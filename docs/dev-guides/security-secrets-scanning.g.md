# Secrets Scanning Guide

This guide covers the secrets scanning implementation in Coding Agent Tools, including local development scanning with Gitleaks and GitHub's native push protection.

## Overview

The project implements a multi-layered approach to prevent secrets from being committed:

1. **Local Development Scanning**: `bin/lint-security` standalone script with Gitleaks for immediate feedback
2. **GitHub Push Protection**: Automatic blocking of commits containing known secrets
3. **Configuration Management**: Proper exclusions for test data and documentation examples
4. **Gitignore Integration**: Automatic exclusion of files matching `.gitignore` patterns
5. **File Size Management**: Skip large files (>1MB) by default to avoid scanning logs and data dumps

## Local Secrets Scanning with Gitleaks

### Standalone bin/lint-security Script

The project provides a dedicated `bin/lint-security` script for security scanning, which is called by `bin/lint`:

```bash
# Run both StandardRB and security scanning
bin/lint

# Or run security scanning directly with options
bin/lint-security
bin/lint-security --full
bin/lint-security --git-past
bin/lint-security --full --git-past --verbose
```

#### Command Options

- **Default**: Scans current files under 1MB, respects `.gitignore`
- **`--full`**: Includes large files (>1MB) in scan
- **`--git-past`**: Scans entire git history for historical secrets
- **`--verbose`**: Provides detailed output during scanning
- **`--help`**: Shows all available options

### Installation

Gitleaks is an optional dependency. Install it for enhanced development experience:

```bash
# macOS
brew install gitleaks

# Linux (Ubuntu/Debian)
sudo apt-get install gitleaks

# Other platforms
# See: https://github.com/gitleaks/gitleaks#installation
```

### Configuration

The project uses `.gitleaks.toml` for configuration:

- **Base Rules**: Uses Gitleaks' default secret detection patterns
- **File Size Limits**: 1MB limit by default (configurable with `--full`)
- **Exclusions**: VCR cassettes, test fixtures, build artifacts
- **Allowlist**: Known safe patterns and placeholder values
- **Gitignore Integration**: Automatically excludes files matching `.gitignore`

Key exclusions:
- **Gitignore Files**: All patterns in `.gitignore` are automatically excluded
- `spec/cassettes/` - VCR cassettes with filtered API responses
- `spec/fixtures/` - Test fixtures with example data
- `.env` files - Local development environment variables
- Large files (>1MB) - Logs, dumps, and data files unless `--full` is used
- Documentation examples with placeholder values

## GitHub Push Protection

### How It Works

GitHub's push protection is automatically enabled for all public repositories:

1. **Scan on Push**: Every commit is scanned before being accepted
2. **Block Secrets**: Known secret patterns are blocked automatically
3. **Developer Guidance**: Clear messages help developers remediate issues
4. **Override Options**: Maintainers can override false positives if needed

### Limitations

GitHub push protection has some limitations that local scanning addresses:

- **Limited Patterns**: Only detects highly identifiable secrets
- **Pattern Pairs**: Requires ID and secret in same file
- **Large Pushes**: May skip scanning very large commits
- **Historical Secrets**: Doesn't scan existing repository history
- **Offline Development**: Requires push to detect issues

### Complementary Benefits

Local Gitleaks scanning complements GitHub protection by:

- **Immediate Feedback**: Catch secrets during development
- **Broader Detection**: More comprehensive pattern matching
- **Offline Capability**: Works without network connection
- **Historical Scanning**: Can scan entire git history with `--git-past`
- **Faster Iteration**: Fix issues before attempting to push
- **Gitignore Respect**: Automatically excludes development files
- **Performance Optimization**: Skips large files by default, use `--full` when needed

## Handling Secrets in Development

### Environment Variables

Use environment variables for sensitive configuration:

```ruby
# Good: Use environment variables
api_key = ENV['GEMINI_API_KEY']
github_token = ENV['GITHUB_TOKEN']

# Bad: Hardcoded secrets
api_key = "hardcoded-secret-example"
```

### Local Environment Files

Store development secrets in `.env` files (excluded from git):

```bash
# .env (not committed)
GEMINI_API_KEY=your_actual_key_here
GITHUB_TOKEN=ghp_your_token_here
```

### Test Data and Fixtures

Use placeholder values in test data:

```ruby
# Good: Placeholder values
let(:api_key) { "test-api-key-12345" }
let(:secret) { "fake-secret-for-testing" }

# Bad: Real-looking secrets
let(:api_key) { "realistic-but-fake-key-example" }
```

### VCR Cassettes

VCR automatically filters sensitive data:

```ruby
# VCR configuration (spec/support/vcr.rb)
config.filter_sensitive_data("<GEMINI_API_KEY>") do |interaction|
  interaction.request.headers["X-Goog-Api-Key"]&.first
end
```

Filtered cassettes are excluded from secret scanning to prevent false positives.

## Documentation Examples

Use clear placeholder patterns in documentation:

```markdown
# Good: Clear placeholders
export GEMINI_API_KEY="your_api_key_here"

# Acceptable: Example format
GITHUB_TOKEN="ghp_example1234567890abcdef"

# Bad: Real-looking values
API_KEY="fake-realistic-key-for-example-only"
```

## Troubleshooting

### False Positives

If Gitleaks detects a false positive:

1. **Verify it's not actually sensitive**: Double-check the detected value
2. **Use placeholder patterns**: Replace with clearly fake values
3. **Check exclusions**: Ensure the file should be scanned
4. **Update configuration**: Add allowlist patterns if needed

### Common Issues

**Issue**: Gitleaks not found
```bash
INFO: Gitleaks not installed - skipping secrets scanning
```
**Solution**: Install Gitleaks or continue without it (optional dependency)

**Issue**: Large files not being scanned
```bash
INFO: Respecting file size limits (1MB) - use --full to override
```
**Solution**: Use `bin/lint-security --full` to scan all files including large ones

**Issue**: Files in `.gitignore` being scanned
**Solution**: Gitleaks automatically respects `.gitignore` - check if file is actually ignored

**Issue**: Need to scan git history
**Solution**: Use `bin/lint-security --git-past` to scan entire repository history

**Issue**: VCR cassettes triggering alerts
```bash
Finding: <GEMINI_API_KEY>
```
**Solution**: Verify cassettes are in `spec/cassettes/` (should be excluded)

**Issue**: Test fixtures triggering alerts
**Solution**: Use placeholder values like `test-key-123` instead of realistic secrets

### Performance Considerations

- **Scan Time**: Typically 1-3 seconds for current files, longer for git history
- **File Size Limits**: Large files (>1MB) are skipped by default, use `--full` to override
- **Memory Usage**: Minimal impact on development workflow
- **Gitignore Integration**: Automatically excludes ignored files for better performance
- **CI Integration**: Uses existing `bin/lint` command in CI/CD

## Best Practices

### For Developers

1. **Run `bin/lint` regularly** during development
2. **Install Gitleaks** for immediate feedback
3. **Use `bin/lint-security --git-past`** periodically to check history
4. **Use `bin/lint-security --full`** when working with large files
5. **Use environment variables** for all secrets
6. **Keep `.env` files local** (never commit them)
7. **Use placeholder values** in tests and documentation

### For Maintainers

1. **Review Gitleaks configuration** periodically
2. **Update allowlist patterns** for new false positives
3. **Monitor push protection alerts** in GitHub
4. **Run `bin/lint-security --git-past --full`** for comprehensive audits
5. **Document secret handling** for contributors
6. **Validate exclusion patterns** work correctly
7. **Update `.gitignore` patterns** as needed for new file types

### For CI/CD

1. **Use existing `bin/lint`** command in workflows
2. **Don't require Gitleaks** in CI (graceful fallback)
3. **Rely on GitHub push protection** as primary defense
4. **Consider `bin/lint-security --git-past`** for periodic full scans
5. **Test secret handling** in development environments
6. **Use `bin/lint-security --full`** for comprehensive release audits

## Security Considerations

### Defense in Depth

The multi-layered approach provides:

- **Prevention**: Local scanning catches issues early
- **Protection**: GitHub blocking prevents publication
- **Detection**: Multiple tools reduce false negatives
- **Education**: Clear guidance helps developers

### Limitations

Remember that secrets scanning:

- **Cannot detect all secrets**: Some patterns may be missed
- **May have false positives**: Requires human judgment
- **Doesn't protect history**: Existing secrets need manual cleanup
- **Requires developer cooperation**: Can be bypassed if needed

### Recommendations

- **Rotate secrets immediately** if accidentally committed
- **Use short-lived tokens** when possible
- **Implement proper secret management** in production
- **Regular security audits** of the codebase
- **Developer training** on secure coding practices

## References

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Gitleaks Configuration](https://github.com/gitleaks/gitleaks#configuration)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [GitHub Push Protection](https://docs.github.com/en/code-security/secret-scanning/push-protection-for-repositories-and-organizations)
- [VCR Gem Documentation](https://github.com/vcr/vcr)
- [Environment Variable Best Practices](https://12factor.net/config)
- [Gitignore Documentation](https://git-scm.com/docs/gitignore)