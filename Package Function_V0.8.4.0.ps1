function Create-Package { 
    param(
        [parameter(mandatory=$false)] [string] $Language = "EN-US",
        [parameter(mandatory=$true)] [string] $Path,
        [parameter(mandatory=$false)] [string] $LimitingCollectionName = "ALL Systems",
        [parameter(mandatory=$false)] [string] $DistributionPoinGroupName = "ALL Mangalore Group",
        [parameter(mandatory=$false)] [datetime] $DeadlineTime
    )

    Clear-Host

    <# FOR TEST ONLY###########################################################
    $Path = "\\192.168.25.214\Package_Source\Applications\Google\Chrome\Google_Chrome_145.0.7632.46"
    $Language = "EN-US"
    $LimitingCollectionName = "ALL Systems"
    $DistributionPoinGroupName = "ALL Mangalore Group"
    # FOR TEST ONLY########################################################### #>


    # ---------------------------------------
    # Extract package details from given path
    # ---------------------------------------
    $pathSPlit = $Path -split "\\"

    $Packagename = $pathSPlit[-1]
    $Company     = $pathSPlit[-3]
    $Product     = $pathSPlit[-2]

    Write-Host "Package name: $Packagename" -ForegroundColor Yellow
    Write-Host "Company/Manufacturer: $Company" -ForegroundColor Yellow
    Write-Host "Product/Application: $Product" -ForegroundColor Yellow

    # ---------------------------------------
    # Extract version from package name
    # ---------------------------------------
    $VersionSPlit = $Packagename -split "_"
    $Version      = $VersionSPlit[-1]

    Write-Host "Version: $Version" -ForegroundColor Green

    # ---------------------------------------
    # Generate program names
    # ---------------------------------------
    $ProgramName1 = $Packagename + "[AVAILABLE]"
    $ProgramName2 = $Packagename + "[INSTALL]"
    $ProgramName3 = $Packagename + "[UNINSTALL]"

    Write-Host "ProgramName1: $ProgramName1" -ForegroundColor Green
    Write-Host "ProgramName2: $ProgramName2" -ForegroundColor Green
    Write-Host "ProgramName3: $ProgramName3" -ForegroundColor Green

    # ---------------------------------------
    # Generate collection names
    # ---------------------------------------
    $CollectionName1 = $Packagename + "[AVAILABLE]"
    $CollectionName2 = $Packagename + "[INSTALL]"
    $CollectionName3 = $Packagename + "[UNINSTALL]"
    $CollectionName4 = $Packagename + "[EXCEPTION]"

    Write-Host "CollectionName1: $CollectionName1" -ForegroundColor Green
    Write-Host "CollectionName2: $CollectionName2" -ForegroundColor Green
    Write-Host "CollectionName3: $CollectionName3" -ForegroundColor Green
    Write-Host "CollectionName4: $CollectionName4" -ForegroundColor Green

    # ---------------------------------------
    # Create SCCM package
    # ---------------------------------------
    New-CMPackage -Name $Packagename -Manufacturer $Company -Version $Version -Language $Language -Path $Path
    Write-Host "Package created" -ForegroundColor Green
                                                                     
    # ---------------------------------------
    # Create programs (Available / Install / Uninstall)
    # ---------------------------------------
    New-CMProgram -PackageName $Packagename -StandardProgramName $ProgramName1 -CommandLine "install.exe" -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn
    New-CMProgram -PackageName $Packagename -StandardProgramName $ProgramName2 -CommandLine "install.bat" -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn
    New-CMProgram -PackageName $Packagename -StandardProgramName $ProgramName3 -CommandLine "uninstall.bat" -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn

    Write-Host "Programs created" -ForegroundColor Green
                 
    # ---------------------------------------
    # Create device collections
    # ---------------------------------------
    New-CMDeviceCollection -Name $CollectionName1 -LimitingCollectionName $LimitingCollectionName
    New-CMDeviceCollection -Name $CollectionName2 -LimitingCollectionName $LimitingCollectionName
    New-CMDeviceCollection -Name $CollectionName3 -LimitingCollectionName $LimitingCollectionName
    New-CMDeviceCollection -Name $CollectionName4 -LimitingCollectionName $LimitingCollectionName

    Write-Host "Collections created" -ForegroundColor Green
     
    # ---------------------------------------
    # Distribute content to DP group
    # ---------------------------------------
    Start-CMContentDistribution -PackageName $Packagename -DistributionPointGroupName $DistributionPoinGroupName 
    Write-Host "Distribution Point Group updated" -ForegroundColor Green
          
    # ---------------------------------------
    # Deploy programs to collections
    # ---------------------------------------
    $ProgramComment = $Packagename + " Program"
    

    New-CMPackageDeployment -StandardProgram -PackageName $Packagename -CollectionName $CollectionName1 -Comment "$ProgramComment" -DeployPurpose Available -ProgramName $ProgramName1
    New-CMPackageDeployment -StandardProgram -PackageName $Packagename -CollectionName $CollectionName2 -Comment "$ProgramComment" -DeployPurpose Available -ProgramName $ProgramName2
    #New-CMPackageDeployment -StandardProgram -PackageName $Packagename -CollectionName $CollectionName3 -Comment "$ProgramComment" -DeployPurpose Required -ProgramName $ProgramName3


    # Create deadline schedule (default: today 8 PM + 10 days)
    $DeadlineTime        = (Get-Date -Hour 20 -Minute 0 -Second 0).AddDays(30)
    $NewScheduleDeadline = New-CMSchedule -Start $DeadlineTime -Nonrecurring
    
    New-CMPackageDeployment -StandardProgram -PackageName $Packagename -ProgramName $ProgramName3 -DeployPurpose Required -CollectionName $CollectionName3 -Schedule $NewScheduleDeadline   

    Write-Host "Program deployed to collections" -ForegroundColor Green

    $siteCode = Get-PCXCMSiteCode
    $CollectionFolder =  "\DeviceCollection\Mphasis Application Deployment\$Company\$Product\$Packagename"
    $CollectionFolderPath = "$siteCode" + ":$CollectionFolder"

    #$CollectionFolderPath =  "\DeviceCollection\Mphasis Application Deployment\$Company\$Product\$Packagename\"
    
    New-PCXCMFolder -Path $CollectionFolder

    # Move the collection to the specified folder
    $CollectionObject = Get-CMDeviceCollection -Name $CollectionName1 # Available 
    Move-CMObject -FolderPath $CollectionFolderPath -InputObject $CollectionObject
    Write-Host "Collection '$CollectionName' is Moved to '$CollectionFolderPath'"

    $CollectionObject = Get-CMDeviceCollection -Name $CollectionName2 # Install
    Move-CMObject -FolderPath $CollectionFolderPath -InputObject $CollectionObject
    Write-Host "Collection '$CollectionName' is Moved to '$CollectionFolderPath'"

    $CollectionObject = Get-CMDeviceCollection -Name $CollectionName3 # Uninstall
    Move-CMObject -FolderPath $CollectionFolderPath -InputObject $CollectionObject
    Write-Host "Collection '$CollectionName' is Moved to '$CollectionFolderPath'"

    $CollectionObject = Get-CMDeviceCollection -Name $CollectionName4 # Exception
    Move-CMObject -FolderPath $CollectionFolderPath -InputObject $CollectionObject
    Write-Host "Collection '$CollectionName' is Moved to '$CollectionFolderPath'"

    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName $CollectionName4 -IncludeCollectionName $CollectionName3
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $CollectionName2 -ExcludeCollectionName $CollectionName4

    $siteCode = Get-PCXCMSiteCode
    $PackageFolder = "\Package\Application Installation\$Company\$Product\$Packagename"
    $PackageFolderFolderPath = "$siteCode" + ":$PackageFolder"

    New-PCXCMFolder -Path $PackageFolder
    $PackageObject = Get-CMPackage -Name $Packagename # Exception
    Move-CMObject -FolderPath $PackageFolderFolderPath -InputObject $PackageObject
    Write-Host "Pacakge '$Packagename' is Moved to '$PackageFolderFolderPath'"

}

# ---------------------------------------
# Example usage
# ---------------------------------------
#Create-Package -Path "\\192.168.25.214\Package_source\Applications\Tim Kosse\FileZilla\Tim Kosse_FileZilla_3.69.6.0"

#Create-Package -Path "\\192.168.25.214\Package_Source\Applications\Google\Chrome\Google_Chrome_145.0.7632.46"



