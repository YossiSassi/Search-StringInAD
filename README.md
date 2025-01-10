# Search-StringInAD
Looks recursively for 'interesting' strings (as well as IP addresses &amp; hidden Unicode characters) in all AD objects<br><br>
Required Dependencies: *None*  (excpet for LDAP connectivity to a Domain Controller, as any authenticated user)<br>
Optional Dependencies: *None*  (No module dependencies, no special permissions)<br><br>
<b>Example usage:</b><br>
& .\Search-StringInAD.ps1 -SearchTerm password<br>
*Searches the entire AD / all objects for any object with any attribute containing the word "password"*<br><br>
& .\Search-StringInAD.ps1 -SearchTerm helpdesk -ShowMatchDetails -OutputToGrid
*Searches the entire AD / all objects for any object with any attribute containing the word "helpdesk", including the exact Match Details from the object, Plus opens an ad-hoc GRID with the results*<br><br>
& .\Search-StringInAD.ps1 -OutputToGrid -SearchForIPAddresses -SearchForHiddenUnicodeCharacters<br><br> 
*Searches the entire AD / all objects for any IP Address pattern match (REGEX), as well as ANY unicode character (hidden in ASCII), Plus opens an ad-hoc GRID with the results*<br><br>
& .\Search-StringInAD.ps1 -SearchTerm admin -SearchForIPAddresses -OutputFile c:\temp\SearchAD.txt<br><br> 
*Searches the entire AD / all objects for any object with any attribute containing the word "admin", plus gets IP Address pattern match (REGEX), and saves the results to c:\temp\SearchAD.txt*<br><br>
