---
id: v.0.6.0+task.012
status: pending
priority: low
estimate: 1h
dependencies: [v.0.6.0+task.006, v.0.6.0+task.011]
release: v.0.6.0-unified-claude
---

# Deprecate legacy claude-integrate script

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
- [ ] **CI Detection**: How to handle automated environments?
- [ ] **Telemetry**: Should we track usage of old script?
- [ ] **Force Migration**: When to remove compatibility mode?

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
| Bash | Wrapper script | Already in use |
| tput | Terminal colors | Cross-platform |
| env vars | CI detection | Standard approach |

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