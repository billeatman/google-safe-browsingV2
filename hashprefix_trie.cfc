<cfcomponent displayname="hashprefix_trie" extends="helper" hint="Simple trie implementation that is used by the SB client." output="false">

<cfset variables.MIN_PREFIX_LEN = 4>

<cffunction name="init" access="public">
	<cfset variables._root = createNode()>
    <cfset variables._size = 0> <!--- # Number of hash prefixes in the trie. --->
    <cfreturn this>
</cffunction>

<cffunction name="createNode" access="private" returntype="struct" hint="Represents a node in the trie." output="false">
	<cfargument name="parent" type="struct" required="false">
	<cfset var node = structNew()>
    
    <cfset node.values = arrayNew(1)>
    <cfset node.children = structNew()>
    <cfif isDefined("arguments.parent")>
		<cfset node.parent = arguments.parent> 
	</cfif>
    
    <cfreturn node>
</cffunction>

<cffunction name="GetPrefixComponents" access="private" returntype="array" output="false">
	<cfargument name="hashprefix" type="string" required="true"> 
<!--- # For performance reasons we will not store any prefixes that are shorter
    # than 4B.  The SafeBrowsing protocol will most probably never serve
    # prefixes shorter than 4B because it would lead to a high number of
    # collisions. --->
    <cfset var retArray = arrayNew(1)>
    <cfset var i = "">
    
    <cfif len(arguments.hashprefix) lt variables.MIN_PREFIX_LEN>
    	<cfoutput>GetPrefixComponents - hashprefix less than variables.MIN_PREFIX_LEN</cfoutput>
        <cfabort>
    </cfif>

	<cfset ArrayAppend(retArray, mid(arguments.hashprefix, 1, variables.MIN_PREFIX_LEN))>
	
    <cfloop from="1" to="#len(arguments.hashprefix) - variables.MIN_PREFIX_LEN#" index="i">
    	<cfset ArrayAppend(retArray, mid(arguments.hashprefix, i + variables.MIN_PREFIX_LEN, 1))>
    </cfloop>

	<cfreturn retArray>    
</cffunction>

<cffunction name="GetNode" access="public" returntype="any" hint="Returns the trie node that will contain hashprefix." output="false">
	<cfargument name="hashprefix" type="string" required="true">
    <cfargument name="create_if_necessary" type="boolean" required="false" default="false">
	<!--- If create_if_necessary is True this method will create the necessary
    trie nodes to store hashprefix in the trie. --->
    <cfset var LOCAL = structNew()>
	
    <cfset LOCAL.node = variables._root>
    <cfset LOCAL.prefixComponents = GetPrefixComponents(arguments.hashprefix)> 
    
    <cfloop array="#LOCAL.prefixComponents#" index="LOCAL.char">
    	<cfif StructKeyExists(LOCAL.node.children, LOCAL.char)>
        	StructKeyExists!<br>
        	<cfset LOCAL.node = LOCAL.node.children["#LOCAL.char#"]>
		<cfelseif arguments.create_if_necessary EQ true>
        	StructInsert<br>
            <cfset StructInsert(LOCAL.node.children, LOCAL.char, createNode(LOCAL.node), false)>
            <cfset LOCAL.node = LOCAL.node.children["#LOCAL.char#"]>
        <cfelse>
        	<cfreturn>
        </cfif> 
    </cfloop> 
    <cfreturn LOCAL.node>
</cffunction>

<cffunction name="tInsert" access="public" returntype="void" hint="Insert entry with a given hash prefix." output="false">
	<cfargument name="hashprefix" type="string" required="true">
    <cfargument name="entry" type="numeric" required="true">
	<cfset var LOCAL = structNew()>
	
	<cfset LOCAL.node = GetNode(hashprefix: arguments.hashprefix, create_if_necessary: true)>
        
    <cfset ArrayAppend(LOCAL.node.values, arguments.entry)> 
	<cfset variables._size = variables._size + 1>
</cffunction>

<cffunction name="tDelete" access="public" returntype="void" hint="Delete a given entry with hash prefix." output="false">
	<cfargument name="hashprefix" type="string" required="true">
    <cfargument name="entry" type="numeric" required="true">
	
	<cfset var LOCAL = structNew()>
    <cfset LOCAL.node = GetNode(hashprefix: arguments.hashprefix)>
    
	<cfif isDefined("LOCAL.node")>
		<cfset LOCAL.entry_index = inArray(LOCAL.node.values, arguments.entry)>
        <cfif LOCAL.entry_index GT 0>
        	<cfset ArrayDeleteAt(LOCAL.node.values, LOCAL.entry_index)>
            <cfset variables._size = variables._size - 1>
            
            <!--- recursively delete parent nodes if necessary. --->
            <cfloop condition="ArrayIsEmpty(LOCAL.node.values) AND StructIsEmpty(LOCAL.node.children) AND isDefined('LOCAL.node.parent')">
 				<cfset LOCAL.node = LOCAL.node.parent>
                
                <cfif len(arguments.hashprefix) EQ variables.MIN_PREFIX_LEN>
                	<cfset StructDelete(LOCAL.node.children, arguments.hashprefix)>
                    <cfbreak>
                </cfif>
                
                <cfset LOCAL.char = mid(arguments.hashprefix, len(arguments.hashprefix), 1)>
				<cfset arguments.hashprefix = mid(arguments.hashprefix, 1, len(arguments.hashprefix) - 1)>
                <cfset StructDelete(LOCAL.node.children, LOCAL.char)>
            </cfloop>
        </cfif>
    </cfif>    	    	
</cffunction>

<cffunction name="tSize" access="public" returntype="numeric" hint="Returns the number of values stored in the trie." output="false">
    <cfreturn variables._size>
</cffunction>

<cffunction name="GetPrefixMatches" returntype="any" access="public" hint="Yields all values that have a prefix of the given fullhash." output="false">
	<cfargument name="fullhash" type="string" required="true">
   	<cfset var LOCAL = structNew()>
	
	<cfset LOCAL.values = arraynew(1)>
    
    <cfset LOCAL.node = variables._root>
    <cfset LOCAL.prefixComponents = GetPrefixComponents(arguments.fullhash)> 
    
    <cfloop array="#LOCAL.prefixComponents#" index="LOCAL.char">
    	<cfif StructKeyExists(LOCAL.node.children, LOCAL.char)>
        	<cfset LOCAL.node = LOCAL.node.children[LOCAL.char]>
			<cfset LOCAL.values = mergeArrays(LOCAL.values, LOCAL.node.values)>
        <cfelse>
        	<cfbreak>
        </cfif>
	</cfloop> 
    
    <cfreturn LOCAL.values>       
</cffunction>

<cffunction name="PrefixIterator" access="public" hint="Iterator over all the hash prefixes that have values." output="false">
    <cfset var LOCAL = structNew()>
    <!--- return prefix array --->
	<cfset LOCAL.prefixes = arrayNew(1)>

	<cfset LOCAL.stack = arrayNew(1)>
    
    <!--- stack push --->
    <cfset arrayPrepend(LOCAL.stack, structNew())>
    <cfset LOCAL.stack[1].hashprefix = ''>
    <cfset LOCAL.stack[1].node = variables._root>

    <cfloop condition="arrayLen(LOCAL.stack) GT 0">
    	<!--- stack 'pop' --->
		<cfset LOCAL.hashprefix = LOCAL.stack[1].hashprefix>
        <cfset LOCAL.node = LOCAL.stack[1].node>
        <cfset arrayDeleteAt(LOCAL.stack, 1)>
  
		<cfif arraylen(LOCAL.node.values) gt 0>
        	<cfset arrayAppend(LOCAL.prefixes, LOCAL.hashprefix)>
        </cfif>
                
        <cfloop list="#StructKeyList(LOCAL.node.children)#" index="LOCAL.char">
			<cfset arrayPrepend(LOCAL.stack, structNew())>        	
   			<cfset LOCAL.stack[1].hashprefix = LOCAL.hashprefix & LOCAL.char>
   			<cfset LOCAL.stack[1].node = LOCAL.node.children["#LOCAL.char#"]>
        </cfloop>
    </cfloop>
    
    <cfreturn LOCAL.prefixes>
</cffunction>

</cfcomponent>