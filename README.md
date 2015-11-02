# posh-HumpCompletion
When working with some PowerShell modules, there can be a large number of cmdlets, and the cmdlet names can get quite long.
posh-HumpCompletion adds support for "hump completion". This means that it will use the capitals in the cmdlet name as the identifiers, 
i.e. "Get-DC<tab>" would complete for Get-DnsClient, Get-DnsClientCache, Get-DscConfiguration, Get-DomainController etc.

## Installation
Make sure you have [chocolatey](https://chocolatey.org) installed.


Currently the installation is only on a myget feed, so install using:
```
choco install posh-HumpCompletion -source "https://www.myget.org/F/posh-humpcompletion/api/v2" -pre
```

## Release notes

### Version 0.0.3 - 28th October 2015
Added caching of command details. If you add load new modules, run Clear-HumpCompletionCommandCache to update the tab completion

### Version 0.0.2 - 28th October 2015
Added partial matching support. So now, Get-DC completes Get-DnsClient, but also Get-DnsClientCache

### Version 0.0.1 - 27th October 2015
The first version, basic functionality implemented