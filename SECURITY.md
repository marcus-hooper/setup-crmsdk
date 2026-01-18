# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Use [GitHub's private vulnerability reporting](https://github.com/marcus-hooper/setup-crmsdk/security/advisories/new) to submit a report
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Disclosure Timeline

- Acknowledgment of your report within 48 hours
- Initial assessment within 7 days
- Target resolution within 90 days for critical vulnerabilities
- Regular updates on the progress of addressing the vulnerability
- Credit in the security advisory (unless you prefer to remain anonymous)

### Scope

The following are considered security vulnerabilities:

- Malicious code injection in the installation script
- Downloading binaries from untrusted sources
- Unsafe handling of file paths or environment variables
- Issues that could compromise the CI/CD pipeline

Out of scope:

- Vulnerabilities in upstream dependencies (report to the respective project)
- Vulnerabilities in Microsoft.CrmSdk.CoreTools (report to Microsoft)
- Issues requiring physical access or social engineering

### Security Notifications

Security fixes are announced via:

- [GitHub Security Advisories](https://github.com/marcus-hooper/setup-crmsdk/security/advisories)
- Release notes for patched versions

Dependencies are monitored automatically via Dependabot.

## Security Considerations

This action performs the following operations that have security implications:

1. **Downloads NuGet CLI** from `https://dist.nuget.org/win-x86-commandline/latest/nuget.exe`
2. **Installs packages** from NuGet.org via the official NuGet CLI
3. **Sets environment variables** (`CRM_SDK_PATH`) that affect subsequent workflow steps
4. **Writes files** to `$env:LOCALAPPDATA\Programs\`

### Best Practices for Users

1. **Pin to a specific version** - Use a tagged release rather than `@main` for stability
2. **Review workflow permissions** - Grant only necessary permissions to your workflow
3. **Verify the SDK path** - The action outputs `sdk-path` which can be validated in subsequent steps
4. **Use in isolated runners** - Consider using ephemeral runners for sensitive pipelines

### Data Handling

This action:

- Does **not** transmit any data to external services (beyond NuGet.org for package download)
- Does **not** collect or store telemetry
- Does **not** access or modify files outside the installation directory
- Cleans up downloaded NuGet CLI after installation
