# Description: This script installs the CRM SDK tools and sets the environment variable CRM_SDK_PATH

# Check if the CRM_SDK_PATH environment variable is set
if (!((Get-ChildItem -Path "env:CRM_SDK_PATH" -ErrorAction SilentlyContinue).Value)) {

    # Check if the Programs folder exists in the user's local app data directory
    if (!(Test-Path "$env:LOCALAPPDATA\Programs\")) {
        # Create the Programs folder if it does not exist
        New-Item -Path "$env:LOCALAPPDATA\Programs\" -ItemType Directory
    }

    # Download the latest version of the NuGet CLI
    Push-Location "$env:LOCALAPPDATA\Programs\"
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile ".\nuget.exe"
    .\nuget.exe sources Add -Name MySource -Source  https://api.nuget.org/v3/index.json

    # Install the Microsoft.CrmSdk.CoreTools package
    .\nuget.exe install Microsoft.CrmSdk.CoreTools

    # Set the CRM_SDK_PATH environment variable to the path of the SolutionPackager.exe file
    $sdkPath = (Get-ChildItem SolutionPackager.exe -Recurse).Directory.Parent.FullName
    [Environment]::SetEnvironmentVariable("CRM_SDK_PATH", $sdkPath, "User")
    $env:CRM_SDK_PATH = $sdkPath

    # Clean up the NuGet CLI
    Remove-Item .\nuget.exe
    Pop-Location
}