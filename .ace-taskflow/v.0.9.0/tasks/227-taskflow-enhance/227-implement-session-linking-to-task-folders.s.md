---
id: v.0.9.0+task.227
status: pending
priority: medium
estimate: 3h
dependencies: []
---

# 226.08: Review Session Linking to Task Folders

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-review` with `--task` flag or auto-save from a feature branch
- **Process**: System creates symlinks from task folder to cache session directories, copies only synthesis reports
- **Output**: Task reviews folder contains symlinks to session folders plus tracked synthesis reports

### Expected Behavior

Currently, ace-review copies all review files to task folders as flat files with timestamp prefixes. This results in unnecessary file duplication, large git repository growth (even though gitignored), and difficult navigation between task reviews and original sessions. All files in `reviews/` are gitignored, including synthesis reports.

The new behavior should:

1. **Symlink Session Folders**: Create `reviews/reports/review-<session-id>/` as a symlink to `.cache/ace-review/sessions/review-<id>/`
   - Symlinks are gitignored (no duplication in repository)
   - Easy navigation from task to original session
   - All session content accessible via symlink

2. **Copy Synthesis Reports**: Copy only `*-synthesis.md` files directly to `reviews/` directory
   - These files are tracked in git
   - Provide historical record of synthesis outcomes
   - Timestamped filenames for uniqueness

3. **Update Gitignore**: Modify ignore patterns to:
   - Ignore `reviews/reports/` (symlinks)
   - Track `reviews/*-synthesis.md` (actual files)

### Interface Contract

```ruby
# New API for TaskReportSaver

# Save review session via symlink (replaces file copying)
TaskReportSaver.save(task_dir, session_dir, review_data)
# => { success: true, path: "reviews/reports/review-8oloay" }

# Save synthesis report as actual copy (tracked in git)
TaskReportSaver.save_synthesis(task_dir, synthesis_file, review_data)
# => { success: true, path: "reviews/8oloax-synthesis.md" }
```

**Expected directory structure:**
```
.ace-taskflow/v.0.9.0/tasks/218-docs-refactor/reviews/
├── reports/
│   ├── review-8oloay -> ../../../../../.cache/ace-review/sessions/review-8oloay
│   ├── review-8olk3o -> ../../../../../.cache/ace-review/sessions/review-8olk3o
│   └── ...
├── 8oloax-synthesis.md  (tracked copy)
└── 8ol2x1-synthesis.md  (tracked copy)
```

**Error Handling:**
- Session directory not found: Return error with clear message
- Task directory not found: Return error with clear message
- Symlink creation fails: Return error with failure reason
- Synthesis copy fails: Return error with failure reason

**Edge Cases:**
- Symlink already exists: Force update with `FileUtils.ln_sf`
- Relative path calculation: Use `Pathname` for portability
- Existing flat files: Remain in place (backward compatible)

### Success Criteria

- [ ] **Symlink Structure**: `reviews/reports/` contains symlinks to session directories
- [ ] **Synthesis Tracking**: `reviews/*-synthesis.md` files are tracked in git
- [ ] **Gitignore Patterns**: `.gitignore` excludes symlinks but includes synthesis reports
- [ ] **Backward Compatible**: Existing flat files in `reviews/` remain functional
- [ ] **Navigation**: Users can navigate from task to session via symlink

### Validation Questions

- [ ] **Symlink Portability**: Will relative symlinks work across different machines/checkout locations?
- [ ] **Windows Compatibility**: Do symlinks work on Windows with Developer Mode enabled?
- [ ] **Migration Strategy**: Should old flat files be migrated or left in place?
- [ ] **Cache Cleanup**: What happens when cache directories are deleted?

## Objective

Reduce repository duplication and improve navigation between task reviews and their original review sessions.

## Scope of Work

- **User Experience Scope**: Symlink creation, synthesis report copying, gitignore updates
- **System Behavior Scope**: TaskReportSaver API changes, ReviewManager caller updates
- **Interface Scope**: TaskReportSaver.save(), TaskReportSaver.save_synthesis()

### Deliverables

#### Create

- `ace-review/lib/ace/review/molecules/task_report_saver.rb` (refactored)

#### Modify

- `ace-review/lib/ace/review/organisms/review_manager.rb`
- `.gitignore`

## Implementation Plan

### Planning Steps

* [ ] Research Ruby symlink creation patterns and portability considerations
* [ ] Review Pathname API for relative path calculation
* [ ] Identify all caller sites of TaskReportSaver.save()

### Execution Steps

- [ ] Step 1: Refactor `TaskReportSaver.save()` to create symlinks
  - Change signature from `save(task_dir, review_file, review_data)` to `save(task_dir, session_dir, review_data)`
  - Create `reviews/reports/` subdirectory
  - Extract session ID from `session_dir` path using `File.basename`
  - Calculate relative path using `Pathname.new(session_dir).relative_path_from(Pathname.new(reports_dir))`
  - Create symlink with `FileUtils.ln_sf(relative_session_path, symlink_path)`
  - Return symlink path in result

- [ ] Step 2: Add `TaskReportSaver.save_synthesis()` method
  - Signature: `save_synthesis(task_dir, synthesis_file, review_data)`
  - Create `reviews/` directory (not `reviews/reports/`)
  - Generate synthesis filename using existing `generate_filename()` with `report_type: 'synthesis'`
  - Copy synthesis file with `FileUtils.cp()` (actual copy, not symlink)
  - Return output path in result

- [ ] Step 3: Update callers in `ReviewManager`
  - `save_to_task_if_requested()`: Pass `session_dir` instead of `result[:output_file]`
  - `auto_save_review_if_enabled()`: Pass `session_dir` instead of `review_file`
  - `auto_save_to_release()`: Extract `review.md` from `session_dir` for release saving
  - `save_multi_model_to_task()`: Pass `session_dir` instead of iterating over model results
  - `auto_save_multi_model_reports()`: Pass `session_dir` instead of individual model output files

- [ ] Step 4: Add `auto_save_synthesis_if_enabled()` method
  - New method for synthesis-specific auto-save handling
  - Detect task from branch like existing auto-save
  - Call `TaskReportSaver.save_synthesis()` instead of `save()`

- [ ] Step 5: Update synthesis auto-save call site
  - In `execute_multi_model()`, change synthesis auto-save to use new method
  - Pass `synthesis_result[:output_file]` directly to `save_synthesis()`

- [ ] Step 6: Update `.gitignore` patterns
  - Change from: `.ace-taskflow/**/reviews/`
  - Change to: `.ace-taskflow/**/reviews/reports/`
  - Add negation: `!.ace-taskflow/**/reviews/*-synthesis.md`

- [ ] Step 7: Verify symlink resolution
  - > TEST: Symlink Resolution
  > Type: Action Validation
  > Assert: Symlink resolves to session directory and files are accessible
  > Command: # Test: ls -la .ace-taskflow/v.0.9.0/tasks/XXX/reviews/reviews/ && cat reviews/reports/review-XXX/review.md

- [ ] Step 8: Verify git tracking
  - > TEST: Git Status Verification
  > Type: Action Validation
  > Assert: Only synthesis files are tracked, symlinks are ignored
  > Command: # Test: git status --short | grep reviews

## Acceptance Criteria

- [ ] AC 1: `TaskReportSaver.save()` creates symlinks to session directories
- [ ] AC 2: `TaskReportSaver.save_synthesis()` copies synthesis files to `reviews/`
- [ ] AC 3: All ReviewManager callers updated to use new API
- [ ] AC 4: `.gitignore` excludes `reviews/reports/` but includes `*-synthesis.md`
- [ ] AC 5: Symlinks resolve correctly and session files are accessible

## Out of Scope

- **Migration Tools**: Scripts to convert existing flat files to symlinks
- **Cache Management**: Automatic cleanup of old session directories
- **Documentation Updates**: User guide updates for new structure

## References

- Original plan: "226.08 - Review Session Linking to Task Folders"
- Related task: 226 (ace-taskflow enhancements)
- Current implementation: `ace-review/lib/ace/review/molecules/task_report_saver.rb`
