# File : Functions.ps1

function Connect-SCCM {
    param(
        $SiteCode = "PS1",
        $ProviderMachineName = "CM01.corp.pcxlab.com"
    )

    if ((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
    }

    if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
    }

    Set-Location "$SiteCode`:\"
}

<#

# New collection

function New-SCCMDeviceCollection {
    param(
        [string]$CollectionName,
        [string]$LimitingCollection = "All Systems"
    )

    try {
        New-CMDeviceCollection `
            -Name $CollectionName `
            -LimitingCollectionName $LimitingCollection

        return "Collection '$CollectionName' created successfully"
    }
    catch {
        return "Error: $($_.Exception.Message)"
    }
}

#>

# You can add more functions if required 

