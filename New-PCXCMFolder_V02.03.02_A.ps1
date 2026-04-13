###############################
function New-PCXCMFolder {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Name
    )

    Write-Verbose "********** Function Begin **********"

    try {
        # -------------------------------
        # Step 1: Detect and extract SiteCode
        # -------------------------------
        $siteCode = $null
        $cleanPath = $null

        if ($Path -match '^[A-Za-z0-9]{3}:\\') {
            # Path includes PSDrive (e.g., PS1:\...)
            $siteCode = $Path.Substring(0,3)
            $cleanPath = $Path.Substring(4)
            Write-Verbose "Detected PSDrive in path: $siteCode"
        }
        else {
            # No PSDrive → use function
            $siteCode = Get-PCXCMSiteCode
            if (-not $siteCode) {
                throw "Failed to retrieve SCCM Site Code."
            }
            $cleanPath = $Path
            Write-Verbose "Using detected SiteCode: $siteCode"
        }

        # -------------------------------
        # Step 2: Ensure ConfigMgr Module + PSDrive
        # -------------------------------
        if (-not (Get-PSDrive -Name $siteCode -ErrorAction SilentlyContinue)) {

            Write-Verbose "PSDrive '$siteCode' not found. Attempting to initialize..."

            $cmModulePath = Join-Path $ENV:SMS_ADMIN_UI_PATH "..\ConfigurationManager.psd1"

            if (-not (Test-Path $cmModulePath)) {
                throw "ConfigurationManager module not found. Install SCCM Console."
            }

            Import-Module $cmModulePath -ErrorAction Stop
            Write-Verbose "ConfigurationManager module loaded."

            try {
                Set-Location "$siteCode`:" -ErrorAction Stop
                Write-Verbose "Connected to site drive: $siteCode"
            }
            catch {
                throw "Failed to switch to PSDrive '$siteCode'. Verify site code."
            }
        }

        $rootPath = "$siteCode`:"
        
        # -------------------------------
        # Step 3: Normalize Path
        # -------------------------------
        $cleanPath = $cleanPath.Trim('\')

        if ([string]::IsNullOrWhiteSpace($cleanPath)) {
            throw "Path cannot be empty."
        }

        $segments = ($cleanPath -split '\\') | Where-Object { $_ }

        Write-Verbose "Normalized Path: $cleanPath"
        Write-Verbose "Segments: $($segments -join ' -> ')"

        # -------------------------------
        # Step 4: Create Path Step-by-Step
        # -------------------------------
        $currentPath = $rootPath

        foreach ($folder in $segments) {
            $nextPath = Join-Path $currentPath $folder

            if (-not (Test-Path $nextPath)) {
                if ($PSCmdlet.ShouldProcess($nextPath, "Create folder")) {
                    New-Item -Path $currentPath -Name $folder -ItemType Directory -ErrorAction Stop
                    Write-Verbose "Created: $nextPath"
                }
            }
            else {
                Write-Verbose "Exists: $nextPath"
            }

            $currentPath = $nextPath
        }

        # -------------------------------
        # Step 5: Handle Optional Name
        # -------------------------------
        if ($Name) {
            if ([string]::IsNullOrWhiteSpace($Name)) {
                throw "Folder name cannot be empty."
            }

            $finalPath = Join-Path $currentPath $Name

            if (-not (Test-Path $finalPath)) {
                if ($PSCmdlet.ShouldProcess($finalPath, "Create folder")) {
                    New-Item -Path $currentPath -Name $Name -ItemType Directory -ErrorAction Stop
                    Write-Verbose "Created final folder: $finalPath"
                }
            }
            else {
                Write-Verbose "Final folder already exists: $finalPath"
            }
        }
        else {
            # No Name → full path already created
            $finalPath = $currentPath
            Write-Verbose "No child name provided. Full path ensured."
        }

        # -------------------------------
        # Step 6: Return Result
        # -------------------------------
        return [PSCustomObject]@{
            Success  = $true
            Path     = $finalPath
            SiteCode = $siteCode
        }
    }
    catch {
        Write-Error "Failed: $($_.Exception.Message)"

        return [PSCustomObject]@{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}
#############################################################
# Example usage 
<#
New-PCXCMFolder -Path "\DeviceCollection\RootFolder\" -Name "Child"
New-PCXCMFolder -Path "DeviceCollection\RootFolder" -Name "Child"
New-PCXCMFolder -Path "\DeviceCollection\RootFolder" -Name "Child"
New-PCXCMFolder -Path "\DeviceCollection\RootFolder" 

#New-PCXCMFolder -Path "\DeviceCollection\RootFolder\SubFoler" -Name "Child" -AutoCreatePath
#New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFoler" -Name "Child" -AutoCreatePath
#New-PCXCMFolder -Path "DeviceCollection\RootFolder\" -Name "Child" -AutoCreatePath
#New-PCXCMFolder -Path "\DeviceCollection\" -Name "Child" -AutoCreatePath
#New-PCXCMFolder -Path "\DeviceCollection\AAA" -Name "Child"
#>

<#
This can work on all below root folders

New-PCXCMFolder -Path "\Application\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\BootImage\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\ConfigurationBaseline\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\ConfigurationItem\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\DeviceCollection\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\Driver\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\DriverPackage\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\OperatingSystemImage\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\OperatingSystemInstaller\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\Package\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\Query\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\SoftwareMetering\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\SoftwareUpdate\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\TaskSequence\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\UserCollection\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\UserStateMigration\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\VirtualHardDisk\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\DeploymentPackage\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\SoftwareUpdateGroup\RootFolder\" -Name "Child"

New-PCXCMFolder -Path "\AutoDeploymentRule\RootFolder\" -Name "Child"

#>

#############################################################
# Reproducing command 
<#
Remove-PCXCMFolder "PS1:\DeviceCollection\RootFolder\Test"
Remove-PCXCMFolder "PS1:\DeviceCollection\RootFolder"
Remove-PCXCMFolder "PS1:\DeviceCollection\RootFolder\SubFolder"
Get-ChildItem -path "PS1:\DeviceCollection\RootFolder"
#>

#############################################################
#Remove-Module PCXCMModule
#Remove-Module PCXCMModule -Force
#############################################################
<#
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder" -Name "Child"
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\" -Name "Child"
New-PCXCMFolder -Path "\DeviceCollection\RootFolder\SubFolder\" -Name "Child"
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\"
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\Tree"
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\Tree"
#>

# Test Cases
<#

#1. Standard PSDrive paths
# Normal path with Name
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder" -Name "Child"

# Trailing backslash
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\" -Name "Child"

# Nested folder creation
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\Tree" -Name "Leaf"

#2. Paths without PSDrive (function should auto-detect SiteCode)
# Relative path, no PSDrive prefix
New-PCXCMFolder -Path "\DeviceCollection\RootFolder\SubFolder" -Name "Child"

# Nested path without PSDrive
New-PCXCMFolder -Path "DeviceCollection\RootFolder\SubFolder\Tree" -Name "Leaf"

#3. Paths without -Name (full path creation)
# Only ensure full path exists
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\Tree"

# Without trailing backslash
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\Tree2"

#4. Edge cases / input validation
# Empty path (should fail)
New-PCXCMFolder -Path "" -Name "Child"

# Name is whitespace (should fail)
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder" -Name "   "

# Path with multiple consecutive backslashes
New-PCXCMFolder -Path "PS1:\DeviceCollection\\RootFolder\\SubFolder" -Name "Child"

#5. Existing folders
# Path and Name already exist (should not throw an error)
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder" -Name "Child"

# Existing nested folders (should skip creation and report verbose)
New-PCXCMFolder -Path "PS1:\DeviceCollection\RootFolder\SubFolder\Tree" -Name "Leaf"

#6. Invalid PSDrive
# PSDrive that does not exist
New-PCXCMFolder -Path "PX1:\DeviceCollection\RootFolder" -Name "Child"

#>


# Run all cases

<#

# -------------------------------
# Test harness for New-PCXCMFolder
# -------------------------------

# Define all test cases as objects
$testCases = @(
    # Standard PSDrive paths
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder"; Name = "Child" },
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder\"; Name = "Child" },
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder\Tree"; Name = "Leaf" },

    # Paths without PSDrive
    @{ Path = "\DeviceCollection\RootFolder\SubFolder"; Name = "Child" },
    @{ Path = "DeviceCollection\RootFolder\SubFolder\Tree"; Name = "Leaf" },

    # Paths without Name
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder\Tree"; Name = $null },
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder\Tree2"; Name = $null },

    # Edge cases
    @{ Path = ""; Name = "Child" },                            # Should fail
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder"; Name = "   " }, # Should fail
    @{ Path = "PS1:\DeviceCollection\\RootFolder\\SubFolder"; Name = "Child" },

    # Existing folders
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder"; Name = "Child" },
    @{ Path = "PS1:\DeviceCollection\RootFolder\SubFolder\Tree"; Name = "Leaf" },

    # Invalid PSDrive
    @{ Path = "PX1:\DeviceCollection\RootFolder"; Name = "Child" }
)

# Array to store results
$results = @()

foreach ($test in $testCases) {
    try {
        Write-Host "Running test: Path='$($test.Path)' Name='$($test.Name)'" -ForegroundColor Cyan

        # Run the function
        $output = if ($test.Name) {
            New-PCXCMFolder -Path $test.Path -Name $test.Name -Verbose -WhatIf
        } else {
            New-PCXCMFolder -Path $test.Path -Verbose -WhatIf
        }

        # Store result
        $results += [PSCustomObject]@{
            Path     = $test.Path
            Name     = $test.Name
            Success  = $output.Success
            Message  = if ($output.Success) { "Folder creation simulated/passed" } else { $output.Error }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Path     = $test.Path
            Name     = $test.Name
            Success  = $false
            Message  = $_.Exception.Message
        }
    }
}

# Display results in table
$results | Format-Table -AutoSize

<#
✅ Features of this test harness:
Runs all test cases automatically.
Uses -WhatIf so no real SCCM folders are created—safe to run.
Captures success/failure and error messages.
Prints a clean table summary at the end.
Handles both -Name provided and not provided.
#>

#>
<#

$results
$results.Count
$results[8]

#>
