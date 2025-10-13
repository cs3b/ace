---
id: v.0.9.0+task.067
status: pending
priority: high
estimate: 2-3h
dependencies: []
---

# Fix retrospectives directory naming and configuration

## Behavioral Specification

### User Experience
- **Input**: Users run `ace-taskflow doctor` to check system health
- **Process**: System scans directories and validates all components without false positives
- **Output**: Accurate health report with no false errors for retrospective files

### Expected Behavior

The ace-taskflow system should properly recognize retrospective files in their designated directories and validate them correctly based on configurable directory names. Files in retrospectives folders should be identified as retrospectives (not tasks), and the directory naming should be consistent throughout the codebase.

The configuration system should allow users to customize directory names via `.ace/taskflow/config.yml`, with all code respecting these configuration values rather than using hardcoded directory names.

### Interface Contract

```bash
# CLI Interface
ace-taskflow doctor
# Should correctly identify retros in retros/ directories
# Should not show false positive errors for retro files

ace-taskflow retro create "Session learnings"
# Should create retro in configured directory

ace-taskflow retros --all
# Should list retros from configured directories

# Configuration Interface (.ace/taskflow/config.yml)
taskflow:
  directories:
    retros: "retros"  # Configurable directory name (plural)
```

**Error Handling:**
- Missing configuration: Use default "retros" directory name
- Invalid directory: Report clear error about misconfiguration

**Edge Cases:**
- Migration from old "reflections" directories
- Backward compatibility with existing "retro" configuration

### Success Criteria

- [ ] **Zero False Positives**: Doctor command shows no false errors for retrospective files
- [ ] **Configuration Respected**: All code uses configured directory name from config.yml
- [ ] **Consistent Naming**: Directory name is plural ("retros") throughout the system
- [ ] **Existing Files Recognized**: All 9 existing "reflections" directories renamed to "retros"
- [ ] **Health Score Improvement**: Eliminates 141+ false positive errors from doctor command

### Validation Questions

- [ ] **Migration Safety**: How should we handle existing "reflections" directories during migration?
- [ ] **Backward Compatibility**: Should we support old "retro" config key temporarily?
- [ ] **Documentation Updates**: Which documentation needs updating for the new directory naming?
- [ ] **Testing Coverage**: How do we test the configuration-driven directory naming?

## Objective

Fix the inconsistent retrospectives directory naming and ensure the system properly uses configuration values for directory names. This eliminates false positive errors in the doctor command and creates a consistent, configurable system for managing retrospectives.

## Scope of Work

- **Configuration Scope**: Update configuration file and add accessor methods
- **Code Update Scope**: Fix hardcoded directory references to use configuration
- **Migration Scope**: Rename existing "reflections" directories to "retros"

### Deliverables

#### Behavioral Specifications
- Proper retrospective file recognition in doctor command
- Configuration-driven directory naming system
- Consistent plural naming convention

#### Validation Artifacts
- Doctor command health check with no false positives
- Successful retro operations using configured directories
- Proper migration of existing directories

## Out of Scope

- ❌ **Other Directory Migrations**: Not changing other directory structures
- ❌ **Feature Enhancements**: Not adding new retro features
- ❌ **Performance Optimization**: Not optimizing scan performance
- ❌ **Database Changes**: No persistent storage modifications

## References

- Current doctor command showing 141+ false positives
- Existing configuration at `/Users/mc/Ps/ace-meta/.ace/taskflow/config.yml`
- 9 existing "reflections" directories needing migration

## Technical Research

### Current State Analysis

1. **Configuration Structure**: The system uses `taskflow.directories.retro: "retro"` in config.yml
2. **Code Inconsistency**:
   - RetroLoader hardcodes "retro" (singular)
   - Doctor/Validators expect "retros" (plural)
3. **Actual Directories**: All 9 retrospective folders are named "reflections"
4. **Missing Infrastructure**: No retro_dir accessor method in Configuration class

### Implementation Approach

Use configuration-driven directory naming with proper accessor methods to ensure all code respects user configuration. Update the configuration key itself to be plural for consistency.

## Implementation Plan

### Planning Steps

* [x] Analyze current directory structure and code references
* [x] Identify all hardcoded directory references
* [x] Design configuration-driven approach
* [x] Plan migration strategy for existing directories

### Execution Steps

#### 1. Update Configuration File
- [ ] Update `/Users/mc/Ps/ace-meta/.ace/taskflow/config.yml` line 29
  - Change `retro: "retro"` to `retros: "retros"` (both key and value plural)
  > TEST: Configuration Validation
  > Type: File Validation
  > Assert: Config file has retros key with retros value
  > Command: grep "retros: \"retros\"" /Users/mc/Ps/ace-meta/.ace/taskflow/config.yml

#### 2. Add Configuration Accessor
- [ ] Add retro_dir method to Configuration class (`lib/ace/taskflow/configuration.rb`)
  ```ruby
  def retro_dir
    config.dig("taskflow", "directories", "retros") || "retros"
  end
  ```
  > TEST: Method Availability
  > Type: Code Validation
  > Assert: Configuration class has retro_dir method
  > Command: grep -n "def retro_dir" ace-taskflow/lib/ace/taskflow/configuration.rb

#### 3. Update RetroLoader to Use Configuration
- [ ] Update `lib/ace/taskflow/molecules/retro_loader.rb` line 122
  - Change hardcoded `"retro"` to configuration value
  - Use: `@config.dig("taskflow", "directories", "retros") || "retros"`
- [ ] Update line 124: Same change for backlog path
- [ ] Update line 131: Same change for release path
  > TEST: Configuration Usage
  > Type: Code Validation
  > Assert: RetroLoader uses configuration for directory names
  > Command: grep "@config.dig.*retros" ace-taskflow/lib/ace/taskflow/molecules/retro_loader.rb

#### 4. Verify Validator Code
- [ ] Confirm validators already use "retros" plural:
  - `frontmatter_validator.rb` line 70: `/retros/` pattern
  - `structure_validator.rb` lines 155, 293, 312: "retros"
  - `release_validator.rb` line 141: "retros"
  > TEST: Validator Consistency
  > Type: Code Validation
  > Assert: All validators expect retros plural
  > Command: grep -n "retros" ace-taskflow/lib/ace/taskflow/molecules/*validator.rb

#### 5. Rename Existing Directories
- [ ] Rename all "reflections" directories to "retros"
  ```bash
  # Rename each reflections directory to retros
  for dir in $(find .ace-taskflow -type d -name "reflections"); do
    new_dir=$(echo "$dir" | sed 's/reflections$/retros/')
    git mv "$dir" "$new_dir"
  done
  ```
  > TEST: Directory Migration
  > Type: File System Validation
  > Assert: No reflections directories remain, all renamed to retros
  > Command: find .ace-taskflow -type d -name "reflections" | wc -l

#### 6. Test Doctor Command
- [ ] Run doctor command to verify false positives are eliminated
  ```bash
  bundle exec ace-taskflow doctor --format summary
  ```
  > TEST: Doctor Health Check
  > Type: Integration Test
  > Assert: Significant reduction in error count (from 141+)
  > Command: bundle exec ace-taskflow doctor --errors-only | grep "Critical Issues" | head -1

#### 7. Test Retro Operations
- [ ] Test retro creation in new directory structure
  ```bash
  bundle exec ace-taskflow retro create "Test retro after migration"
  ```
- [ ] Test retro listing
  ```bash
  bundle exec ace-taskflow retros --all
  ```
  > TEST: Retro Functionality
  > Type: Integration Test
  > Assert: Retro operations work with new directory structure
  > Command: bundle exec ace-taskflow retros --count

## Acceptance Criteria

- [x] Configuration file updated with plural key and value
- [ ] Configuration class has retro_dir accessor method
- [ ] RetroLoader uses configuration for directory names
- [ ] All "reflections" directories renamed to "retros"
- [ ] Doctor command shows significant reduction in false positives
- [ ] Retro create/list operations work correctly
- [ ] All tests pass