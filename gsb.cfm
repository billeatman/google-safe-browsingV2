<cfset server = createObject('component', 'server').init()>

<cfset ex1 = "www.example.com/">
<cfset ex2 = "example.com/">

<cfoutput>#ex1# - #MID(HASH(ex1, 'SHA-256'), 1, 8)#</cfoutput><br />
<cfoutput>#ex2# - #MID(HASH(ex2, 'SHA-256'), 1, 8)#</cfoutput><br />