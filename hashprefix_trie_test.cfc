<cfcomponent extends="mxunit.framework.TestCase">
	<cfset variables.trie = "">

	<!--- this will run before every single test in this test case --->
	<cffunction name="setUp" returntype="void" access="public" hint="put things here that you want to run before each test">
	</cffunction>

	<!--- this will run after every single test in this test case --->
	<cffunction name="tearDown" returntype="void" access="public" hint="put things here that you want to run after each test">

	</cffunction>

        <!--- this will run once after initialization and before setUp() --->
	<cffunction name="beforeTests" returntype="void" access="public" hint="put things here that you want to run before all tests">
		<cfset trie = createObject("component", "hashprefix_trie").init()>
	</cffunction>

	<!--- this will run once after all tests have been run --->
	<cffunction name="afterTests" returntype="void" access="public" hint="put things here that you want to run after all tests">
	</cffunction>

	<!--- calling the other functions as private because I couldn't get "order" to work --->
	<cffunction name="hashprefix_trie_test" returntype="void" access="public">
		<cfset insert_test()>
        <cfset delete_test()>
        <cfset prefix_iterator_test()>
    </cffunction>

	<!--- your test. Name it whatever you like... make it descriptive. --->
	<cffunction name="insert_test" returntype="void" access="private" order="1">
		<!--- exercise your component under test --->
		<cfset var result = "">
		
        <cfset trie.tInsert('aabc', 1)>
		<cfset trie.tInsert('aabcd', 2)>
		<cfset trie.tInsert('acde', 3)>
		<cfset trie.tInsert('abcdefgh', 4)>
      
        <cfset result = trie.GetPrefixMatches('aabcdefg')> 
        <cfset debug(result)> 
		<cfset assertEquals([1,2], result)>

        <cfset result = trie.GetPrefixMatches('aabcd')> 
        <cfset debug(result)> 
		<cfset assertEquals([1,2], result)>

        <cfset result = trie.GetPrefixMatches('aabc')> 
        <cfset debug(result)> 
		<cfset assertEquals([1], result)>

        <cfset result = trie.GetPrefixMatches('acde')> 
        <cfset debug(result)> 
		<cfset assertEquals([3], result)>

        <cfset result = trie.tSize()> 
        <cfset debug(result)> 
		<cfset assertEquals(4, result)>        
	</cffunction>
    
    <cffunction name="delete_test" returntype="void" access="private" order="2">
		<cfset var result = "">
        
		<cfset trie.tDelete('abcdefgh', 4)>
		<!---  Make sure that all nodes between abcd and abcdefgh were deleted because they were emtpy. ---> 
		<cfset result = isStruct(trie.GetNode('abcd'))>
        <cfset debug(result)>
        <cfset assertEquals(false, result)>

		<cfset trie.tDelete('aabc', 2)>  <!--- No such prefix, value pair. --->
        <cfset trie.tDelete('aaaa', 1)>  <!--- No such prefix, value pair. --->
		<cfset result = trie.tSize()>
        <cfset debug(result)>
        <cfset assertEquals(3, result)>

        <cfset trie.tDelete('aabc', 1)>
		<cfset result = trie.tSize()>
        <cfset debug(result)>
        <cfset assertEquals(2, result)>
	</cffunction>
    
    <cffunction name="prefix_iterator_test" returntype="void" access="private" order="3">
		<cfset var result = "">
        <cfset result = trie.PrefixIterator()>
        <cfset debug(result)>
        <cfset assertEquals(['acde','aabcd'], result)>        
	</cffunction>


</cfcomponent>

