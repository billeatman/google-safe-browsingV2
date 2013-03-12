<!--- Unittest for googlesafebrowsing.hashprefix_trie. --->
<h2>Unittest for googlesafebrowsing.hashprefix_trie.</h2>

<cffunction name="assertSameElements" access="public">
</cffunction>

<cfset trie = createObject("component", "hashprefix_trie").init()>

inserting - 'aabc', 'aabcd', 'acde', 'abcdefgh'<br /><br />    
<cfset trie.tInsert('aabc', 1)>
<cfset trie.tInsert('aabcd', 2)>
<cfset trie.tInsert('acde', 3)>
<cfset trie.tInsert('abcdefgh', 4)>

abcdefg - {1, 2}<br />
<cfdump var="#trie.GetPrefixMatches('aabcdefg')#"><br />  <!--- 1, 2 --->
abcdefg - {1, 2}<br />
<cfdump var="#trie.GetPrefixMatches('aabcd')#"><br />  <!--- 1, 2 --->  
abcdefg - {1}<br />
<cfdump var="#trie.GetPrefixMatches('aabc')#"><br />  <!--- 1 --->  
abcdefg - {3}<br />
<cfdump var="#trie.GetPrefixMatches('acde')#"><br />  <!--- 3 --->  
Trie Size: 4<br />
<cfdump var="#trie.tSize()#"><br /><br />  <!--- 4 --->  

deleting - 'abcdefgh'<br />
<cfset trie.tDelete('abcdefgh', 4)>
<!---  Make sure that all nodes between abcd and abcdefgh were deleted because
 they were emtpy. ---> 
Exists 'abcd' - NO<br />
<cfdump var="#isStruct(trie.GetNode('abcd'))#"><br /><br />

deleting - 'aabc', 'aaaa'<br />
<cfset trie.tDelete('aabc', 2)>  <!--- No such prefix, value pair. --->
<cfset trie.tDelete('aaaa', 1)>  <!--- No such prefix, value pair. --->

Trie Size: 3<br />
<cfdump var="#trie.tSize()#"><br /><br />

deleting - 'aabc'<br />
<cfset trie.tDelete('aabc', 1)>
Trie Size: 2<br />
<cfdump var="#trie.tSize()#"><br /><br />

PrefixIterator - 'aabcd', 'acde'<br />
<cfdump var="#trie.PrefixIterator()#">
