# File GUI_Package.ps1

# ================================
# SCCM Package GUI Tool
# ================================

Clear-Host
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

. "$PSScriptRoot\Functions.ps1"
. "$PSScriptRoot\Package Function_V0.8.4.0.ps1"
. "$PSScriptRoot\Connect-PCXCMSite.ps1"
. "$PSScriptRoot\New-PCXCMFolder_V02.03.02_A.ps1"
. "$PSScriptRoot\Get-PCXCMSiteCode.ps1"

# Connect SCCM
Connect-SCCM

# ================================
# XAML UI
# ================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SCCM Package Tool" Height="450" Width="400">

    <Grid Margin="10">

        <Label Content="Source Path:" VerticalAlignment="Top"/>
        <!--TextBox Name="txtSourcePath" Margin="0,25,0,0" Height="25" VerticalAlignment="Top"/-->

        <TextBox Name="txtSourcePath" Margin="0,25,80,0" Height="25" VerticalAlignment="Top"/>

        <Button Name="btnBrowse" Content="..." Width="60" Height="25"
        Margin="0,25,0,0" HorizontalAlignment="Right" VerticalAlignment="Top"/>

        <Label Content="Package Name:" Margin="0,60,0,0" VerticalAlignment="Top"/>
        <TextBox Name="txtPackageName" Margin="0,85,0,0" Height="25" VerticalAlignment="Top" IsReadOnly="True"/>

        <Label Content="Company:" Margin="0,120,0,0" VerticalAlignment="Top"/>
        <TextBox Name="txtCompany" Margin="0,145,0,0" Height="25" VerticalAlignment="Top" IsReadOnly="True"/>

        <Label Content="Product:" Margin="0,180,0,0" VerticalAlignment="Top"/>
        <TextBox Name="txtProduct" Margin="0,205,0,0" Height="25" VerticalAlignment="Top" IsReadOnly="True"/>

        <Label Content="Version:" Margin="0,240,0,0" VerticalAlignment="Top"/>
        <TextBox Name="txtVersion" Margin="0,265,0,0" Height="25" VerticalAlignment="Top" />

        <Button Name="btnCreatePackage" Content="Create Package" Height="30" Margin="0,310,0,0" VerticalAlignment="Top"/>

        <TextBlock Name="txtStatus" Margin="0,350,0,0" Height="60" TextWrapping="Wrap"/>

    </Grid>
</Window>
"@

# ================================
# Load UI
# ================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ================================
# Get Controls
# ================================
$txtSourcePath   = $window.FindName("txtSourcePath")
$txtPackageName  = $window.FindName("txtPackageName")
$txtCompany      = $window.FindName("txtCompany")
$txtProduct      = $window.FindName("txtProduct")
$txtVersion      = $window.FindName("txtVersion")
$btnCreatePackage = $window.FindName("btnCreatePackage")
$txtStatus       = $window.FindName("txtStatus")
$btnBrowse       = $window.FindName("btnBrowse")

# ================================
# Auto-fill from Path
# ================================
$txtSourcePath.Add_TextChanged({

    $path = $txtSourcePath.Text

    if ([string]::IsNullOrWhiteSpace($path)) {
        return
    }

    try {
        $pathSplit = $path -split "\\"

        if ($pathSplit.Count -lt 3) {
            return
        }

        $packageName = $pathSplit[-1]
        $company     = $pathSplit[-3]
        $product     = $pathSplit[-2]

        $versionSplit = $packageName -split "_"
        $version = $versionSplit[-1]

        # Populate UI
        $txtPackageName.Text = $packageName
        $txtCompany.Text     = $company
        $txtProduct.Text     = $product
        $txtVersion.Text     = $version
    }
    catch {
        # silent
    }
})

# ================================
# Browse Button (Explorer Style)
# ================================
$btnBrowse.Add_Click({

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select any file inside the Package folder"
    $openFileDialog.InitialDirectory = "C:\"
    $openFileDialog.Filter = "All files (*.*)|*.*"

    if ($openFileDialog.ShowDialog() -eq "OK") {

        # Get folder from selected file
        $folderPath = Split-Path $openFileDialog.FileName -Parent

        # Set to textbox (this will trigger auto-fill automatically)
        $txtSourcePath.Text = $folderPath
    }

})

# ================================
# Button Click
# ================================
$btnCreatePackage.Add_Click({

    $srcPath = $txtSourcePath.Text

    if ([string]::IsNullOrWhiteSpace($srcPath)) {
        $txtStatus.Text = "Enter Source Path!"
        return
    }

    try {
        $txtStatus.Text = "Running package creation..."

        # CALL YOUR FUNCTION (NO CHANGE)
        Create-Package -Path $srcPath

        $txtStatus.Text = "Package creation completed!"
    }
    catch {
        $txtStatus.Text = $_.Exception.Message
    }

})

# ================================
# Show Window
# ================================
$window.ShowDialog() | Out-Null



