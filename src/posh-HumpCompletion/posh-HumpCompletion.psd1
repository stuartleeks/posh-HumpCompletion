@{
    RootModule             = 'posh-HumpCompletion.psm1'
    NestedModules          = @("posh-HumpCompletion.dll")
    ModuleVersion          = '0.5.0-preview1'
    GUID                   = '39a47162-82d7-400b-89b6-3400bb377681'
    Author                 = 'Stuart Leeks'
    CompanyName            = 'Stuart Leeks'
    Copyright              = '(c) 2017 Stuart Leeks. All rights reserved.'
    Description            = 'When working with some PowerShell modules, there can be a large number of cmdlets, and the cmdlet names can get quite long. posh-HumpCompletion adds support for "hump completion". This means that it will use the capitals in the cmdlet name as the identifiers, i.e. "Get-DC<tab>" would complete for Get-DnsClient, Get-DnsClientCache, Get-DscConfiguration, Get-DomainController etc. '
    PowerShellVersion      = '5.0'
    DotNetFrameworkVersion = '4.6.1'
    CLRVersion             = '4.0.0'
    AliasesToExport        = @()
    # TODO - narrow down exports!
    FunctionsToExport      = '*'
    CmdletsToExport        = '*'
    # FunctionsToExport = 'PSConsoleHostReadLine'
    # CmdletsToExport        = 'Get-PoshTest2Ints', 'Get-PoshTest2Foo'
    PrivateData            = @{
        PSData = @{
            Tags       = @('tab-completion', 'completion')
            LicenseUri = 'https://github.com/stuartleeks/posh-HumpCompletion/blob/master/LICENSE.md'
            ProjectUri = 'https://github.com/stuartleeks/posh-HumpCompletion'
        }
    }
}
    