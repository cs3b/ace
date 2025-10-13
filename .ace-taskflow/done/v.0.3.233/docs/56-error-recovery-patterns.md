# Error Recovery Patterns for Workflows

**Task**: v.0.3.0+task.56 - Add Error Recovery Procedures to Workflows  
**Created**: 2025-07-04  
**Purpose**: Standard error handling patterns for AI agent workflows

## Standard Error Handling Section Format

All workflows should include an "Error Handling" section with the following structure:

```markdown
## Error Handling

### Common Issues

**[Error Category]:**

[Error symptoms/description]

**Symptoms:**
- Specific error messages or behaviors

**Recovery Steps:**
1. [Immediate action]
2. [Validation step]
3. [Continue or escalate]

**Prevention:**
- [Proactive measures]
```

## Error Categories and Recovery Patterns

### 1. Git Operation Failures

#### Merge Conflicts

**Symptoms:**

- `git merge` fails with conflict markers
- `git pull` reports conflicts
- Files contain `<<<<<<<`, `=======`, `>>>>>>>` markers

**Recovery Steps:**

1. Stop current operation: `git merge --abort` or `git rebase --abort`
2. Review conflicted files: `git status`
3. For simple conflicts, resolve manually:

   ```bash
   # Edit conflicted files, remove markers, choose correct content
   git add resolved-file.ext
   git commit
   ```

4. For complex conflicts, escalate to user with clear description
5. Validate resolution: `git status` should show clean working tree

**Prevention:**

- Always `git pull` before making changes
- Check `git status` before operations
- Use `git fetch` first to preview incoming changes

#### Pre-commit Hook Failures

**Symptoms:**

- `git commit` fails with hook error messages
- Code style, lint, or test failures during commit

**Recovery Steps:**

1. Read hook error message carefully
2. Fix identified issues (lint, formatting, tests)
3. Re-stage fixed files: `git add .`
4. Retry commit: `git commit`
5. If hook is incorrectly configured, ask user for guidance

**Prevention:**

- Run `bin/lint` before committing
- Run `bin/test` before committing
- Understand project's quality gates

#### Authentication Failures

**Symptoms:**

- `git push` fails with 403/401 errors
- SSH key or token rejection

**Recovery Steps:**

1. Check authentication status: `git remote -v`
2. Verify SSH key: `ssh -T git@github.com`
3. If token expired, ask user to refresh credentials
4. For organization repos, verify push permissions
5. Document the issue for user resolution

**Prevention:**

- Check authentication before starting git operations
- Use `git fetch` to test connectivity

### 2. LLM/API Failures

#### Rate Limiting

**Symptoms:**

- API returns 429 (Too Many Requests)
- "Rate limit exceeded" messages
- Quota exhaustion errors

**Recovery Steps:**

1. Wait for rate limit reset (check headers for timing)
2. Implement exponential backoff:

   ```bash
   # Wait 30 seconds, then 60, then 120
   sleep 30 && retry_command
   ```

3. If multiple models available, switch to alternative provider
4. For urgent tasks, ask user about priority and alternatives
5. Continue with partial results if workflow allows

**Prevention:**

- Check API quotas before expensive operations
- Use lighter models for exploratory work
- Batch multiple small requests when possible

#### Authentication Failures

**Symptoms:**

- 401 Unauthorized responses
- "Invalid API key" messages
- Token expiration errors

**Recovery Steps:**

1. Verify API key environment variables are set
2. Check key format and permissions
3. Test with simple API call first
4. Ask user to verify/refresh credentials
5. Document which provider failed for troubleshooting

**Prevention:**

- Validate API keys before starting operations
- Check provider status pages for outages
- Have fallback providers configured

#### Timeout Failures

**Symptoms:**

- Operations hang or timeout
- Large content processing failures
- Model context length exceeded

**Recovery Steps:**

1. Cancel hung operation if possible
2. Reduce content size (summarize, chunk, or filter)
3. Increase timeout for legitimate large operations
4. Split large requests into smaller batches
5. Switch to higher-capacity model if available

**Prevention:**

- Estimate content size before processing
- Set appropriate timeouts based on content size
- Use streaming for large operations when available

### 3. File System Failures

#### Missing Files/Directories

**Symptoms:**

- "No such file or directory" errors
- `ls` or `find` commands return empty results
- Template or reference files not found

**Recovery Steps:**

1. Verify current working directory: `pwd`
2. Check if files exist at expected paths: `ls -la path/`
3. Search for files in alternative locations: `find . -name "filename"`
4. For missing templates, check if they need to be created
5. Ask user for correct paths if location unclear

**Prevention:**

- Use absolute paths when possible
- Verify file existence before operations: `[ -f "path" ]`
- Check directory structure matches expectations

#### Permission Errors

**Symptoms:**

- "Permission denied" on file operations
- Cannot create/modify files in directories
- Git operations fail due to file permissions

**Recovery Steps:**

1. Check current user permissions: `ls -la`
2. For temporary permission issues, ask user to fix
3. Use alternative output location if available
4. For git permission issues, check repository ownership
5. Document permission requirements for user

**Prevention:**

- Check write permissions before creating files
- Use project-appropriate output directories
- Verify git repository ownership

### 4. Test/Validation Failures

#### Test Suite Failures

**Symptoms:**

- `bin/test` returns non-zero exit code
- Unit, integration, or lint test failures
- Code quality checks fail

**Recovery Steps:**

1. Run specific failed tests to understand scope: `bin/test --verbose`
2. Read error messages carefully for root cause
3. For lint errors, run `bin/lint` and fix style issues
4. For logic errors, analyze recent changes
5. If tests are flaky, retry once before escalating

**Prevention:**

- Run tests before making changes to establish baseline
- Make small, incremental changes
- Understand test requirements and coverage expectations

#### Missing Dependencies

**Symptoms:**

- "Command not found" errors
- Import/require statements fail
- Tools not available on PATH

**Recovery Steps:**

1. Check if dependency installation is needed
2. Verify PATH and environment variables
3. For project tools, check if `bin/` scripts need setup
4. Ask user to install missing dependencies
5. Document dependency requirements

**Prevention:**

- Check tool availability before using: `which command`
- Validate environment in workflow prerequisites
- Use project-standard tool locations

### 5. Task/Workflow State Issues

#### Incomplete Prerequisites

**Symptoms:**

- Workflow steps fail due to missing context
- Previous tasks not completed
- Project state inconsistent

**Recovery Steps:**

1. Check task dependencies and their status
2. Verify prerequisite files and configurations exist
3. Run prerequisite validation commands
4. Complete missing prerequisites or ask user guidance
5. Update task status appropriately

**Prevention:**

- Validate prerequisites at workflow start
- Check dependency task completion
- Load required project context documents

#### Invalid Task State

**Symptoms:**

- Task status doesn't match actual progress
- Duplicate work being attempted
- Conflicting task assignments

**Recovery Steps:**

1. Check current task status: `bin/tn` and task file metadata
2. Review what work has actually been completed
3. Update task status to match reality
4. Identify conflicting tasks or duplicate work
5. Synchronize with user on actual project state

**Prevention:**

- Update task status immediately after changes
- Use consistent task ID generation
- Check task status before starting work

## Recovery Decision Framework

When encountering errors, follow this decision tree:

1. **Can this be fixed automatically?**
   - Yes: Apply fix and continue
   - No: Go to step 2

2. **Is this a known error with documented recovery?**
   - Yes: Follow recovery steps
   - No: Go to step 3

3. **Can progress continue with partial results?**
   - Yes: Document limitation and continue
   - No: Go to step 4

4. **Is this a user environment/configuration issue?**
   - Yes: Document issue and ask user to resolve
   - No: Go to step 5

5. **Is this a critical workflow blocker?**
   - Yes: STOP workflow, document state, ask for guidance
   - No: Continue with alternative approach

## Escalation Guidelines

**Immediate Escalation Required:**

- Data loss or corruption risks
- Security credential exposure
- Destructive operations about to execute
- User approval needed for major changes

**Document and Continue:**

- Minor tool failures with workarounds
- Non-critical feature unavailability  
- Expected limitations (rate limits, etc.)
- Recoverable environment issues

**Standard Error Documentation:**

```markdown
**Error Encountered**: [Brief description]
**Location**: [File/command where error occurred]  
**Symptoms**: [What was observed]
**Recovery Attempted**: [What was tried]
**Current State**: [Where workflow stands]
**Next Steps**: [What needs to happen to continue]
```

This framework ensures consistent, predictable error handling across all workflows while empowering AI agents to recover gracefully from common failure scenarios.
