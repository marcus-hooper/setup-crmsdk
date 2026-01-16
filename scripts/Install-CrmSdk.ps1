# Description: This script installs the CRM SDK tools and sets the environment variable CRM_SDK_PATH

# Function to log messages
function Write-Message {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    Write-Host "[$Level] $Message"
}

# Function to safely execute a script block and handle errors
function Invoke-Safely {
    param (
        [scriptblock]$Command,
        [string]$ErrorMessage
    )
    try {
        & $Command
    } catch {
        Write-Message "$ErrorMessage`: $_" "ERROR"
        throw
    }
}

# Function to set environment variable (GitHub Actions compatible)
function Set-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$Name,
        [string]$Value
    )

    if ($PSCmdlet.ShouldProcess("$Name=$Value", "Set environment variable")) {
        # Set for current process
        [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
        Set-Item -Path "env:$Name" -Value $Value

        # Set for GitHub Actions (persists to subsequent steps)
        if ($env:GITHUB_ENV) {
            "$Name=$Value" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
            Write-Message "Environment variable $Name exported to GitHub Actions."
        }

        # Set for user scope (persists outside of CI)
        if (-not $env:CI) {
            [Environment]::SetEnvironmentVariable($Name, $Value, "User")
        }
    }
}

# Check if the CRM_SDK_PATH environment variable is already set
if (-not (Test-Path env:CRM_SDK_PATH)) {
    Write-Message "CRM_SDK_PATH is not set. Proceeding with installation."

    # Ensure the Programs folder exists in the user's local app data directory
    $programsPath = "$env:LOCALAPPDATA\Programs"
    if (-not (Test-Path $programsPath)) {
        Write-Message "Creating Programs folder at $programsPath."
        New-Item -Path $programsPath -ItemType Directory -Force | Out-Null
    }

    # Download the latest version of the NuGet CLI
    $nugetPath = Join-Path -Path $programsPath -ChildPath "nuget.exe"
    if (-not (Test-Path $nugetPath)) {
        Write-Message "Downloading NuGet CLI to $nugetPath."
        Invoke-Safely {
            Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath -ErrorAction Stop
        } "Failed to download NuGet CLI"
    } else {
        Write-Message "NuGet CLI already exists at $nugetPath. Skipping download."
    }

    try {
        Push-Location $programsPath

        # Install the Microsoft.CrmSdk.CoreTools package (nuget.org is configured by default)
        Write-Message "Installing Microsoft.CrmSdk.CoreTools package."
        & $nugetPath install Microsoft.CrmSdk.CoreTools -OutputDirectory $programsPath
        if ($LASTEXITCODE -ne 0) {
            Write-Message "Failed to install Microsoft.CrmSdk.CoreTools package." "ERROR"
            Exit 1
        }

        # Locate the SolutionPackager.exe file and set the CRM_SDK_PATH environment variable
        $solutionPackager = Get-ChildItem -Path $programsPath -Recurse -Filter "SolutionPackager.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($solutionPackager) {
            $sdkPath = $solutionPackager.Directory.Parent.FullName
            Set-EnvironmentVariable -Name "CRM_SDK_PATH" -Value $sdkPath
            Write-Message "CRM_SDK_PATH set to $sdkPath."
        } else {
            Write-Message "SolutionPackager.exe not found. Installation failed." "ERROR"
            Exit 1
        }
    } finally {
        Pop-Location

        # Clean up the NuGet CLI
        if (Test-Path $nugetPath) {
            Remove-Item $nugetPath -Force -ErrorAction SilentlyContinue
            Write-Message "Cleaned up NuGet CLI."
        }
    }
} else {
    Write-Message "CRM_SDK_PATH is already set to $env:CRM_SDK_PATH. Skipping installation."
}
