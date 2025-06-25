---
id: v.0.2.0+task.48
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Harden File-IO Layer with Path Sanitization and Confirmation

## 0. Task Context Update ✅

### Current State Analysis

The existing `FileIoHandler` (molecules/file_io_handler.rb) provides basic file operations with:
- File size validation (10MB limit)
- Basic path existence checks
- Read/write permission validation
- Format inference from file extensions

However, it lacks:
- Path traversal attack prevention
- Symlink resolution and validation
- Directory allowlist/denylist controls
- User confirmation for overwrites
- Security-focused logging

### Implementation Approach

This task will completely refactor the security architecture while maintaining the existing API surface for backward compatibility. The new architecture introduces:
1. **SecurityLogger** (Atom) - Handles security event logging without exposing sensitive paths
2. **SecurePathValidator** (Molecule) - Comprehensive path validation with allowlist/denylist
3. **FileOperationConfirmer** (Molecule) - Interactive confirmation with CI awareness
4. **Enhanced FileIoHandler** - Integrates all security components

The focus is exclusively on securing the `exe/llm-query` command, which uses FileIoHandler for:
- Reading prompt files (line 106: `process_content`)
- Reading system instruction files (line 117: `process_system_instruction`)
- Writing output files (line 202: `write_content`)
- Inferring output format (line 222: `infer_format_from_path`)

## Objective

Harden the File-IO layer to prevent path traversal attacks and add confirmation mechanisms before overwriting files. This focuses specifically on securing file operations used by the `exe/llm-query` command, which handles both prompt input files and output files. Breaking changes are acceptable to achieve better security architecture.

## Scope of Work

- Implement comprehensive path sanitization to block directory traversal attempts (../, ..\, symlinks)
- Add `--force` flag to `llm-query` command to bypass file overwrite confirmations
- Implement interactive confirmation prompts when overwriting existing files
- Create secure path validator with configurable allowlist/denylist directories
- Replace current FileIoHandler security with more robust architecture
- Add security-focused logging without exposing sensitive paths
- Focus exclusively on `exe/llm-query` integration

### Deliverables

#### Create

- `lib/coding_agent_tools/molecules/secure_path_validator.rb` - Path sanitization and validation logic
- `lib/coding_agent_tools/molecules/file_operation_confirmer.rb` - Interactive confirmation prompts
- `lib/coding_agent_tools/atoms/security_logger.rb` - Security-focused logging without exposing paths
- `spec/coding_agent_tools/molecules/secure_path_validator_spec.rb`
- `spec/coding_agent_tools/molecules/file_operation_confirmer_spec.rb`
- `spec/coding_agent_tools/atoms/security_logger_spec.rb`
- `spec/support/shared_examples/path_traversal_attacks.rb`

#### Modify

- `lib/coding_agent_tools/cli/commands/llm/query.rb` - Add --force flag and integrate security
- `lib/coding_agent_tools/molecules/file_io_handler.rb` - Complete refactor with new security architecture
- `spec/coding_agent_tools/molecules/file_io_handler_spec.rb` - Update tests for new architecture
- `spec/integration/llm_file_io_integration_spec.rb` - Add security integration tests
- `lib/coding_agent_tools.rb` - Update requires

#### Delete

- Current basic validation in FileIoHandler (replaced with comprehensive security)

## Phases

1. Analyze current FileIoHandler usage in llm-query command
2. Design comprehensive path sanitization system with allowlist/denylist
3. Implement SecurePathValidator with symlink and traversal protection
4. Create FileOperationConfirmer for interactive prompts
5. Refactor FileIoHandler with new security architecture
6. Integrate --force flag into llm-query command
7. Add comprehensive security testing including attack vectors

## Implementation Plan

### Planning Steps

* [ ] Analyze FileIoHandler usage patterns in llm-query command (lines 83, 106, 202, 222)
  > TEST: Usage Pattern Analysis
  > Type: Pre-condition Check
  > Assert: All FileIoHandler calls in llm-query documented with security implications
  > Command: grep -n "FileIoHandler\|@file_handler" lib/coding_agent_tools/cli/commands/llm/query.rb
* [ ] Research Ruby path traversal prevention (Pathname#realpath, File.expand_path security)
* [ ] Design allowlist/denylist configuration for SecurePathValidator
  - Default allowlist: current directory and subdirectories
  - Default denylist: system directories, home directory roots, .git
* [ ] Design confirmation UX that works for both interactive terminals and CI environments

### Execution Steps

- [ ] Create `SecurityLogger` atom for security event logging
  > TEST: Security Logger
  > Type: Action Validation
  > Assert: Logger sanitizes paths and logs security events
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/security_logger_spec.rb
- [ ] Create `SecurePathValidator` molecule with comprehensive path checks
  > TEST: Path Validator Security
  > Type: Action Validation
  > Assert: Blocks ../../../etc/passwd, symlinks to /etc, and other attacks
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/secure_path_validator_spec.rb
- [ ] Implement path normalization using Pathname#cleanpath and #realpath
- [ ] Add configurable allowlist/denylist with sensible defaults
- [ ] Create `FileOperationConfirmer` with TTY detection for CI compatibility
  > TEST: Confirmation Flow
  > Type: Action Validation
  > Assert: Interactive prompts in TTY, auto-deny in CI without --force
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/file_operation_confirmer_spec.rb
- [ ] Add --force flag to llm/query.rb command definition
  > TEST: Force Flag Integration
  > Type: Action Validation
  > Assert: --force flag properly defined and passed to FileIoHandler
  > Command: exe/llm-query google "test" --output test.txt --force --help | grep -q "force"
- [ ] Refactor FileIoHandler to use new security components
  - Replace basic validation with SecurePathValidator
  - Integrate FileOperationConfirmer for write operations
  - Add SecurityLogger for all file operations
- [ ] Create shared examples for path traversal attack patterns
  > TEST: Attack Vector Coverage
  > Type: Action Validation
  > Assert: Tests cover 20+ path traversal patterns
  > Command: rspec spec/support/shared_examples/path_traversal_attacks.rb --dry-run | grep -c "example"
- [ ] Add integration tests for llm-query with malicious paths
- [ ] Verify backward compatibility for non-security features

## Acceptance Criteria

- [ ] AC 1: Path traversal attacks including ../, ..\, and symlink attacks are blocked
- [ ] AC 2: Symlinks resolving outside allowlist are rejected with clear error
- [ ] AC 3: File operations restricted to current directory and subdirectories by default
- [ ] AC 4: System directories (/etc, /usr, /bin) blocked by default denylist
- [ ] AC 5: Interactive confirmation prompt shown before overwriting files (when TTY present)
- [ ] AC 6: `--force` flag in llm-query bypasses all confirmation prompts
- [ ] AC 7: Non-interactive environments (CI) safely deny overwrites without --force
- [ ] AC 8: Security events logged with sanitized paths (no sensitive info exposed)
- [ ] AC 9: Clear error messages guide users to safe file paths
- [ ] AC 10: All tests pass including new security test suite

## Out of Scope

- ❌ Implementing file encryption or advanced access controls
- ❌ Adding file backup/versioning before overwrite
- ❌ Complex permission management or user authentication
- ❌ Network-based file operations (focus on local file system only)
- ❌ Securing other CLI commands beyond llm-query
- ❌ Windows-specific path security (focus on Unix-like systems first)

## References

- [Current FileIoHandler Implementation](../../../../lib/coding_agent_tools/molecules/file_io_handler.rb)
- [LLM Query Command](../../../../lib/coding_agent_tools/cli/commands/llm/query.rb)
- [OWASP Path Traversal Prevention](https://owasp.org/www-community/attacks/Path_Traversal)
- [ATOM Architecture](../../../../docs/architecture.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)
- [Ruby Pathname Security](https://ruby-doc.org/stdlib/libdoc/pathname/rdoc/Pathname.html#method-i-realpath)