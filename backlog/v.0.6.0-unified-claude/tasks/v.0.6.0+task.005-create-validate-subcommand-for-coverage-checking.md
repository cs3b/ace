---
id: v.0.6.0+task.005
status: draft
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Create validate subcommand for coverage checking

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude validate` to check command coverage
- **Process**: System analyzes workflows vs commands and reports gaps or issues
- **Output**: Comprehensive validation report with actionable findings

### Expected Behavior
The system should perform a comprehensive validation of Claude command coverage by comparing workflow instruction files against existing commands. It should identify missing commands, outdated commands, duplicates, and any other consistency issues. The validation should provide clear, actionable feedback to help developers maintain complete and accurate Claude integration.

### Interface Contract
```bash
# Full validation
handbook claude validate
# Output:
Validating Claude command coverage...

Workflows found: 25
Commands found: 23

✗ Missing commands:
  - capture-idea.wf.md (no command found)
  - rebase-against.wf.md (no command found)

⚠ Outdated commands (workflow modified after command):
  - draft-task.md (workflow updated 2 days ago)

⚠ Duplicate commands:
  - plan-task appears in both _custom/ and _generated/

✓ Valid commands: 20

Summary: 2 missing, 1 outdated, 1 duplicate

# Validate with specific checks
handbook claude validate --check missing
# Output:
Checking for missing commands...
✗ Missing commands:
  - capture-idea.wf.md
  - rebase-against.wf.md

# Validate with exit code
handbook claude validate --strict
# Output:
[Same validation output]
# Exit code: 1 (if any issues found)

# Validate specific workflow
handbook claude validate --workflow draft-task
# Output:
Validating draft-task workflow...
✓ Command exists: _custom/draft-task.md
✓ Command is up to date
✓ No duplicates found
```

**Error Handling:**
- Missing directories: Report what's missing
- Permission issues: Clear error about access
- Malformed files: Report and continue validation

**Edge Cases:**
- Workflows without commands needed: Whitelist support
- Commands without workflows: Report as orphaned
- Symbolic links: Follow and validate
- Case sensitivity: Handle gracefully

### Success Criteria
- [ ] **Coverage Analysis**: All workflows checked for commands
- [ ] **Duplicate Detection**: Same-named commands identified
- [ ] **Freshness Check**: Outdated commands detected
- [ ] **Clear Reporting**: Issues presented actionably
- [ ] **Exit Codes**: Proper codes for CI integration

### Validation Questions
- [ ] **Whitelist Support**: How to mark workflows that don't need commands?
- [ ] **Staleness Definition**: How old before a command is "outdated"?
- [ ] **Validation Levels**: Should there be warning vs error severity?
- [ ] **Custom Rules**: Should validation be configurable?

## Objective

Provide comprehensive validation of Claude command coverage to ensure all workflows have appropriate commands and maintain integration quality.

## Scope of Work

- **User Experience Scope**: Validation workflow and reporting
- **System Behavior Scope**: Coverage analysis and issue detection
- **Interface Scope**: CLI options and report formats

### Deliverables

#### Behavioral Specifications
- Validation rule documentation
- Report format specifications
- Exit code conventions

#### Validation Artifacts
- Coverage calculation tests
- Issue detection accuracy tests
- Report format validation

## Out of Scope
- ❌ **Implementation Details**: File comparison algorithms
- ❌ **Technology Decisions**: Diff libraries or tools
- ❌ **Performance Optimization**: Caching validation results
- ❌ **Future Enhancements**: Auto-fixing issues, IDE integration

## References

- Workflow instruction conventions
- Command file standards
- CI/CD best practices for validation tools