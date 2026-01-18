# Contributing to setup-crmsdk

Thank you for your interest in contributing to setup-crmsdk!

## Development Setup

### Prerequisites

- Windows (PowerShell 5.1+)
- Git

### Clone and Test

```powershell
git clone https://github.com/marcus-hooper/setup-crmsdk.git
cd setup-crmsdk
.\scripts\Install-CrmSdk.ps1
```

### Verify Setup

```powershell
# Run Pester tests
Invoke-Pester -Path ./tests -Output Detailed
```

## Running CI Locally

Before pushing, run the same checks as CI:

```powershell
# Lint check (must pass)
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery

# Format check (must pass)
$scripts = Get-ChildItem -Path ./scripts -Include *.ps1,*.psm1 -Recurse
foreach ($script in $scripts) {
    $content = Get-Content $script.FullName -Raw
    $formatted = Invoke-Formatter -ScriptDefinition $content
    if ($content -ne $formatted) {
        Write-Host "Formatting issues in: $($script.Name)"
    }
}

# Unit tests (must pass)
Invoke-Pester -Path ./tests -Output Detailed
```

### Quick CI Script

```powershell
# All-in-one CI check
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery; if ($?) { Invoke-Pester -Path ./tests -Output Detailed }
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `ci` | CI/workflow changes |
| `deps` | Dependency updates |
| `security` | Security improvements |
| `chore` | Other maintenance tasks |
| `perf` | Performance improvement |

### Examples

```
feat: add support for specifying SDK version

fix: handle missing LOCALAPPDATA environment variable

docs: update usage examples in README

test: add tests for Set-CrmSdkEnvironmentVariable

ci: add CodeQL security scanning

deps: update actions/checkout to v6

security: pin GitHub Actions to commit SHAs
```

### Breaking Changes

For breaking changes, use `!` after the type or add a `BREAKING CHANGE:` footer:

```
feat!: change installation directory structure

SDK tools now install to $LOCALAPPDATA\CrmSdk\ instead of $LOCALAPPDATA\Programs\
```

Or with a footer:

```
feat: change installation directory structure

BREAKING CHANGE: SDK tools now install to $LOCALAPPDATA\CrmSdk\ instead of $LOCALAPPDATA\Programs\
```

## Pull Request Process

### Before Opening a PR

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Run CI locally** (see above)

3. **Add tests** for new functionality

4. **Update CHANGELOG.md** under `[Unreleased]`

### PR Requirements

All PRs must pass these checks before merge:

| Check | Command | Threshold |
|-------|---------|-----------|
| Lint | `Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery` | No errors |
| Format | See format check in [Running CI Locally](#running-ci-locally) | No changes |
| Tests | `Invoke-Pester -Path ./tests` | All pass |
| Coverage | Collected automatically | 80%+ target (not enforced) |

### PR Description

Use the [PR template](.github/PULL_REQUEST_TEMPLATE.md). Include:

- Summary of changes
- Related issue (if any)
- Type of change
- Testing performed

### Code Review

- All PRs require at least one approval
- Address review feedback promptly
- Resolve all conversations before merge
- Squash merge to `main`

## Test Requirements

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ./tests -Output Detailed

# Run tests with coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('./scripts/Install-CrmSdk.ps1', './scripts/Install-CrmSdk.psm1')
Invoke-Pester -Configuration $config
```

### Adding Tests

| Change Type | Test Requirement |
|-------------|------------------|
| New function | Add unit tests covering happy path and error cases |
| Bug fix | Add regression test that fails without the fix |
| Refactor | Ensure existing tests still pass |

Tests are located in `tests/Install-CrmSdk.Tests.ps1`. See existing tests for patterns on mocking external dependencies like `Invoke-WebRequest` and `nuget.exe`.

## Coding Standards

### Project-Specific Guidelines

```powershell
# Use Test-Path for environment variable checks (not $env:VAR -ne $null)
if (Test-Path env:CRM_SDK_PATH) {
    # Variable exists
}

# Mock external dependencies in tests (Invoke-WebRequest, nuget.exe)
Mock Invoke-WebRequest { }
Mock nuget.exe { return 0 }
```

### PowerShell Best Practices

```powershell
# Use ErrorAction Stop for critical operations
Invoke-WebRequest -Uri $url -OutFile $file -ErrorAction Stop

# Use try/finally for cleanup
try {
    Push-Location $tempDir
    # ... work
} finally {
    Pop-Location
}

# Check exit codes after external commands
& nuget.exe install $package
if ($LASTEXITCODE -ne 0) {
    throw "NuGet install failed"
}

# Use Test-Path for environment variable checks
if (Test-Path env:CRM_SDK_PATH) {
    # Variable exists
}

# Add SupportsShouldProcess for state-changing functions
function Set-Something {
    [CmdletBinding(SupportsShouldProcess)]
    param(...)
}
```

### Function Guidelines

- Use `Write-Message` for consistent logging
- Use `Invoke-Safely` for error handling with context
- Export functions via module manifest
- Add comment-based help for public functions

### Adding New Functions

When adding functions to `Install-CrmSdk.psm1`:

1. Add the function implementation
2. Add it to `Export-ModuleMember -Function` at the bottom of the module
3. Add corresponding Pester tests in `tests/Install-CrmSdk.Tests.ps1`

Keep `.ps1` entry points minimal—put testable logic in the `.psm1` module.

## Issue Guidelines

### Bug Reports

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml). Include:

- Operating system and PowerShell version
- Steps to reproduce
- Expected vs actual behavior
- Relevant error messages

### Feature Requests

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml). Include:

- Problem statement
- Proposed solution
- Alternatives considered

## Release Process

Releases are managed by maintainers:

1. All CI checks pass on `main`
2. CHANGELOG.md updated with version and date
3. Tag created: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Tag pushed: `git push origin v1.0.0`
5. GitHub Actions creates release and updates major version tag

## Getting Help

- **Questions**: Open a [Discussion](../../discussions)
- **Bugs**: Open an [Issue](../../issues)
- **Security**: See [SECURITY.md](SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
