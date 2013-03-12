<cfcomponent displayname="server" extends="helper" hint="Encapsulates interaction with the safebrowsing servers.">

<cfset variables.CLIENT = 'api'>
<cfset variables.APPVER = '1.0'>
<cfset variables.PVER = '2.2'>

<!--- Request types --->

<cfset variables.LIST = 'list'>
<cfset variables.DOWNLOADS = 'downloads'>
<cfset variables.NEWKEY = 'newkey'>
<cfset variables.GETHASH = 'gethash'>

<cfset variables.MAC = 'm:(.+)'>
<cfset variables.NEXT = 'n:(\d+)'>
<cfset variables.PLEASERKEY = 'e:pleaserekey'>
<cfset variables.PLEASERESET = 'r:pleasereset'>
<cfset variables.LISTRESP = 'i:(.+)'>

<cfset variables.URLRESP = 'u:(.+)'>

<cfset variables.ADDORSUB = '([as]):(\d+):(\d+):(\d+)'>
<cfset variables.ADDDELRESP = 'ad:(.+)'>
<cfset variables.SUBDELRESP = 'sd:(.+)'>

<!--- Bytes in a full length hash (full sha256) --->
<cfset variables.FULLHASHLEN = 32>

<cffunction name="init" access="public" returntype="server">
	<cfargument name="hp" type="array" required="true">
	<cfargument name="ssl_hp" type="array" required="true">
	<cfargument name="base_path" type="string" required="true">
	<cfargument name="clientkey" type="string" required="false">
	<cfargument name="wrkey" type="string" required="false">
	<cfargument name="apikey" type="string" required="false">
	<cfargument name="timeout" type="numeric" required="false" default="20">
	<cfargument name="gethash_server" type="array" required="false">
	<cfargument name="url_request_function" type="any" required="false" default=UrllibRequest>

 	<cfif NOT isCallable(arguments.url_request_function)>
		<cfoutput>ServerError('arguments.url_request_function is not a function')</cfoutput>
        <cfabort>
    </cfif>
    
	<cfset variables._host = arguments.hp[1]>
    <cfset variables._port = arguments.hp[2]>
    <cfset variables._ssl_host = arguments.ssl_hp[1]>
    <cfset variables._ssl_port = arguments.ssl_hp[2]>
    <cfset variables._base_path = arguments.base_path>
	<cfset variables._base_qry = "client=#variables.CLIENT#&appver=#variables.APPVER#&pver=#variables.PVER#">     
    
	<cfif NOT isDefined('arguments.gethash_server')>
    	<cfset variables._gethash_host = arguments.hp[1]>
    	<cfset variables._gethash_port = arguments.hp[2]>
    <cfelse>
    	<cfset variables._gethash_host = arguments.gethash_server[1]>
    	<cfset variables._gethash_port = arguments.gethash_server[2]>
    </cfif>

    <!--- Unescaped client key. --->
    <cfset variables._clientkey = arguments.clientkey>
    <cfif isDefined(arguments.wrkey)>
    	<cfset variables._wrkey = arguments.wrkey>
	</cfif>
    <cfif isDefined(arguments.apikey)>
		<cfset variables._apikey = arguments.apikey>
	</cfif>
	<cfset variables._timeout = arguments.timeout>
	<cfset variables._url_request_function = arguments.url_request_function>

	<cfreturn this>
</cffunction>

<cffunction name="WillUseMac" access="public" returntype="boolean">
	<cfreturn isdefined("variables._wrkey") AND isdefined("variables._GetMacKeys")> 
</cffunction>

<cffunction name="ReKey" access="public" returntype="array" hint="Get a new set of keys, replacing any existing keys. Returns (clientkey, wrkey). The keys are stored in the Server object.">
	<cfset var LOCAL = structNew()>
    
    <cfset LOCAL.keys = _GetMacKeys()>
	<cfset variables._clientkey = LOCAL.keys[1]>
    <cfset variables._wrkey = LOCAL.keys[2]>
    
    <cfreturn Keys()>
</cffunction>

<cffunction name="Keys" access="public" returntype="array" hint="Return (clientkey, wrkey).">
	<cfset var keys = arrayNew(0)> 
    <cfset keys[1] = variables._clientkey>
    <cfset keys[2] = variables._wrkey>
    <cfreturn keys> 
</cffunction>	

<!--- stub ! --->
<cffunction name="GetLists" access="public" returntype="any" hint="Get the available blacklists. Returns a list of List objects.">
	<cfset var LOCAL = structNew()>
    
    <cfset LOCAL.resp = MakeRequest(path: variables.LIST, use_apikey: true)> 
    
    <cfif WillUseMac() EQ TRUE>
    	<cfset LOCAL.mac = trim(ListFirst(LOCAL.resp, "#chr(13)##chr(10)#"))>
    </cfif>
    
    <cfset LOCAL.sbls = arrayNew(0)>
    <cfset LOCAL.raw_data = arrayNew(0)>
    
    <cfset LOCAL.respArray = listtoarray(LOCAL.resp,"#chr(13)##chr(10)#")>
	<cfloop from="1" to="#arrayLen(LOCAL.respArray)#" index="LOCAL.line">
    	<cfset ArrayAppend(LOCAL.raw_data, LOCAL.line)>
        <cfset ArrayAppend( <!--- need sblist object! --->
    </cfloop>
</cffunction>

<!--- 
def GetLists(self):
    """
    Get the available blacklists. Returns a list of List objects.
    """
    resp = self._MakeRequest(Server.LIST, use_apikey=True)
    mac = None
    if self.WillUseMac():
      mac = resp.readline().strip()
    sbls = []
    raw_data = []
    for line in resp:
      raw_data.append(line)
      sbls.append(sblist.List(line.strip()))
    resp.close()
    self._CheckMac(mac, ''.join(raw_data))
    return sbls
--->

<cffunction name="UrllibRequest" access="public" returntype="any">
	<cfargument name="url" type="string" required="true">
    <cfargument name="postdata" type="any" required="true">
    <cfset var result = "">
    <cfhttp url="#arguments.url#" method="post" result="#result#">#arguments.postdata#</cfhttp> 
	<cfreturn result>
</cffunction> 

<cffunction name="GetMacKeys" access="private" hint="Request a new key from the server.">
	<cfset var LOCAL = structNew()>
    
    <cfset LOCAL.hp = arrayNew(0)>
    <cfset LOCAL.hp[1] = variables._ssl_host>
    <cfset LOCAL.hp[2] = variables._ssl_port>
    
    <cfset LOCAL.resp = MakeRequest(path: variables.NEWKEY, hp: LOCAL.hp, protocol: 'https')>

	<cfset LOCAL.respArray = listtoarray(LOCAL.resp,"#chr(13)##chr(10)#")>
	<cfloop from="1" to="#arrayLen(LOCAL.respArray)#" index="LOCAL.line">
		<cfset LOCAL.split = listtoarray(LOCAL.line,":")>
    	<cfif arrayLen(LOCAL.split) NEQ 3>
			<cfoutput>ResponseError('newkey: #LOCAL.line#')</cfoutput>
	        <cfabort>
        </cfif>
        
        <cftry>
        	<cfset LOCAL.length = int(LOCAL.split[2])>
			<cfcatch>
				<cfoutput>ResponseError('newkey: #LOCAL.line#')</cfoutput>
                <cfabort>
            </cfcatch>
        </cftry>

		<cfif len(LOCAL.split[3]) LT LOCAL.length>
			<cfoutput>ResponseError('newkey: #LOCAL.line#')</cfoutput>
	        <cfabort>
        </cfif>           	
        
        <cfif LOCAL.split[1] EQ 'clientkey'>
        	<cftry>
            	<cfset LOCAL.clientkey = mid(LOCAL.split[3], 1, LOCAL.length)>
        		<cfset LOCAL.clientkey = toBinary(LOCAL.clientkey)>
               	<cfcatch>
					<cfoutput>ResponseError('could not decode clientkey: "#LOCAL.line#", "#LOCAL.clientkey#"')</cfoutput>
                    <cfabort>
                </cfcatch>
            </cftry>
		<cfelseif LOCAL.split[1] EQ 'wrappedkey'>
        	<cfset LOCAL.wrkey = mid(LOCAL.split[3], 1, LOCAL.length)>
        <cfelse>
	       	<cfoutput>ResponseError('newkey: #LOCAL.line#')</cfoutput>
            <cfabort>
       	<cfabort>
            
        </cfif>
    </cfloop> 
    
    <cfif (NOT isDefined(LOCAL.clientkey)) OR (NOT isDefined(LOCAL.wrkey))>
       	<cfoutput>ResponseError('response is missing wrappedkey or clientkey')</cfoutput>
       	<cfabort>
	</cfif>
    
    <cfset LOCAL.retval = arrayNew(0)>
    <cfset LOCAL.retval[1] = LOCAL.clientkey>
    <cfset LOCAL.retval[2] = LOCAL.wrkey>
    
    <cfreturn LOCAL.retval>
</cffunction>

<cffunction name="MakeRequest" access="private" returntype="any">
 	<cfargument name="path" type="string" required="true">
    <cfargument name="postdata" type="string" required="false">
    <cfargument name="hp" type="any" required="false">
    <cfargument name="use_wrkey" type="boolean" required="false" default="true">
    <cfargument name="use_apikey" type="boolean" required="false" default="false">
    <cfargument name="extra_params" type="string" required="false" default="">
    <cfargument name="protocol" type="string" required="false" default="http">
    
    <cfset var LOCAL = structNew()>
    
    <cfif NOT isdefined(arguments.hp)>
		<cfset arguments.hp = arrayNew(0)>
        <cfset arguments.hp[1] = variables._host>
        <cfset arguments.hp[2] = variables._port>
    </cfif>
	
    <cfset LOCAL.wrkey = ''>
    <cfif isDefined("arguments.use_wrkey") AND isDefined("variables._wrkey")>
    	<cfset LOCAL.wrkey = "&wrkey=#variables._wrkey#">
	</cfif>
    
    <cfset LOCAL.apikey_param = ''>
	<cfif arguments.use_apikey AND variables._apikey>
    	<cfset LOCAL.apikey_param = "&apikey=#variables._apikey#">     
    </cfif>

	<cfset LOCAL.url = "#arguments.protocol#://#arguments.hp[1]#:#arguments.hp[2]##variables._base_path#/#path#?#variables._base_qry##LOCAL.wrkey##LOCAL.apikey_param##arguments.extra_params#">
    
	<!--- logging.debug('http url: "%s"', url) --->
    <cftry>
    	<cfset LOCAL.resp = variables._url_request_function(LOCAL.url, arguments.postdata)>
		<cfcatch>
        	<cfoutput>ServerError('#arguments.path# failed: #cfcatch.Message#')</cfoutput>
        	<cfabort>
        </cfcatch>
    </cftry>
	<cfreturn LOCAL.resp>
</cffunction>

</cfcomponent>