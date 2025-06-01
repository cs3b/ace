# Security Guidelines

## Goal

This guide outlines essential security practices, checklists, and procedures to follow during development to
minimize vulnerabilities and protect project assets and user data.

## 1. Security Review Checklist

- **Input Validation**
  - All user inputs are sanitized (e.g., against injection attacks like SQLi, XSS)
  - File paths are canonicalized and validated against allowed directories (prevent path traversal)
  - URLs are validated and checked against allowlists if applicable

- **Authentication & Authorization**
  - Secrets (API keys, passwords, tokens) are securely stored (e.g., using vaults, environment variables, not
    hardcoded)
  - Access tokens have appropriate lifespans and are rotated/refreshed securely
  - Permissions and roles are correctly enforced for all actions

- **Data Protection**
  - Sensitive data is encrypted at rest and in transit
  - No secrets or sensitive information are included in logs
  - Secure methods are used for data deletion when required

- **Network Security**
  - Use TLS/SSL (HTTPS) for all external network communication
  - Ensure proper certificate validation
  - Configure reasonable network timeouts to prevent resource exhaustion

- **Dependency Management**
  - Regularly scan dependencies for known vulnerabilities using appropriate tools for your language/ecosystem
    (e.g., GitHub Dependabot or language-specific scanners)
  - Keep dependencies updated

- **Secure Defaults**
  - Configure services and libraries with security in mind (e.g., disable default accounts, enable security features)

### 2. Best Practices Examples (Conceptual)

**Secure Configuration:**
Load sensitive configuration like API keys, encryption keys, and database credentials from secure sources
(environment variables, secrets management systems) rather than hardcoding them. Configure security settings
like TLS versions and timeouts appropriately.

```plaintext
// Pseudocode for loading configuration securely
config = loadConfiguration();

// Fetch sensitive keys from environment or secret manager
config.encryptionKey = getSecret("ENCRYPTION_KEY");
config.apiKey = getSecret("API_KEY");

// Set security-related options
config.requestTimeout = 30; // seconds
config.sslVerification = true;
config.minTlsVersion = "TLSv1.2";

applyConfiguration(config);
```

**Secure File Handling:**
When handling file paths provided by users or external systems, always validate and sanitize them.
Canonicalize the path (resolve `..`, symbolic links) and ensure it falls within permitted base directories
to prevent path traversal attacks.

```plaintext
// Pseudocode for safe file path validation
function getSafeFilePath(untrustedPath, allowedBaseDir) {
  // Normalize the path (e.g., resolve '.', '..')
  normalizedPath = normalizePath(untrustedPath);

  // Get the absolute path
  absolutePath = resolveAbsolutePath(normalizedPath);

  // Ensure the absolute path starts with the allowed base directory
  if (!absolutePath.startsWith(allowedBaseDir)) {
    throw new SecurityError("Access denied: Path traversal attempt detected.");
  }

  // Optional: Check if the specific file exists and has correct permissions
  if (!fileExists(absolutePath) || !checkPermissions(absolutePath)) {
    throw new Error("File not accessible.");
  }

  return absolutePath;
}
```

**Secure Process Execution:**
Avoid executing external commands based directly on user input. If dynamic command execution is necessary, use
an allowlist of permitted commands and strictly sanitize any arguments passed to them. Execute commands with the
minimum required privileges and within restricted environments (e.g., specific working directory, chroot jail
if applicable).

```plaintext
// Pseudocode for safer command execution
function executeAllowedCommand(commandName, arguments) {
  allowedCommands = ["list_files", "show_content", "find_text"]; // Example allowlist

  if (!allowedCommands.includes(commandName)) {
    throw new SecurityError("Command not allowed: " + commandName);
  }

  // Sanitize each argument rigorously based on expected format
  sanitizedArgs = arguments.map(arg => sanitizeArgument(arg));

  // Execute the command with sanitized arguments in a controlled environment
  options = {
    workingDirectory: "/path/to/safe/directory",
    environmentVariables: { "PATH": "/usr/bin:/bin" } // Minimal PATH
  };
  result = runSystemCommand(commandName, sanitizedArgs, options);
  return result;
}
```

### 3. Language/Environment-Specific Examples

For specific code examples demonstrating security best practices, configuration of security tools (e.g.,
dependency scanners, static analysis security testing - SAST), or framework-specific security features, please
refer to the examples in the [./security/](./security/) sub-directory.

### 4. Security Disclosure Process

1. **Reporting**
   - Email: <security@example.com>
   - Include detailed reproduction steps
   - Provide impact assessment

2. **Response Timeline**
   - Initial response: 24 hours
   - Assessment: 72 hours
   - Fix timeline: Based on severity

3. **Severity Levels**
   - Critical: System compromise
   - High: Data exposure
   - Medium: Limited impact
   - Low: Minor issues

## Related Documentation

- [Coding Standards](docs-dev/guides/coding-standards.g.md)
- [Quality Assurance](docs-dev/guides/quality-assurance.g.md) (Code Review)
- [Error Handling](docs-dev/guides/error-handling.g.md) (Avoid leaking sensitive info)
