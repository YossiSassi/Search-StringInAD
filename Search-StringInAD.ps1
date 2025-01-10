<#
.SYNOPSIS
    Looks recursively for 'interesting' strings (as well as IP addresses & Unicode characters that are hidden in ASCII) in all AD objects.

    Author: 1nTh35h311 (yossis@protonmail.com, @Yossi_Sassi)

    Version: 1.1
    v1.1 - Added an optional lookup for (hidden) Unicode characters in AD Objects
    v1.0.0 - initial script

    Required Dependencies: None (excpet for LDAP connectivity to a Domain Controller, as any authenticated user)
    Optional Dependencies: None (No dependencies, no special permissions)

    License: BSD 3-Clause

.EXAMPLE
& .\Search-StringInAD.ps1 -SearchTerm password
Searches the entire AD / all objects for any object with any attribute containing the word "password".

& .\Search-StringInAD.ps1 -SearchTerm helpdesk -ShowMatchDetails -OutputToGrid
Searches the entire AD / all objects for any object with any attribute containing the word "helpdesk", including the exact Match Details from the object, Plus opens an ad-hoc GRID with the results.

& .\Search-StringInAD.ps1 -OutputToGrid -SearchForIPAddresses -SearchForHiddenUnicodeCharacters
Searches the entire AD / all objects for any IP Address pattern match (REGEX), as well as ANY unicode character (hidden in ASCII), Plus opens an ad-hoc GRID with the results.

& .\Search-StringInAD.ps1 -SearchTerm admin -SearchForIPAddresses -OutputFile c:\temp\SearchAD.txt
Searches the entire AD / all objects for any object with any attribute containing the word "admin", plus gets IP Address pattern match (REGEX), and saves the results to c:\temp\SearchAD.txt.
#>

param (
    [cmdletbinding()]
    [string]$SearchTerm,
    [switch]$ShowMatchDetails,
    [Switch]$OutputToGrid,
    [switch]$SearchForIPAddresses,
    [switch]$SearchForHiddenUnicodeCharacters,
    [String]$OutputFile = "$(Get-Location)\SearchStringsInAD_$(Get-Date -Format ddMMyyyyHHmmss).txt"
)

function Switch-Color {
    if ($global:Color -eq "Yellow") {$global:Color = "Cyan"} else {$global:Color = "Yellow"};
    return $global:Color
}

$global:Color = "Yellow";
if ($SearchTerm)
    {
        if ($SearchForIPAddresses)
            {
                "Results for SearchTerm $SearchTerm + IPv4 addresses pattern matching -" | out-file $OutputFile -append -force
            }
        else
            {
                "Results for SearchTerm $SearchTerm -" | out-file $OutputFile -append -force
            }
    }

else
    {
        if ($SearchForIPAddresses)
            {
                "Results may include IPv4 addresses pattern matching -" | out-file $OutputFile -append -force
            }
    else   
        {
            Write-Host "Missing SearchTerm parameter." -ForegroundColor Yellow;
            break
        }
}

if ($SearchForHiddenUnicodeCharacters)
    {
        "Results may include hidden Unicode Characters (switch specified)." | Out-File $OutputFile -append -force
    }

if ($OutputToGrid)
    {
        $GridData = @();
        $GridData += "SamAccountName;Name;DistinguishedName;Attribute;Value (Match Details)"
    }

# hash table of unicode characters + types
$UnicodeCharTable = @{
    "0x200B" = "Zero Width Space (ZWSP)"
    "0x200C" = "Zero Width Non-Joiner (ZWNJ)"
    "0x200D" = "Zero Width Joiner (ZWJ)"
    "0xFEFF" = "Zero Width No-Break Space"

    "0x00A0" = "No-Break Space (NBSP)"
    "0x2000" = "En Quad"
    "0x2001" = "Em Quad"
    "0x2002" = "En Space"
    "0x2003" = "Em Space"
    "0x2004" = "Three-Per-Em Space"
    "0x2005" = "Four-Per-Em Space"
    "0x2006" = "Six-Per-Em Space"
    "0x2007" = "Figure Space"
    "0x2008" = "Punctuation Space"
    "0x2009" = "Thin Space"
    "0x200A" = "Hair Space"
    "0x205F" = "Medium Mathematical Space"
    "0x202F" = "Narrow No-Break Space"

    "0x200E" = "Left-to-Right Mark (LRM)"
    "0x200F" = "Right-to-Left Mark (RLM)"
    "0x202A" = "Left-to-Right Embedding (LRE)"
    "0x202B" = "Right-to-Left Embedding (RLE)"
    "0x202C" = "Pop Directional Formatting (PDF)"
    "0x202D" = "Left-to-Right Override (LRO)"
    "0x202E" = "Right-to-Left Override (RLO)"

    "0xFFFC" = "Object Replacement Character"
    "0xFFF9" = "Interlinear Annotation Anchor"
    "0xFFFA" = "Interlinear Annotation Separator"
    "0xFFFB" = "Interlinear Annotation Terminator"
}

# Get AD Objects
$DS = new-object system.directoryservices.directorysearcher;
$DS.Filter = '(WhenCreated=*)';
$DS.SizeLimit = 100000;
$DS.PageSize = 100000;

$DS.FindAll() | Foreach-Object {
        $obj = $_;
        $prop = $obj.properties.PropertyNames;

        $prop[0] | ForEach-Object {
                    $CurrentProp = $_;
                    
                    if ($SearchForIPAddresses)
                        {
                            $IPRegExResult = ([regex]::Matches($obj.Properties.$CurrentProp,"\b(?:\d{1,3}\.){3}\d{1,3}\b")).value;
                            $IPs = ($IPRegExResult | ForEach-Object {[System.Net.IPAddress]$_}).IPAddressToString;

                            # match by either SearchTerm or IP Address
                            if ($SearchTerm) 
                                {
                                    if ($obj.Properties.$CurrentProp -like "*$SearchTerm*" -or $IPs) 
                                        {
                                            $ResultMatch = $true
                                        }
                                }
                            # match by IP Address only (search term is empty)
                            elseif ($IPs) 
                                        {
                                            $ResultMatch = $true
                                        }
                        }
                    # match by search term only
                    elseif ($obj.Properties.$CurrentProp -like "*$SearchTerm*") {
                            $ResultMatch = $true;
                        }

                    # hidden Unicode characters
                    if ($SearchForHiddenUnicodeCharacters) {
                            $UnicodeResult = ($obj.Properties.$CurrentProp | Out-String).ToCharArray() | ForEach-Object {$Key = $('0x{0:X4}' -f [int][char]$_); if ($UnicodeCharTable.Keys -contains $Key) {"Unicode character:$key,Type:$($UnicodeCharTable[$key])"} }     
                            if ($UnicodeResult) {
                                Write-Host "Found HIDDEN UNICODE CHARACTER on attribute <$($CurrentProp)> of object:`n$($obj.properties.samaccountname); $($obj.properties.distinguishedname)`nMatch Details: $UnicodeResult" -ForegroundColor $(Switch-Color);
				                "Found HIDDEN UNICODE CHARACTER on attribute <$($CurrentProp)> of object:`n$($obj.properties.samaccountname); $($obj.properties.distinguishedname)`nMatch Details: $UnicodeResult`n" | out-file $OutputFile -append -force;
                                $UnicodeResultMatch = $true;
                                $ResultMatch = $true
                            }
                    }

                    if ($ResultMatch)
                        {
                            if ($ShowMatchDetails -and $UnicodeResult -eq $false)
                                {
                                    Write-Host "Found match on attribute <$($CurrentProp)> of object:`n$($obj.properties.samaccountname); $($obj.properties.distinguishedname)`nMatch Details: $($obj.properties.$CurrentProp)" -ForegroundColor $(Switch-Color);
				                    "Found match on attribute <$($CurrentProp)> of object:`n$($obj.properties.samaccountname); $($obj.properties.distinguishedname)`nMatch Details: $($obj.properties.$CurrentProp)`n" | out-file $OutputFile -append -force;
                                }
                            else
                                {
                                    Write-Host "Found match on attribute <$($CurrentProp)> of object:`n$($obj.properties.samaccountname); $($obj.properties.distinguishedname)" -ForegroundColor $(Switch-Color);
				                    "Found match on attribute <$($CurrentProp)> of object:`n$($obj.properties.samaccountname); $($obj.properties.distinguishedname)`n" | out-file $OutputFile -append -force;
                                }

                            if ($OutputToGrid)
                                {
                                    if ($UnicodeResultMatch) {$GridData += "$($obj.properties.samaccountname);$($obj.properties.name);$($obj.properties.distinguishedname);$CurrentProp;$UnicodeResult"}
                                    $GridData += "$($obj.properties.samaccountname);$($obj.properties.name);$($obj.properties.distinguishedname);$CurrentProp;$($obj.properties.$CurrentProp)"
                                }
                            
                            # reset result match for the next loop
                            $ResultMatch = $false;
                            $UnicodeResultMatch = $false;
                            Clear-Variable unicodeResult -ErrorAction SilentlyContinue
                        }
        }                               
}

if ($OutputToGrid)
    {
        $GridData | ConvertFrom-Csv -Delimiter ";" | Out-GridView -Title "Results - Search for string in AD Objects (saved to $OutputFile)"
    }

if ([io.file]::ReadAllLines($OutputFile).count -eq 1)
    {
        Write-Host "No matches found." -ForegroundColor Yellow
    }
else
    {
        Write-Host "`nResults saved to $OutputFile." -ForegroundColor Green
    }