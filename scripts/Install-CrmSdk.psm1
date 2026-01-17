# Install-CrmSdk Module
# Exports testable functions for installing CRM SDK tools

function Write-Message {
    <#
    .SYNOPSIS
        Logs a message with a specified level.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'ERROR', 'WARN')]
        [string]$Level = 'INFO'
    )

    Write-Host "[$Level] $Message"
}

function Invoke-Safely {
    <#
    .SYNOPSIS
        Executes a script block and handles errors with a custom message.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Command,

        [Parameter(Mandatory)]
        [string]$ErrorMessage
    )

    try {
        & $Command
    }
    catch {
        Write-Message "$ErrorMessage`: $_" 'ERROR'
        throw
    }
}

function Set-CrmSdkEnvironmentVariable {
    <#
    .SYNOPSIS
        Sets an environment variable with GitHub Actions compatibility.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    if ($PSCmdlet.ShouldProcess("$Name=$Value", 'Set environment variable')) {
        # Set for current process
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
        Set-Item -Path "env:$Name" -Value $Value

        # Set for GitHub Actions (persists to subsequent steps)
        if ($env:GITHUB_ENV) {
            "$Name=$Value" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
            Write-Message "Environment variable $Name exported to GitHub Actions."
        }

        # Set for user scope (persists outside of CI)
        if (-not $env:CI) {
            [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
        }
    }
}

function Get-NuGetCli {
    <#
    .SYNOPSIS
        Downloads the NuGet CLI if not already present.
    .OUTPUTS
        The path to nuget.exe
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    $nugetPath = Join-Path -Path $DestinationPath -ChildPath 'nuget.exe'

    if (-not (Test-Path $nugetPath)) {
        Write-Message "Downloading NuGet CLI to $nugetPath."
        Invoke-Safely {
            Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $nugetPath -ErrorAction Stop
        } 'Failed to download NuGet CLI'
    }
    else {
        Write-Message "NuGet CLI already exists at $nugetPath. Skipping download."
    }

    return $nugetPath
}

function Invoke-NuGetInstall {
    <#
    .SYNOPSIS
        Executes NuGet install command. Separated for testability.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$NuGetPath,

        [Parameter(Mandatory)]
        [string]$PackageName,

        [Parameter(Mandatory)]
        [string]$OutputDirectory
    )

    & $NuGetPath install $PackageName -OutputDirectory $OutputDirectory
    return $LASTEXITCODE
}

function Install-CrmSdkPackage {
    <#
    .SYNOPSIS
        Installs the Microsoft.CrmSdk.CoreTools NuGet package.
    .OUTPUTS
        The path to the installed SDK directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$NuGetPath,

        [Parameter(Mandatory)]
        [string]$InstallPath
    )

    Write-Message 'Installing Microsoft.CrmSdk.CoreTools package.'

    try {
        Push-Location $InstallPath

        $exitCode = Invoke-NuGetInstall -NuGetPath $NuGetPath -PackageName 'Microsoft.CrmSdk.CoreTools' -OutputDirectory $InstallPath
        if ($exitCode -ne 0) {
            throw ('NuGet install command failed with exit code {0}' -f $exitCode)
        }
    }
    finally {
        Pop-Location
    }

    # Locate the SolutionPackager.exe file
    $solutionPackager = Get-ChildItem -Path $InstallPath -Recurse -Filter 'SolutionPackager.exe' -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $solutionPackager) {
        throw 'SolutionPackager.exe not found. Installation failed.'
    }

    return $solutionPackager.Directory.Parent.FullName
}

function Remove-NuGetCli {
    <#
    .SYNOPSIS
        Removes the NuGet CLI after installation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$NuGetPath
    )

    if (Test-Path $NuGetPath) {
        if ($PSCmdlet.ShouldProcess($NuGetPath, 'Remove NuGet CLI')) {
            Remove-Item $NuGetPath -Force -ErrorAction SilentlyContinue
            Write-Message 'Cleaned up NuGet CLI.'
        }
    }
}

function Install-CrmSdk {
    <#
    .SYNOPSIS
        Installs the CRM SDK tools and sets the CRM_SDK_PATH environment variable.
    .DESCRIPTION
        Downloads NuGet CLI, installs Microsoft.CrmSdk.CoreTools package,
        locates SolutionPackager.exe, and sets CRM_SDK_PATH.
    .OUTPUTS
        The path to the installed CRM SDK, or the existing path if already installed.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$InstallPath = "$env:LOCALAPPDATA\Programs"
    )

    # Check if already installed
    if (Test-Path env:CRM_SDK_PATH) {
        Write-Message "CRM_SDK_PATH is already set to $env:CRM_SDK_PATH. Skipping installation."
        return $env:CRM_SDK_PATH
    }

    Write-Message 'CRM_SDK_PATH is not set. Proceeding with installation.'

    # Ensure the install directory exists
    if (-not (Test-Path $InstallPath)) {
        Write-Message "Creating install folder at $InstallPath."
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }

    $nugetPath = $null
    try {
        # Download NuGet CLI
        $nugetPath = Get-NuGetCli -DestinationPath $InstallPath

        # Install the CRM SDK package
        $sdkPath = Install-CrmSdkPackage -NuGetPath $nugetPath -InstallPath $InstallPath

        # Set the environment variable
        Set-CrmSdkEnvironmentVariable -Name 'CRM_SDK_PATH' -Value $sdkPath
        Write-Message "CRM_SDK_PATH set to $sdkPath."

        return $sdkPath
    }
    finally {
        # Clean up NuGet CLI
        if ($nugetPath) {
            Remove-NuGetCli -NuGetPath $nugetPath
        }
    }
}

Export-ModuleMember -Function @(
    'Write-Message'
    'Invoke-Safely'
    'Set-CrmSdkEnvironmentVariable'
    'Get-NuGetCli'
    'Invoke-NuGetInstall'
    'Install-CrmSdkPackage'
    'Remove-NuGetCli'
    'Install-CrmSdk'
)
