# Fix Retrospectives Directory Naming - Usage Guide

## Overview

This task fixes the retrospectives directory naming inconsistency in ace-taskflow, eliminating 141+ false positive errors in the doctor command and ensuring proper configuration-driven directory naming.

## Before and After

### Before
- Doctor command reports 141+ false errors for retrospective files
- Retrospective files in "reflections" directories are misidentified as tasks
- Hardcoded directory names ignore configuration
- Inconsistent naming: "retro" (singular) vs "retros" (plural)

### After
- Doctor command correctly identifies retrospective files
- All retrospective directories use consistent "retros" naming
- Configuration drives directory naming throughout the system
- Zero false positives for retrospective files

## Configuration Changes

### Updated Configuration
```yaml
# .ace/taskflow/config.yml
taskflow:
  directories:
    # Changed from retro: "retro" to:
    retros: "retros"  # Both key and value are now plural
```

### Configuration Usage in Code
```ruby
# New Configuration accessor method
config = Ace::Taskflow::Configuration.new
retro_dir = config.retro_dir  # Returns "retros" or configured value
```

## Migration Process

### Directory Renaming
All existing "reflections" directories are renamed to "retros":
```bash
# Before
.ace-taskflow/done/v.0.2.0-synapse-tools/reflections/
.ace-taskflow/done/v.0.3.0-migration-tools/reflections/
# ... 9 total directories

# After
.ace-taskflow/done/v.0.2.0-synapse-tools/retros/
.ace-taskflow/done/v.0.3.0-migration-tools/retros/
# ... all renamed to retros/
```

## Verification

### Check Doctor Health
```bash
# Run doctor command - should show significant improvement
bundle exec ace-taskflow doctor --format summary

# Before: Health: Poor (0/100) | Errors: 141 | Warnings: 183
# After:  Health: Better | Errors: <10 | Warnings: <183
```

### Test Retro Operations
```bash
# Create a new retrospective
bundle exec ace-taskflow retro create "Migration success notes"

# List all retrospectives
bundle exec ace-taskflow retros --all

# Check specific release retros
bundle exec ace-taskflow retros --context v.0.9.0
```

## Technical Details

### Files Modified
1. **Configuration**: `/Users/mc/Ps/ace-meta/.ace/taskflow/config.yml`
2. **Configuration Class**: `ace-taskflow/lib/ace/taskflow/configuration.rb`
3. **RetroLoader**: `ace-taskflow/lib/ace/taskflow/molecules/retro_loader.rb`
4. **Directory Structure**: All "reflections" → "retros"

### Code Changes
- Configuration key changed from `retro:` to `retros:`
- Added `retro_dir` accessor method to Configuration class
- RetroLoader now uses configuration instead of hardcoded values
- Validators already expect "retros" plural (no changes needed)

## Benefits

1. **Eliminates False Positives**: 141+ errors removed from doctor command
2. **Consistent Naming**: Plural form matches other directories (ideas, docs)
3. **Configuration-Driven**: Respects user configuration settings
4. **Better Health Score**: Improves overall system health assessment
5. **Future Flexibility**: Easy to change directory names via configuration

## Rollback (if needed)

If issues arise, rollback by:
1. Revert git commits for code changes
2. Rename directories back: `retros` → `reflections`
3. Restore original config: `retros: "retros"` → `retro: "retro"`

## Summary

This fix creates a consistent, configuration-driven system for retrospectives directories, eliminating false positive errors and improving the overall health check accuracy of ace-taskflow doctor command.