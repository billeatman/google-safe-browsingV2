<cfcomponent displayname="helper">

<cffunction name="inArray" access="public" returntype="boolean" hint="Needed a value in array method.">
    <cfargument name="array" type="array" required="true">
    <cfargument name="value" type="numeric" required="true">
	<cfset var i = "">
    <cfloop from="1" to="#arrayLen(arguments.array)#" index="i">
    	<cfif arguments.array[i] EQ arguments.value>
        	<cfreturn i>
        </cfif>
    </cfloop>
    <cfreturn 0>
</cffunction>

<!--- is a function callable --->
<cffunction name="isCallable" access="public" returntype="boolean">
	<cfargument name="func" type="any" required="true">
    <cftry>
		<cfif structKeyExists(GetMetaData(arguments.func), "NAME") AND structKeyExists(GetMetaData(arguments.func), "PARAMETERS")>
            <cfreturn true>
        </cfif>
	<cfcatch></cfcatch>
    </cftry>    
    
    <cfreturn false>
</cffunction>

<!--- http://stackoverflow.com/questions/3081756/join-two-arrays-in-coldfusion --->
<cffunction name="mergeArrays" returntype="array" >
    <cfargument name="array1" type="array" required="true" >
    <cfargument name="array2" type="array" required="true" >

	<cfset var i = "">

    <cfloop array="#arguments.array2#" index="i">
        <cfset arrayAppend(arguments.array1, i) >
    </cfloop>

    <cfreturn arguments.array1>
</cffunction>


</cfcomponent>