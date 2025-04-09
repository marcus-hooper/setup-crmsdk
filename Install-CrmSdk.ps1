# Description: This script installs the CRM SDK tools and sets the environment variable CRM_SDK_PATH

# Function to log messages
function Write-Message {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    Write-Host "[$Level] $Message"
}

# Check if the CRM_SDK_PATH environment variable is already set
if (-not (Get-ChildItem -Path "env:CRM_SDK_PATH" -ErrorAction SilentlyContinue)) {
    Write-Message "CRM_SDK_PATH is not set. Proceeding with installation."

    # Ensure the Programs folder exists in the user's local app data directory
    $programsPath = "$env:LOCALAPPDATA\Programs\"
    if (-not (Test-Path $programsPath)) {
        Write-Message "Creating Programs folder at $programsPath."
        New-Item -Path $programsPath -ItemType Directory -Force | Out-Null
    }

    # Download the latest version of the NuGet CLI
    $nugetPath = Join-Path -Path $programsPath -ChildPath "nuget.exe"
    if (-not (Test-Path $nugetPath)) {
        Write-Message "Downloading NuGet CLI to $nugetPath."
        Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath -ErrorAction Stop
    }
    else {
        Write-Message "NuGet CLI already exists at $nugetPath. Skipping download."
    }

    # Add NuGet source if not already added
    Push-Location $programsPath
    & $nugetPath sources Add -Name MySource -Source https://api.nuget.org/v3/index.json
    Write-Message "NuGet source added."

    # Install the Microsoft.CrmSdk.CoreTools package
    Write-Message "Installing Microsoft.CrmSdk.CoreTools package."
    & $nugetPath install Microsoft.CrmSdk.CoreTools

    # Locate the SolutionPackager.exe file and set the CRM_SDK_PATH environment variable
    $solutionPackager = Get-ChildItem -Path $programsPath -Recurse -Filter "SolutionPackager.exe"
    if ($solutionPackager) {
        $sdkPath = $solutionPackager.Directory.Parent.FullName
        [Environment]::SetEnvironmentVariable("CRM_SDK_PATH", $sdkPath, "User")
        $env:CRM_SDK_PATH = $sdkPath
        Write-Message "CRM_SDK_PATH set to $sdkPath."
    }
    else {
        Write-Message "SolutionPackager.exe not found. Installation failed." "ERROR"
        Exit 1
    }

    # Clean up the NuGet CLI
    Remove-Item $nugetPath -Force
    Write-Message "Cleaned up NuGet CLI."

    Pop-Location
}
else {
    Write-Message "CRM_SDK_PATH is already set to $env:CRM_SDK_PATH. Skipping installation."
}