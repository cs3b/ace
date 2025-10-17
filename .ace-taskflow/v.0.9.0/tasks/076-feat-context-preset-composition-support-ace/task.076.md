---
id: v.0.9.0+task.076
status: draft
priority: medium
estimate: 6-8h
dependencies: []
---

# Add preset composition support to ace-context configuration

## Behavioral Specification

### User Experience
- **Input**: Users provide preset composition via YAML configuration `presets:` array or CLI flags `-p`/`--presets`
- **Process**: System loads and merges presets in order, deduplicating arrays and overriding scalars
- **Output**: Unified context with all preset configurations merged intelligently

### Expected Behavior

Users can compose multiple presets together to build complex context configurations without duplication. The system allows preset composition both in configuration files and via command-line interface.

When a preset includes other presets, those are loaded first and merged in order. The current preset's explicit configurations (files, commands) are then applied on top, allowing for specialization and extension of base presets.

Arrays (files, commands) are concatenated and made unique to prevent processing the same file or running the same command multiple times. Scalar values (output, max_size, timeout) use a "last wins" strategy where later presets override earlier ones.

### Interface Contract

```bash
# CLI Interface - Multiple preset flags
ace-context -p base -p project-specific
ace-context --preset base --preset specialized

# CLI Interface - Comma-separated list
ace-context --presets base,project-specific,team-config

# Expected outputs
# - Loads base preset first
# - Merges project-specific on top
# - Deduplicates any repeated files/commands
# - Returns unified context

# Error conditions
ace-context -p nonexistent
# Error: Preset 'nonexistent' not found

# YAML Configuration Interface
context:
  presets:
    - base           # Load base preset first
    - project-base   # Then merge project-base
  files:
    - additional.md  # Add extra files on top
  commands:
    - git log -1     # Add extra commands
```

**Error Handling:**
- [Nonexistent preset]: Display error "Preset 'name' not found" and continue with other presets
- [Circular dependency]: Detect and prevent infinite loops in preset references
- [Invalid merge]: Report specific merge conflicts that cannot be resolved

**Edge Cases:**
- [Empty presets array]: Process only explicit files/commands in current config
- [Duplicate presets]: Process each preset only once even if listed multiple times
- [Deep nesting]: Support presets that reference other presets (transitive composition)

### Success Criteria

- [ ] **Preset Composition in Config**: Users can define `presets:` array in YAML that loads and merges multiple presets
- [ ] **CLI Multi-Preset Support**: Users can pass multiple presets via `-p` flags or `--presets` comma-separated list
- [ ] **Intelligent Merging**: Arrays are concatenated and deduplicated, scalars follow "last wins" strategy
- [ ] **Order Preservation**: Presets are loaded and merged in the order specified
- [ ] **Error Resilience**: System continues processing valid presets even if one fails to load

### Validation Questions

- [ ] **Merge Strategy**: Should arrays maintain original order after deduplication, or sort them?
- [ ] **Preset Paths**: Should presets support relative paths or only named presets from .ace/context/presets/?
- [ ] **Recursion Depth**: Should there be a maximum depth for preset composition to prevent stack overflow?
- [ ] **Override Behavior**: Should there be a way to explicitly exclude items from inherited presets?

## Objective

Enable modular and composable context configurations by allowing presets to build upon each other, reducing duplication and improving maintainability of context definitions.

## Scope of Work

- **User Experience Scope**: Configuration file preset composition, CLI multi-preset support, clear error messages
- **System Behavior Scope**: Preset loading, intelligent merging, deduplication, order preservation
- **Interface Scope**: YAML `presets:` array, CLI `-p`/`--presets` flags, error reporting

### Deliverables

#### Behavioral Specifications
- Preset composition behavior definition
- Merge strategy specification
- CLI interface documentation

#### Validation Artifacts
- Test scenarios for preset merging
- Edge case handling verification
- User acceptance criteria for composition

## Out of Scope

- ❌ **Implementation Details**: Specific code changes to PresetManager or ContextLoader classes
- ❌ **Technology Decisions**: Choice of merging algorithms or data structures
- ❌ **Performance Optimization**: Caching strategies for loaded presets
- ❌ **Future Enhancements**: Preset inheritance, conditional includes, or template variables

## References

- Original idea: .ace-taskflow/v.0.9.0/docs/ideas/076-20251017-121339-ace-context-add-presets-options-to-the-config-sam.md
- Current preset structure: .ace/context/presets/*.md
- ace-context implementation: ace-context/lib/ace/context/