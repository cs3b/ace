---
id: v.0.6.0+task.004
status: draft
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.001, v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Implement update-registry subcommand

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude update-registry` to sync commands.json
- **Process**: System scans all command files and rebuilds the registry
- **Output**: Updated commands.json with all current commands registered

### Expected Behavior
The system should scan both _custom and _generated directories for all .md command files, extract their metadata, and rebuild the commands.json registry file. The registry should maintain proper JSON structure, preserve any custom metadata, and ensure all commands are properly registered for Claude Code to discover them. The process should validate the JSON and report any issues.

### Interface Contract
```bash
# Update registry
handbook claude update-registry
# Output:
Scanning command directories...
Found commands:
  _custom/: 6 commands
  _generated/: 19 commands
  
Updating commands.json...
✓ Registry updated with 25 commands
✓ JSON validation passed

# Update with validation disabled
handbook claude update-registry --no-validate
# Output:
[Same scanning]
✓ Registry updated with 25 commands
⚠ JSON validation skipped

# Update with backup
handbook claude update-registry --backup
# Output:
✓ Backed up existing registry to commands.json.bak
[Rest of normal output]

# Dry run
handbook claude update-registry --dry-run
# Output:
Would update registry with:
  - commit (custom)
  - draft-tasks (custom)
  - capture-idea (generated)
  [... list all commands ...]
No changes made
```

**Error Handling:**
- Missing commands directory: Create it and report
- Corrupted JSON: Backup and regenerate
- Write permission denied: Clear error message
- Invalid command file: Skip with warning

**Edge Cases:**
- Empty directories: Create valid empty registry
- Duplicate command names: Report conflict
- Missing metadata in command: Use filename as fallback
- Very large registry: Handle gracefully

### Success Criteria
- [ ] **Directory Scanning**: All command files discovered
- [ ] **Registry Generation**: Valid JSON with all commands
- [ ] **Metadata Preservation**: Custom fields retained
- [ ] **Validation**: JSON structure validated
- [ ] **Backup Option**: Previous registry can be preserved

### Validation Questions
- [ ] **Metadata Format**: What fields should each command entry contain?
- [ ] **Sort Order**: Should commands be alphabetically sorted?
- [ ] **Custom Fields**: Which non-standard fields should be preserved?
- [ ] **Version Control**: Should registry include version information?

## Objective

Maintain an accurate, up-to-date registry of all Claude commands that enables proper command discovery and integration with Claude Code.

## Scope of Work

- **User Experience Scope**: Registry update workflow and validation
- **System Behavior Scope**: File scanning, JSON generation, and validation
- **Interface Scope**: CLI options and output format

### Deliverables

#### Behavioral Specifications
- Registry JSON schema documentation
- Command metadata specifications
- Validation rules documentation

#### Validation Artifacts
- JSON schema validation tests
- Registry integrity checks
- Backup/restore verification

## Out of Scope
- ❌ **Implementation Details**: JSON parsing libraries, file I/O methods
- ❌ **Technology Decisions**: Specific JSON schema validator
- ❌ **Performance Optimization**: Incremental updates, caching
- ❌ **Future Enhancements**: Registry versioning, command dependencies

## References

- Claude Code commands.json format
- JSON schema validation standards
- Existing registry structure