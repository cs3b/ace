---
id: 8ld000
title: Hardcoded Retro Path Remediation
type: standard
tags: []
created_at: '2025-10-14 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ld000-hardcoded-retro-path-remediation.md"
---

# Reflection: Hardcoded Retro Path Remediation

**Date**: 2025-10-14
**Context**: Investigation and fix of hardcoded retro directory paths throughout ace-taskflow codebase
**Author**: Claude Code with Miguel
**Type**: Standard

## What Went Well

- Systematic investigation approach identified all hardcoded paths efficiently
  - Code: 2 files (taskflow_doctor.rb, release_validator.rb)
  - Documentation: 3 files (create-retro.wf.md, draft-release.wf.md, README.md)
  - Data: Dual directory structure discovered and consolidated

- Configuration system already existed and worked well
  - Just needed to use it consistently
  - No architecture changes required
  - Easy to extend for other directory names

- Test coverage strategy worked perfectly
  - Created new test file for taskflow_doctor
  - Tests verified both default and custom directory names
  - All tests passing (3 tests, 8 assertions)

- Documentation updates improved user experience
  - Replaced manual bash path construction with CLI tools
  - Added configuration documentation to README
  - Updated workflows to be CLI-first

- Version bump process executed smoothly
  - 13 commits properly categorized (3 added, 3 fixed, 6 changed, 1 technical)
  - Changelog comprehensive and organized
  - Bump completed: 0.11.3 → 0.11.4

## What Could Be Improved

- Initial investigation should have checked actual directory structure first
  - Would have discovered the `retro/` vs `retros/` dual structure immediately
  - Could have consolidated directories before code fixes

- Documentation audit should be standard practice after config changes
  - Need a checklist: code → tests → docs → data migration
  - This would have caught the workflow issues earlier

- Workflow instructions should emphasize CLI tools over manual file operations
  - Manual path construction is error-prone
  - CLI tools respect configuration automatically

## Key Learnings

- **Configuration exists but needs to be used everywhere**: Having a config system is not enough - need to audit that all code paths use it

- **Data structure inconsistencies matter**: The dual `retro/` and `retros/` directories caused confusion and needed cleanup

- **CLI-first is better than bash-first**: Workflows should use `ace-taskflow retro create` instead of manual `mkdir` and file creation

- **Documentation is part of the fix**: Code changes without doc updates leave users confused

- **Test what you configure**: Configuration options should have test coverage showing they actually work

## Action Items

### Stop Doing

- Allowing hardcoded paths in new code (add linter check?)
- Writing workflows with manual bash path construction
- Leaving documentation inconsistent with implementation

### Continue Doing

- Systematic investigation approach (code → docs → data)
- Adding test coverage for configuration changes
- Using TodoWrite to track multi-step tasks
- Comprehensive commit messages with context

### Start Doing

- Add pre-commit check for hardcoded directory names
- Create documentation audit checklist for config changes
- Review workflows periodically to ensure they use CLI tools
- Consider linter rule: flag string literals matching directory names

## Technical Details

### Files Modified

**Code (previous session):**
1. `ace-taskflow/lib/ace/taskflow/organisms/taskflow_doctor.rb` - Use `config.retro_dir`
2. `ace-taskflow/lib/ace/taskflow/molecules/release_validator.rb` - Use `config.retro_dir`
3. `ace-taskflow/test/organisms/taskflow_doctor_test.rb` - Test coverage (new file)

**Documentation (this session):**
4. `ace-taskflow/handbook/workflow-instructions/create-retro.wf.md` - Replace bash with CLI
5. `ace-taskflow/handbook/workflow-instructions/draft-release.wf.md` - Fix directory names
6. `ace-taskflow/README.md` - Add configuration section

**Data:**
7. Moved 3 files from `.ace-taskflow/v.0.9.0/retro/` to `retros/`
8. Removed empty `retro/` directory

**Version:**
9. Bumped to 0.11.4 with changelog

### Configuration Pattern

```yaml
# .ace/taskflow/config.yml
taskflow:
  directories:
    retros: "retros"  # default, can be customized
```

Used via: `Ace::Taskflow.configuration.retro_dir`

### Validation Commands

```bash
# Verify no singular retro directories
find .ace-taskflow -type d -name "retro" 2>/dev/null  # should be empty

# Check for hardcoded paths
rg '"retro/"' ace-taskflow/README.md ace-taskflow/handbook/**/*.wf.md

# Run tests
bundle exec ruby ace-taskflow/test/organisms/taskflow_doctor_test.rb
```

## Additional Context

- **Related Issue**: User feedback that workflows should use tools over manual paths
- **Impact**: Medium - affects doctor validation and workflow documentation
- **Commits**:
  - Code fix (previous): Test coverage for configurable retro directories
  - Docs fix: `e8a0a292` - Consolidate retro directory and update workflows
  - Version: `a94ea1a6` - Bump to 0.11.4
- **Time**: ~2 hours total (investigation + implementation + documentation)

### Lessons for Future Config Work

1. **Audit checklist**: Code → Tests → Docs → Data → Migration helper (optional)
2. **Test actual vs expected**: Check if directory structure matches config defaults
3. **Favor CLI over bash**: Use tools that respect configuration automatically
4. **Document configuration**: Add examples to README showing how to customize
5. **Version bump scope**: Include all related changes in one release