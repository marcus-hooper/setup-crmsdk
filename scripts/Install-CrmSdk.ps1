# Description: This script installs the CRM SDK tools and sets the environment variable CRM_SDK_PATH

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Import the module
$modulePath = Join-Path $PSScriptRoot 'Install-CrmSdk.psm1'
Import-Module $modulePath -Force

# Run the installation
$sdkPath = Install-CrmSdk

# Output the path for GitHub Actions
if ($sdkPath) {
    Write-Output "sdk-path=$sdkPath"
}
