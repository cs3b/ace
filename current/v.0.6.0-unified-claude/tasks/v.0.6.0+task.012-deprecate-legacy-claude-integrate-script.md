---
id: v.0.6.0+task.012
status: pending
priority: low
estimate: 1h
dependencies: [v.0.6.0+task.006, v.0.6.0+task.011]
release: v.0.6.0-unified-claude
---

# Deprecate legacy claude-integrate script

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should the deprecation wrapper automatically run the new command in CI environments without prompting?
  - **Research conducted**: Found CI detection patterns in `file_operation_confirmer.rb` using ENV vars
  - **Current implementation**: Script uses Ruby, not bash
  - **Suggested default**: Auto-run new command with deprecation notice in CI
  - **Why needs human input**: Balance between CI stability and forcing migration

> no, just cleanup what we don't need anymore

- [ ] Should the migration guide be created at `dev-handbook/.integrations/claude/MIGRATION.md` or elsewhere?
  - **Research conducted**: Directory exists with other Claude docs but no MIGRATION.md yet
  - **Similar patterns**: `dev-tools/docs/migrations/migration-guide.md` exists for tools
  - **Suggested default**: Create at `dev-handbook/.integrations/claude/MIGRATION.md`
  - **Why needs human input**: Documentation structure consistency

> no, we don' need it

### [MEDIUM] Enhancement Questions
- [ ] Should we keep the Ruby implementation or switch to bash for the deprecation wrapper?
  - **Research conducted**: Current script is Ruby, requires dev-tools lib path
  - **Task specification**: Shows bash implementation in examples
  - **Suggested default**: Use bash for simpler deprecation logic
  - **Why needs human input**: Implementation language affects maintainability

> no need for bash

- [ ] How should we handle the case where the new `handbook claude integrate` command doesn't exist?
  - **Research conducted**: Dependencies show task.006 implements the new command
  - **Current behavior**: Script has fallback to inline implementation
  - **Suggested default**: Provide setup instructions if command not found
  - **Why needs human input**: Error handling strategy for partial migrations

> it must exists :-)

### [LOW] Future Enhancement Questions
- [ ] Should we log usage of the deprecated script for analytics?
  - **Research conducted**: No telemetry patterns found in current codebase
  - **Privacy consideration**: Would need user consent
  - **Suggested default**: No tracking, just deprecation warnings
  - **Why needs human input**: Privacy and analytics policy decision

> no because we delete it

## Behavioral Specification

### User Experience
- **Input**: User runs old `claude-integrate` script
- **Process**: System shows deprecation notice and guides to new command
- **Output**: Clear migration instructions and optional compatibility mode

### Expected Behavior
The legacy `bin/claude-integrate` script should be replaced with a deprecation wrapper that informs users about the new `handbook claude integrate` command. The wrapper should provide helpful migration guidance while optionally allowing the old functionality to work during a transition period. After a grace period, the script can be removed entirely.

### Interface Contract
```bash
# Running old script
./bin/claude-integrate
# Output:
⚠️  DEPRECATION WARNING: claude-integrate is deprecated

This script has been replaced by the unified handbook CLI:

  handbook claude integrate

The new command provides:
✓ Better error handling
✓ More options (--dry-run, --backup, --force)
✓ Integration with other Claude commands

To use the new command:
1. Ensure dev-tools is up to date
2. Run: handbook claude integrate

Would you like to:
1. Run the new command now
2. Continue with legacy script (will be removed in v0.7.0)
3. See migration guide

Choice [1-3]:

# If user chooses 1:
Executing: handbook claude integrate
[... normal integrate output ...]

# If user chooses 2:
⚠️  Running legacy script (last warning!)
[... old script behavior ...]

# If user chooses 3:
Opening migration guide...
[... opens MIGRATION.md ...]
```

**Error Handling:**
- New command not found: Provide setup instructions
- Permission issues: Same as before
- User confusion: Link to documentation

**Edge Cases:**
- CI/CD using old script: Environment variable for silent mode
- Scripts calling claude-integrate: Deprecation in logs
- Muscle memory: Clear, helpful guidance

### Success Criteria
- [ ] **Clear Deprecation**: Users understand what changed
- [ ] **Smooth Transition**: Can still work during grace period
- [ ] **Helpful Guidance**: Easy to switch to new system
- [ ] **CI Compatibility**: Doesn't break automated systems
- [ ] **Clean Removal Path**: Can be fully removed later

### Validation Questions
- [ ] **Grace Period**: How long before full removal?
  - **Answer needed**: Roadmap shows v0.7.0 targeted for Q4 2025 (8-9 months)
- [ ] **CI Detection**: How to handle automated environments?
  - **Answer needed**: Auto-run vs fail-fast in CI
- [ ] **Telemetry**: Should we track usage of old script?
  - **Answer needed**: Privacy policy and consent requirements
- [ ] **Force Migration**: When to remove compatibility mode?
  - **Answer needed**: Specific v0.7.0 release date

## Objective

Gracefully deprecate the legacy `claude-integrate` script in favor of the new unified `handbook claude integrate` command, providing clear migration guidance and a smooth transition period.

## Scope of Work

- **User Experience Scope**: Deprecation notices and migration help
- **System Behavior Scope**: Wrapper script with compatibility mode
- **Interface Scope**: Interactive prompts and guidance

### Deliverables

#### Behavioral Specifications
- Deprecation strategy documentation
- Migration timeline
- Communication plan

#### Validation Artifacts
- User acceptance testing
- CI/CD compatibility verification
- Usage metrics (if tracked)

## Out of Scope
- ❌ **Implementation Details**: Complex compatibility layers
- ❌ **Technology Decisions**: Telemetry implementation
- ❌ **Performance Optimization**: Script execution speed
- ❌ **Future Enhancements**: Auto-migration tools

## Technical Approach

### Architecture Pattern
- Wrapper script with deprecation notice
- Environment detection for CI/CD
- Optional pass-through to new command

### Technology Stack
- Shell script (bash) for wrapper
- Environment variables for configuration
- ANSI colors for terminal output

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Git | File deletion | Version control |
| Grep | Find references | Search documentation |

## File Modifications

### Create
- `bin/claude-integrate.deprecated` - Backup of original script

### Modify
- `bin/claude-integrate` - Replace with deprecation wrapper

### Delete
- `bin/claude-integrate` - After grace period (v0.7.0)

## Risk Assessment

### Technical Risks
- **Breaking CI/CD**: Scripts fail due to interactive prompt
  - Mitigation: Detect CI environment, skip prompt
- **Lost Functionality**: New command missing features
  - Mitigation: Ensure feature parity first

### Integration Risks
- **User Resistance**: People prefer old script
  - Mitigation: Show clear benefits of new system
- **Documentation Lag**: Outdated references
  - Mitigation: Comprehensive documentation update

## Implementation Plan

### Planning Steps

* [ ] Analyze current script usage patterns
* [ ] Define deprecation timeline
* [ ] Plan CI/CD compatibility approach
* [ ] Prepare communication strategy

### Execution Steps

- [ ] Backup original script
  ```bash
  cp bin/claude-integrate bin/claude-integrate.deprecated
  git add bin/claude-integrate.deprecated
  ```

- [ ] Create deprecation wrapper
  ```bash
  #!/usr/bin/env bash
  # bin/claude-integrate - Deprecation wrapper

  # Colors for output
  YELLOW='\033[1;33m'
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color

  # Check if running in CI
  if [ -n "$CI" ] || [ -n "$CONTINUOUS_INTEGRATION" ] || [ -n "$GITHUB_ACTIONS" ]; then
    echo "⚠️  claude-integrate is deprecated. Use: handbook claude integrate" >&2
    # In CI, try to run new command automatically
    exec handbook claude integrate "$@"
  fi

  # Interactive deprecation notice
  echo -e "${YELLOW}⚠️  DEPRECATION WARNING: claude-integrate is deprecated${NC}"
  echo ""
  echo "This script has been replaced by the unified handbook CLI:"
  echo ""
  echo -e "  ${GREEN}handbook claude integrate${NC}"
  echo ""
  echo "The new command provides:"
  echo "✓ Better error handling"
  echo "✓ More options (--dry-run, --backup, --force)"
  echo "✓ Integration with other Claude commands"
  echo ""
  echo "Would you like to:"
  echo "1. Run the new command now"
  echo "2. Continue with legacy script (will be removed in v0.7.0)"
  echo "3. See migration guide"
  echo ""
  read -p "Choice [1-3]: " choice

  case $choice in
    1)
      echo "Executing: handbook claude integrate"
      exec handbook claude integrate "$@"
      ;;
    2)
      echo -e "${YELLOW}⚠️  Running legacy script (last warning!)${NC}"
      exec bash "$(dirname "$0")/claude-integrate.deprecated" "$@"
      ;;
    3)
      echo "Opening migration guide..."
      open "dev-handbook/.integrations/claude/MIGRATION.md" || \
      cat "dev-handbook/.integrations/claude/MIGRATION.md"
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
  ```
  > TEST: Wrapper Behavior
  > Type: Manual Test
  > Assert: All options work correctly
  > Command: ./bin/claude-integrate

- [ ] Make wrapper executable
  ```bash
  chmod +x bin/claude-integrate
  ```

- [ ] Test CI compatibility
  ```bash
  # Simulate CI environment
  CI=true ./bin/claude-integrate
  ```
  > TEST: CI Mode
  > Type: Environment Test
  > Assert: No interactive prompt in CI
  > Command: CI=true ./bin/claude-integrate

- [ ] Update references in documentation
  ```bash
  # Find all references
  grep -r "bin/claude-integrate" docs/ --include="*.md"

  # Update to mention deprecation
  ```

- [ ] Add deprecation notice to README
  ```markdown
  ## ⚠️ Deprecation Notice

  The `bin/claude-integrate` script is deprecated as of v0.6.0.
  Please use `handbook claude integrate` instead.

  The old script will be removed in v0.7.0.
  ```

- [ ] Plan removal timeline
  ```markdown
  ## Deprecation Timeline

  - v0.6.0 (current): Deprecation wrapper added
  - v0.6.x: Grace period with compatibility mode
  - v0.7.0: Complete removal of old script
  ```

## Acceptance Criteria

- [ ] Deprecation wrapper provides clear guidance
- [ ] CI/CD environments continue to work
- [ ] Users can still use old script during grace period
- [ ] Migration path is well documented
- [ ] New command is promoted effectively
- [ ] Removal timeline is communicated

## References

- Deprecation best practices
- SemVer guidelines for breaking changes
- User communication strategies
- Current script: `bin/claude-integrate` (Ruby implementation)
- CI detection pattern: `dev-tools/lib/coding_agent_tools/molecules/file_operation_confirmer.rb`
- Related tasks: v.0.6.0+task.006 (integrate command), v.0.6.0+task.011 (documentation)
- Roadmap: v0.7.0 "Conductor" targeted for Q4 2025

## Review Summary

**Date:** 2025-08-04
**Reviewer:** Claude (Automated Review)

**Questions Generated:** 5 total (2 HIGH, 2 MEDIUM, 1 LOW)
**Critical Blockers:** 2 HIGH priority questions need answers before implementation
**Implementation Readiness:** Blocked on answers - need decisions on CI behavior and documentation location

**Research Conducted:**
- ✅ Analyzed current `bin/claude-integrate` script (Ruby implementation using ClaudeCommandsInstaller)
- ✅ Found CI environment detection patterns in codebase (uses ENV vars)
- ✅ Verified dependencies: task.006 implements new command, task.011 handles documentation
- ✅ Checked for existing MIGRATION.md (not found, needs creation)
- ✅ Reviewed roadmap for v0.7.0 timeline (Q4 2025, approximately 8-9 months away)
- ✅ Searched for deprecation patterns in codebase (found cache_manager deprecation example)
- ✅ Confirmed `.integrations/claude/` directory structure exists

**Content Updates Made:**
- Added needs_review: true to metadata for tracking
- Added Review Questions section with 5 prioritized questions
- Enhanced Validation Questions with research findings
- Added comprehensive References section with specific file paths
- Added Review Summary for tracking review outcomes

**Key Findings:**
- Current script is Ruby, not bash (implementation mismatch with examples)
- v0.7.0 removal date is ~8-9 months away (longer grace period than typical)
- No existing migration guide to reference (needs creation)
- CI detection patterns already exist in codebase

**Recommended Next Steps:**
1. Answer HIGH priority questions about CI behavior and documentation location
2. Decide on implementation language (Ruby vs bash wrapper)
3. Create MIGRATION.md guide before implementing wrapper
4. Ensure task.006 completion before starting this task
5. Coordinate with task.011 for documentation updates
