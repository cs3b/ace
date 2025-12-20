---
id: v.0.9.0+task.139
status: in-progress
priority: medium
estimate: 16-24h
dependencies: []
worktree:
  branch: 139-secure-git-history-remove-and-revoke-authentication-tokens
  path: "../ace-task.139"
  created_at: '2025-12-20 20:19:37'
  updated_at: '2025-12-20 20:19:37'
---

# Secure Git History: Remove and Revoke Authentication Tokens

## 0. Directory Audit

_Command run:_

```bash
ace-nav guide://
```

_Result excerpt:_

```
guide://security/ruby        -> dev-handbook/guides/security/ruby.md
guide://release-publish/ruby -> dev-handbook/guides/release-publish/ruby.md
guide://atom-pattern.g       -> dev-handbook/guides/atom-pattern.g.md
```

## Objective

Implement a comprehensive security solution to identify, remove, and revoke authentication tokens from Git history in the ACE mono-repo. This is a critical security fix to prevent exposure of sensitive credentials (GitHub PATs, LLM API keys, cloud service credentials) that may have been inadvertently committed to Git history, especially before publishing gems or pushing to public repositories.

## Technical Approach

### Architecture Pattern

- **Pattern**: New standalone gem `ace-security` following ATOM architecture
- **Rationale**: Security functionality is cross-cutting and deserves dedicated gem with clear separation of concerns. Keeps security-related code isolated and auditable.
- **Integration**: Hooks into ace-taskflow release workflow and optionally ace-git-commit pre-commit

### Technology Stack

**Core Dependencies:**
- `ace-support-core` (~> 0.10) - Configuration management and project root detection
- `faraday` (~> 2.0) - HTTP client for token revocation APIs
- `thor` - CLI interface (consistent with other ACE gems)

**External Tools:**
- `git-filter-repo` (Python, installed via Homebrew) - History rewriting
- GitHub Credential Revocation API - Token invalidation (unauthenticated, rate-limited)

**Integration Dependencies:**
- `ace-llm` - For LLM provider API key revocation (Anthropic, OpenAI)
- `ace-taskflow` - Release workflow integration

### Implementation Strategy

**Phase 1: Core Scanning** (8h)
- Token pattern matcher atom (regex-based detection)
- Git history scanner molecule (traverse commits, blobs)
- Scan report model and CLI command

**Phase 2: History Rewriting** (6h)
- Git-filter-repo wrapper molecule
- Interactive confirmation system
- Dry-run and backup capabilities

**Phase 3: Token Revocation** (4h)
- GitHub API integration (Credential Revocation API)
- LLM provider integration via ace-llm
- Revocation result tracking

**Phase 4: Integration** (4h)
- ace-taskflow release workflow hook
- Pre-commit integration option
- Workflow instructions and documentation

## Tool Selection

| Criteria | git-filter-repo | BFG Repo-Cleaner | git filter-branch | Selected |
|----------|-----------------|------------------|-------------------|----------|
| Performance | Excellent (10-50x faster) | Good | Poor | git-filter-repo |
| Maintained | Active (2024+) | Archived | Deprecated | git-filter-repo |
| Features | Comprehensive | Limited | Complete | git-filter-repo |
| Integration | Python CLI | Java JAR | Built-in | git-filter-repo |

**Selection Rationale:** git-filter-repo is the official replacement for git-filter-branch, recommended by Git documentation. It offers superior performance, active maintenance, and comprehensive features for content-based filtering.

| Criteria | Faraday | Net::HTTP | HTTParty | Selected |
|----------|---------|-----------|----------|----------|
| Consistency | Used by ace-llm | Ruby stdlib | Third-party | Faraday |
| Retry | Built-in middleware | Manual | Limited | Faraday |
| Testing | WebMock compatible | WebMock compatible | WebMock compatible | Faraday |

**Selection Rationale:** Faraday is already used by ace-llm and follows ADR-010 for HTTP client standardization.

### Dependencies

- [x] `ace-support-core` ~> 0.10 (existing)
- [ ] `faraday` ~> 2.0 (add to gem)
- [ ] `git-filter-repo` (external, document installation requirement)
- [ ] `ace-llm` ~> 0.15 (optional, for LLM token revocation)

## Scope of Work

### Deliverables

#### Create

**New Gem: ace-security**

```
ace-security/
├── .ace.example/security/config.yml     # Default patterns config
├── exe/ace-security                      # CLI entrypoint
├── lib/
│   └── ace/security/
│       ├── atoms/
│       │   ├── token_pattern_matcher.rb  # Regex pattern matching
│       │   ├── git_blob_reader.rb        # Git object parsing
│       │   └── service_api_client.rb     # API request builders
│       ├── molecules/
│       │   ├── history_scanner.rb        # Scan git history
│       │   ├── git_rewriter.rb           # git-filter-repo wrapper
│       │   └── token_revoker.rb          # Revocation orchestration
│       ├── organisms/
│       │   ├── security_auditor.rb       # Scan and report
│       │   ├── history_cleaner.rb        # Rewrite workflow
│       │   └── release_gate.rb           # Pre-release check
│       ├── models/
│       │   ├── detected_token.rb         # Token data structure
│       │   ├── revocation_result.rb      # Revocation outcome
│       │   └── scan_report.rb            # Scan results
│       ├── commands/
│       │   ├── scan_command.rb           # ace-security scan
│       │   ├── rewrite_command.rb        # ace-security rewrite-history
│       │   ├── revoke_command.rb         # ace-security revoke
│       │   └── check_release_command.rb  # ace-security check-release
│       ├── cli.rb                        # Thor CLI
│       └── version.rb
├── handbook/
│   ├── agents/
│   │   └── security-audit.ag.md          # Security audit agent
│   └── workflow-instructions/
│       └── token-remediation.wf.md       # Complete remediation workflow
├── test/
│   ├── atoms/
│   │   ├── token_pattern_matcher_test.rb
│   │   └── git_blob_reader_test.rb
│   ├── molecules/
│   │   ├── history_scanner_test.rb
│   │   └── token_revoker_test.rb
│   ├── organisms/
│   │   └── security_auditor_test.rb
│   ├── commands/
│   │   └── scan_command_test.rb
│   ├── fixtures/
│   │   └── sample_tokens.yml             # Test token patterns
│   └── test_helper.rb
├── bin/ace-security                       # Mono-repo binstub
├── ace-security.gemspec
├── CHANGELOG.md
├── LICENSE
├── Rakefile
└── README.md
```

#### Modify

- `ace-taskflow/handbook/workflow-instructions/publish-release.wf.md`
  - Add security check step before pre-publish validation
  - Reference ace-security check-release command

- `Gemfile` (root)
  - Add ace-security gem reference

#### Delete

None

## Implementation Plan

### Planning Steps

* [x] Analyze existing gem structure patterns (ace-git-commit, ace-llm)
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Identified ATOM structure, Thor CLI pattern, gemspec format
  > Result: Reviewed ace-git-commit and ace-llm gems for reference patterns

* [x] Research git-filter-repo capabilities and installation requirements
  > TEST: Tool Research Complete
  > Type: Pre-condition Check
  > Assert: git-filter-repo installation method documented, API understood
  > Result: Available via Homebrew, Python-based, comprehensive regex filtering

* [x] Research GitHub Credential Revocation API
  > TEST: API Research Complete
  > Type: Pre-condition Check
  > Assert: API endpoints, authentication, rate limits documented
  > Result: Unauthenticated API, 60 req/hr, bulk revocation supported

* [x] Design token pattern detection regex for common token types
  > TEST: Pattern Design Complete
  > Type: Pre-condition Check
  > Assert: Patterns for GitHub PATs, LLM keys, AWS credentials defined
  > Result: Patterns defined in usage.md

### Execution Steps

#### Phase 1: Gem Scaffold and Core Scanning (8h)

- [ ] Create ace-security gem directory structure
  > TEST: Directory Structure Created
  > Type: Action Validation
  > Assert: All required directories and files exist
  > Command: ls -la ace-security/lib/ace/security/{atoms,molecules,organisms,models,commands}

- [ ] Create gemspec with dependencies
  > TEST: Gemspec Valid
  > Type: Action Validation
  > Assert: Gemspec loads without errors
  > Command: cd ace-security && gem build ace-security.gemspec --strict

- [ ] Implement TokenPatternMatcher atom
  - Pure regex matching for token patterns
  - Support for GitHub PAT formats (ghp_, gho_, ghs_, ghr_)
  - Support for LLM API keys (sk-ant-, sk-)
  - Support for AWS credentials (AKIA, ASIA)
  - Confidence scoring (high/medium/low)
  > TEST: Pattern Matching Works
  > Type: Unit Test
  > Assert: All token formats correctly detected with appropriate confidence
  > Command: ace-test test/atoms/token_pattern_matcher_test.rb

- [ ] Implement GitBlobReader atom
  - Parse git objects
  - Extract content from blobs
  - Handle binary vs text content
  > TEST: Blob Reading Works
  > Type: Unit Test
  > Assert: Can read and parse git blob objects
  > Command: ace-test test/atoms/git_blob_reader_test.rb

- [ ] Implement DetectedToken model
  - Token type, pattern matched, confidence
  - Commit hash, file path, line number
  - Masked token value for display
  > TEST: Model Structure Valid
  > Type: Unit Test
  > Assert: Model correctly stores and masks token data
  > Command: ace-test test/models/detected_token_test.rb

- [ ] Implement ScanReport model
  - Collection of detected tokens
  - Summary statistics
  - Serialization (JSON, YAML, table)
  > TEST: Report Model Works
  > Type: Unit Test
  > Assert: Report can be generated and serialized
  > Command: ace-test test/models/scan_report_test.rb

- [ ] Implement HistoryScanner molecule
  - Walk git log for all commits
  - Scan each commit's tree for blobs
  - Apply pattern matching to blob content
  - Progress reporting for large repos
  > TEST: History Scanning Works
  > Type: Integration Test
  > Assert: Can scan a test repository and detect planted tokens
  > Command: ace-test test/molecules/history_scanner_test.rb

- [ ] Implement ScanCommand CLI
  - Options: --patterns, --since, --branch, --format, --confidence
  - Exit codes: 0 (clean), 1 (tokens found), 2 (error)
  > TEST: Scan Command Works
  > Type: Command Test
  > Assert: ace-security scan returns expected output
  > Command: ace-test test/commands/scan_command_test.rb

#### Phase 2: History Rewriting (6h)

- [ ] Implement GitRewriter molecule
  - Wrapper for git-filter-repo command
  - Check for tool availability
  - Build filter expressions from detected tokens
  - Execute with proper arguments
  - Capture and report output
  > TEST: Rewriter Works
  > Type: Integration Test
  > Assert: Can invoke git-filter-repo and capture results
  > Command: ace-test test/molecules/git_rewriter_test.rb

- [ ] Implement HistoryCleaner organism
  - Orchestrate scan + rewrite workflow
  - Interactive confirmation with typed input
  - Backup recommendation
  - Dry-run mode
  > TEST: History Cleaner Works
  > Type: Organism Test
  > Assert: Workflow correctly sequences scan, confirm, rewrite
  > Command: ace-test test/organisms/history_cleaner_test.rb

- [ ] Implement RewriteCommand CLI
  - Options: --dry-run, --backup, --force, --scan-file
  - Safety checks (clean working directory)
  - Clear warnings and confirmation
  > TEST: Rewrite Command Works
  > Type: Command Test
  > Assert: ace-security rewrite-history handles all options
  > Command: ace-test test/commands/rewrite_command_test.rb

#### Phase 3: Token Revocation (4h)

- [ ] Implement ServiceApiClient atom
  - Build HTTP requests for GitHub Credential Revocation API
  - Handle response parsing
  - Rate limit awareness
  > TEST: API Client Works
  > Type: Unit Test
  > Assert: Can build and parse API requests/responses
  > Command: ace-test test/atoms/service_api_client_test.rb

- [ ] Implement RevocationResult model
  - Token identifier
  - Service name
  - Status (revoked, failed, unsupported)
  - Error message if failed
  > TEST: Result Model Works
  > Type: Unit Test
  > Assert: Model correctly captures revocation outcomes
  > Command: ace-test test/models/revocation_result_test.rb

- [ ] Implement TokenRevoker molecule
  - Route tokens to appropriate service handlers
  - Execute revocation API calls
  - Collect results
  - Handle partial failures gracefully
  > TEST: Token Revoker Works
  > Type: Integration Test
  > Assert: Can revoke tokens via mocked API
  > Command: ace-test test/molecules/token_revoker_test.rb

- [ ] Implement RevokeCommand CLI
  - Options: --service, --token, --scan-file
  - Report revocation status for each token
  > TEST: Revoke Command Works
  > Type: Command Test
  > Assert: ace-security revoke handles all options
  > Command: ace-test test/commands/revoke_command_test.rb

#### Phase 4: Integration (4h)

- [ ] Implement ReleaseGate organism
  - Run security scan
  - Report findings
  - Return appropriate exit code for CI
  > TEST: Release Gate Works
  > Type: Organism Test
  > Assert: Blocks on findings, passes on clean
  > Command: ace-test test/organisms/release_gate_test.rb

- [ ] Implement CheckReleaseCommand CLI
  - Options: --strict, --format
  - CI-friendly output
  > TEST: Check Release Command Works
  > Type: Command Test
  > Assert: ace-security check-release returns correct exit codes
  > Command: ace-test test/commands/check_release_command_test.rb

- [ ] Create workflow instruction: token-remediation.wf.md
  - Complete remediation workflow
  - Step-by-step guide for scan, revoke, rewrite

- [ ] Create agent: security-audit.ag.md
  - Single-purpose security audit agent

- [ ] Update publish-release.wf.md to include security check step

- [ ] Create mono-repo binstub at bin/ace-security

- [ ] Add ace-security to root Gemfile

- [ ] Create default configuration at .ace.example/security/config.yml

- [ ] Write comprehensive README.md

- [ ] Create CHANGELOG.md with initial version

## Test Case Planning

### Happy Path Scenarios

| Scenario | Input | Expected Output |
|----------|-------|-----------------|
| Clean repository scan | Repo with no tokens | Exit 0, "No tokens detected" |
| Token detection | Repo with planted ghp_ token | Exit 1, Token in report with commit/file |
| History rewrite dry-run | Repo with token, --dry-run | Shows what would be removed, no changes |
| Successful revocation | Valid GitHub PAT | Token revoked, confirmation message |
| Pre-release pass | Clean repo | Exit 0, "Security check passed" |

### Edge Case Scenarios

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| Binary file handling | Repo with binary files | Skip binary files, no false positives |
| Large repository | 10k+ commits | Progress indicator, reasonable performance |
| Shallow clone | --depth 1 clone | Appropriate warning, scan available history |
| Merge commits | Complex merge history | Handle correctly, no duplicate reports |
| Empty repository | New repo with no commits | Graceful handling, exit 0 |

### Error Condition Scenarios

| Scenario | Error Condition | Expected Behavior |
|----------|-----------------|-------------------|
| git-filter-repo missing | Tool not installed | Clear error message with installation instructions |
| Dirty working directory | Uncommitted changes | Block rewrite, suggest commit or stash |
| API rate limit | 60 requests exceeded | Warning, suggest GITHUB_TOKEN |
| Invalid pattern file | Malformed YAML | Clear error message with line number |
| Network failure | API unreachable | Graceful failure, offline mode for scan |

### Security Test Scenarios

| Scenario | Test | Expected Behavior |
|----------|------|-------------------|
| Token masking in output | Any token detection | Token value masked (ghp_***...) |
| No token logging | Scan operation | Tokens never written to logs |
| Confirmation required | History rewrite | Must type "REWRITE HISTORY" exactly |

## Risk Assessment

### Technical Risks

- **Risk:** git-filter-repo not installed on user systems
  - **Probability:** Medium
  - **Impact:** High (core feature blocked)
  - **Mitigation:** Clear error message with installation instructions, check at command start
  - **Rollback:** N/A - document as prerequisite

- **Risk:** History rewrite corrupts repository
  - **Probability:** Low (git-filter-repo is mature)
  - **Impact:** High (data loss)
  - **Mitigation:** Mandatory backup recommendation, --dry-run mode, explicit confirmation
  - **Rollback:** Restore from backup clone

- **Risk:** False positives in pattern matching
  - **Probability:** Medium
  - **Impact:** Medium (user confusion, wasted effort)
  - **Mitigation:** Confidence scoring, whitelist configuration, manual review step
  - **Rollback:** N/A - informational only

### Integration Risks

- **Risk:** Breaks existing release workflow
  - **Probability:** Low
  - **Impact:** Medium (release delays)
  - **Mitigation:** Make security check optional initially, document integration
  - **Monitoring:** Check workflow execution in CI

- **Risk:** API rate limiting affects revocation
  - **Probability:** Medium (60 req/hr limit)
  - **Impact:** Low (can retry later)
  - **Mitigation:** Document rate limits, suggest authenticated requests
  - **Rollback:** Manual revocation via web UI

### Performance Risks

- **Risk:** Slow scanning on large repositories
  - **Probability:** Medium
  - **Impact:** Medium (user experience)
  - **Mitigation:** Progress indicators, --since option for incremental scanning
  - **Monitoring:** Track scan times, add profiling
  - **Thresholds:** Target < 5 minutes for 10k commits

## Acceptance Criteria

### Core Functionality

- [ ] **AC1**: CLI command `ace-security scan` successfully scans Git history and detects common token patterns
- [ ] **AC2**: CLI command `ace-security rewrite-history` uses git-filter-repo to remove detected tokens from history
- [ ] **AC3**: CLI command `ace-security revoke` integrates with GitHub API to revoke tokens
- [ ] **AC4**: Token detection supports GitHub PATs, common LLM API keys, and custom pattern configuration
- [ ] **AC5**: Scan output includes commit hashes, file paths, and token types in a structured format

### Safety and User Experience

- [ ] **AC6**: History rewrite operations require explicit user confirmation with typed verification ("REWRITE HISTORY")
- [ ] **AC7**: Clear warnings are displayed before any destructive operations
- [ ] **AC8**: Scan reports provide actionable next steps and remediation guidance
- [ ] **AC9**: Tool detects and warns about false positives in scan results (confidence scoring)

### Integration

- [ ] **AC10**: Integrates with ace-taskflow release workflows as pre-release check
- [ ] **AC11**: Integrates with ace-llm for LLM provider token revocation
- [ ] **AC12**: Configuration managed through ace-core config system (.ace/security/config.yml)
- [ ] **AC13**: Workflow instructions created in handbook/workflow-instructions/

### Architecture

- [ ] **AC14**: Follows ATOM architecture (Atoms, Molecules, Organisms, Models)
- [ ] **AC15**: Uses Thor for CLI interface
- [ ] **AC16**: Implements proper error handling and logging
- [ ] **AC17**: Performance optimized for large Git repositories (< 5 min for 10k commits)

### Testing

- [ ] **AC18**: Unit tests cover token pattern matching with various formats
- [ ] **AC19**: Integration tests verify git-filter-repo integration
- [ ] **AC20**: Tests verify API integration for token revocation (with mocks)
- [ ] **AC21**: Tests cover edge cases and error scenarios

## Out of Scope

- Multi-repository scanning (focus on single repo)
- Automatic pre-commit hook installation (document manual setup)
- Real-time monitoring or continuous scanning
- Token generation or rotation (only detection and revocation)
- Support for git hosting providers other than GitHub for revocation

## References

- [GitHub Credential Revocation API](https://docs.github.com/en/rest/credentials/revoke)
- [git-filter-repo Documentation](https://github.com/newren/git-filter-repo)
- [ADR-011: ATOM Architecture](docs/decisions/ADR-011-ATOM-Architecture-House-Rules.t.md)
- [ADR-018: Thor CLI Commands Pattern](docs/decisions/ADR-018-thor-cli-commands-pattern.md)
- [ace-gems.g.md](docs/ace-gems.g.md) - Gem development guide
- Task UX Documentation: [ux/usage.md](./ux/usage.md)