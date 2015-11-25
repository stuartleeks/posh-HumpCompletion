# posh-HumpCompletion
When working with some PowerShell modules, there can be a large number of cmdlets, and the cmdlet names can get quite long.
posh-HumpCompletion adds support for "hump completion". This means that it will use the capitals in the cmdlet name as the identifiers, 
i.e. `"Get-DC<tab>"` would complete for Get-DnsClient, Get-DnsClientCache, Get-DscConfiguration, Get-DomainController etc.

## Installation

### PowerShell Gallery

You can install [posh-HumpCompletion](https://www.powershellgallery.com/packages/posh-HumpCompletion/) via the [PowerShell Gallery](https://www.powershellgallery.com/)

```powershell
Install-Module -Name posh-HumpCompletion
```

### Chocolatey
Make sure you have [chocolatey](https://chocolatey.org) installed.

Currently the installation is only on a myget feed, so install using:
```powershell
choco install posh-HumpCompletion -source "https://www.myget.org/F/posh-humpcompletion/api/v2" -pre
```

## Instructions
Hopefully this is fairly simple to use!

If you have a command that you want to complete for then you can type the capitals in the name and then Tab to complete.

E.g. for Get-AzureResourceGroup you can use `Get-ARG<tab>`
Repeated tabs will cycle matches (in this case, Get-AzureResourceGroupDeployment etc)

### Tips
For performance, posh-HumpCompletion caches the loaded commands. 
If you load new modules or otherwise change the set of commands (Azure PowerShell & Switch-AzureMode, I'm looking at you!) then run `Clear-HumpCompletionCommandCache` to reset. 
[Bonus tip: use `"Clear-HCCC<tab>"` :-)]

## Release notes

### Version 0.0.11 25th November 2015
Pushed to PowerShell Gallery
Pushed to myget feed
Fixed some typos/script styling - thanks @korygill ;-)

### Version 0.0.8 - 2nd November 2015
Pushed to myget feed 2nd November 2015
Minor tweaks and packaging for chocolatey

### Version 0.0.3 - 28th October 2015
Added caching of command details. If you add load new modules, run Clear-HumpCompletionCommandCache to update the tab completion

### Version 0.0.2 - 28th October 2015
Added partial matching support. So now, Get-DC completes Get-DnsClient, but also Get-DnsClientCache

### Version 0.0.1 - 27th October 2015
The first version, basic functionality implemented