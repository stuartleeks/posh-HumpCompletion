# posh-HumpCompletion
When working with some PowerShell modules, there can be a large number of cmdlets, and the cmdlet names can get quite long.
posh-HumpCompletion adds support for "hump completion". This means that it will use the capitals in the cmdlet name as the identifiers, 
i.e. "Get-DC<tab>" would complete for Get-DnsClient, Get-DscConfiguration, Get-DomainController etc.
