---
id: v.0.6.0+task.003
status: draft
priority: high
estimate: 6h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Create generate-commands subcommand

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude generate-commands` with optional flags
- **Process**: System scans workflows, identifies missing commands, generates them using templates
- **Output**: Report of generated commands and their locations

### Expected Behavior
The system should scan all workflow instruction files (.wf.md) in dev-handbook and identify which ones lack corresponding Claude commands. For missing commands, it should generate appropriate command files using predefined templates. The generation should be smart enough to skip custom commands and only generate for truly missing workflows. Users should see clear progress and results.

### Interface Contract
```bash
# Generate all missing commands
handbook claude generate-commands
# Output:
Scanning workflow instructions...
Found 25 workflow files
Checking existing commands...

Missing commands for:
  - capture-idea.wf.md
  - fix-linting-issue-from.wf.md
  - rebase-against.wf.md

Generating commands...
✓ Created: _generated/capture-idea.md
✓ Created: _generated/fix-linting-issue-from.md
✓ Created: _generated/rebase-against.md

Summary: 3 commands generated

# Generate with dry-run
handbook claude generate-commands --dry-run
# Output:
[Same scanning output]
Would generate:
  - _generated/capture-idea.md
  - _generated/fix-linting-issue-from.md
  - _generated/rebase-against.md

# Force regeneration
handbook claude generate-commands --force
# Output:
[Regenerates even existing _generated commands]

# Generate specific workflow
handbook claude generate-commands --workflow capture-idea
# Output:
✓ Created: _generated/capture-idea.md
```

**Error Handling:**
- Missing workflow directory: Clear error about location
- Template not found: Error with template path
- Write permission denied: Error with remediation steps
- Invalid workflow format: Skip with warning

**Edge Cases:**
- Workflow with custom command exists: Skip generation
- Generated command already exists: Skip unless --force
- Malformed workflow file: Report and continue
- Template variables missing: Use safe defaults

### Success Criteria
- [ ] **Workflow Scanning**: All .wf.md files are discovered and analyzed
- [ ] **Gap Detection**: Missing commands are accurately identified
- [ ] **Template Application**: Commands generated using correct template
- [ ] **Progress Reporting**: Clear output showing what's being done
- [ ] **Idempotent Operation**: Running twice produces same result

### Validation Questions
- [ ] **Custom Detection**: How to identify if a command is custom vs should be generated?
- [ ] **Template Variables**: What variables should templates support?
- [ ] **Naming Conflicts**: How to handle workflows with similar names?
- [ ] **Generation Rules**: Should some workflows never have commands?

## Objective

Enable automatic generation of Claude commands for workflow instructions that lack them, maintaining consistency while respecting custom implementations.

## Scope of Work

- **User Experience Scope**: Command generation workflow and progress reporting
- **System Behavior Scope**: File scanning, template processing, and file generation
- **Interface Scope**: CLI flags and output format

### Deliverables

#### Behavioral Specifications
- Template format specification
- Generation rules documentation
- Progress reporting format

#### Validation Artifacts
- Generated command validation tests
- Template variable verification
- Idempotency test scenarios

## Out of Scope
- ❌ **Implementation Details**: File I/O methods, template engine choice
- ❌ **Technology Decisions**: Ruby libraries for templating
- ❌ **Performance Optimization**: Parallel generation strategies
- ❌ **Future Enhancements**: AI-powered command generation

## References

- Current workflow instruction format
- Existing Claude command patterns
- Template processing best practices