---
id: v.0.9.0+task.139
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Secure Git History: Remove and Revoke Authentication Tokens

## Description

Implement a comprehensive security solution to identify, remove, and revoke authentication tokens from Git history in the ACE mono-repo. This is a critical security fix to prevent exposure of sensitive credentials (GitHub PATs, LLM API keys, cloud service credentials) that may have been inadvertently committed to Git history, especially before publishing gems or pushing to public repositories.

## Behavioral Requirements

### Core Behaviors

**B1: Git History Scanning**
- GIVEN a Git repository
- WHEN the security scan is invoked
- THEN it MUST identify all potential authentication tokens in the Git history based on pattern matching
- AND provide a detailed report of detected tokens with commit hashes and file locations

**B2: Token Pattern Detection**
- GIVEN common authentication token formats
- WHEN scanning Git objects
- THEN it MUST recognize patterns for:
  - GitHub Personal Access Tokens (ghp_, gho_, ghs_, ghr_)
  - LLM API keys (Anthropic, OpenAI, etc.)
  - Cloud service credentials (AWS, GCP, Azure)
  - Generic API keys and secrets
- AND allow custom pattern configuration via ace-core

**B3: Git History Rewriting**
- GIVEN identified tokens in Git history
- WHEN the user confirms history rewrite
- THEN it MUST use `git filter-repo` to permanently remove tokens from all commits
- AND preserve all other commit data and history
- AND provide clear warnings about the destructive nature of this operation
- AND require explicit user confirmation before proceeding

**B4: Token Revocation**
- GIVEN detected authentication tokens
- WHEN tokens are identified from supported services
- THEN it MUST integrate with service APIs to revoke tokens:
  - GitHub API for PAT revocation
  - LLM provider APIs via ace-llm integration
  - Other supported service APIs
- AND report revocation status for each token

**B5: Pre-Release Security Check**
- GIVEN a release workflow in ace-taskflow
- WHEN preparing to publish gems or push to public repos
- THEN it MUST automatically scan for tokens
- AND block the release if tokens are detected
- AND provide actionable guidance for remediation

### User Experience Behaviors

**B6: Clear Warnings and Confirmations**
- GIVEN any destructive operation (history rewrite)
- WHEN the operation is initiated
- THEN it MUST display clear warnings about irreversibility
- AND recommend creating repository backups
- AND require explicit typed confirmation (not just yes/no)

**B7: Actionable Reporting**
- GIVEN scan results
- WHEN tokens are detected
- THEN it MUST provide:
  - Count of detected tokens by type
  - List of affected commits with hashes
  - File paths and line numbers where tokens appear
  - Recommended next steps for remediation

**B8: AI Agent Compatibility**
- GIVEN an AI agent using ace-security
- WHEN the agent invokes security commands
- THEN it MUST provide deterministic CLI outputs
- AND support workflow-instructions for guided processes
- AND use ace-llm for interactive prompts when appropriate

## Acceptance Criteria

### Core Functionality
- [ ] **AC1**: CLI command `ace-security scan` successfully scans Git history and detects common token patterns
- [ ] **AC2**: CLI command `ace-security rewrite-history` uses git filter-repo to remove detected tokens from history
- [ ] **AC3**: CLI command `ace-security revoke` integrates with at least GitHub API to revoke tokens
- [ ] **AC4**: Token detection supports GitHub PATs, common LLM API keys, and custom pattern configuration
- [ ] **AC5**: Scan output includes commit hashes, file paths, and token types in a structured format

### Safety and User Experience
- [ ] **AC6**: History rewrite operations require explicit user confirmation with typed verification
- [ ] **AC7**: Clear warnings are displayed before any destructive operations
- [ ] **AC8**: Scan reports provide actionable next steps and remediation guidance
- [ ] **AC9**: Tool detects and warns about false positives in scan results

### Integration
- [ ] **AC10**: Integrates with ace-taskflow release workflows as pre-release check
- [ ] **AC11**: Integrates with ace-llm for token revocation API calls
- [ ] **AC12**: Configuration managed through ace-core config system
- [ ] **AC13**: Workflow instructions created in handbook/workflow-instructions/

### Architecture
- [ ] **AC14**: Follows ATOM architecture (Atoms, Molecules, Organisms, Models)
- [ ] **AC15**: Uses Thor for CLI interface
- [ ] **AC16**: Implements proper error handling and logging
- [ ] **AC17**: Performance optimized for large Git repositories

### Testing
- [ ] **AC18**: Unit tests cover token pattern matching with various formats
- [ ] **AC19**: Integration tests verify git filter-repo integration
- [ ] **AC20**: Tests verify API integration for token revocation (with mocks)
- [ ] **AC21**: Tests cover edge cases and error scenarios

## Implementation Notes

### Proposed Architecture

**New Gem: `ace-security`**

**ATOM Structure**:
- **Atoms**:
  - `token_pattern_matcher.rb` - Pure regex pattern matching for various token types
  - `git_blob_reader.rb` - Git object parsing and reading
  - `service_api_client.rb` - API request builders for token revocation

- **Molecules**:
  - `history_scanner.rb` - Combines blob reading and pattern matching
  - `git_rewriter.rb` - Orchestrates git filter-repo commands
  - `token_revoker.rb` - Manages token revocation across services

- **Organisms**:
  - `security_auditor.rb` - Orchestrates scanning and reporting
  - `history_cleaner.rb` - Manages full history rewrite process
  - `token_management_workflow.rb` - Guides through identification, removal, revocation

- **Models**:
  - `DetectedToken` - Data structure for identified tokens
  - `RevocationResult` - Result of token revocation attempts
  - `GitHistoryScanReport` - Structured scan results

**CLI Commands**:
- `ace-security scan [--patterns FILE]` - Scan Git history for tokens
- `ace-security rewrite-history [--dry-run]` - Remove tokens from history
- `ace-security revoke [--service SERVICE]` - Revoke detected tokens
- `ace-security check-release` - Pre-release security validation

### Integration Points

1. **ace-git-commit**: Add optional pre-commit hook for token pattern detection
2. **ace-taskflow**: Integrate into release workflows as mandatory step
3. **ace-llm**: Use for LLM provider API interactions and explanatory prompts
4. **ace-context**: Leverage for project root awareness and configuration

### Key Considerations

**Security**:
- Store service credentials for revocation in environment variables (never in Git)
- Consider integration with secure vault systems
- Ensure scan results don't log actual token values

**Performance**:
- Implement efficient Git object traversal
- Consider parallel processing for large repositories
- Add progress indicators for long-running operations

**Accuracy**:
- Balance false positives vs false negatives in pattern matching
- Allow whitelist/exclusion configuration
- Provide confidence scores for detected tokens

**User Guidance**:
- Create comprehensive workflow instructions (`.wf.md` files)
- Provide clear documentation in handbook
- Include examples and common scenarios

### Dependencies

- `git filter-repo` (external dependency, check availability)
- GitHub API client (Octokit or similar)
- ace-llm (for LLM provider integrations)
- ace-core (for configuration management)
- ace-taskflow (for workflow integration)

### Risks and Mitigations

**Risk**: Accidental data loss from history rewrite
**Mitigation**: Mandatory backup recommendations, dry-run mode, explicit confirmation

**Risk**: False positives disrupting legitimate code
**Mitigation**: Confidence scoring, whitelist configuration, manual review step

**Risk**: Token revocation API failures
**Mitigation**: Graceful error handling, manual revocation instructions as fallback

**Risk**: Performance issues with large repositories
**Mitigation**: Optimization, progress indicators, incremental scanning options
