# Review Synthesis: Task 121.01 - ace-prompt Basic Archive + Output

## Overview

Three AI reviewers analyzed the ace-prompt implementation (GPT-5.1, GPro, GLM-4.6). The Kimi-K2 report was empty.

All reviewers praised:
- Strong ATOM architecture adherence
- Comprehensive test coverage
- Thoughtful error handling
- Good separation of concerns

## Synthesized Recommendations by Priority

### HIGH Priority (ace-prompt specific)

| Issue | Source | Description | Location |
|-------|--------|-------------|----------|
| CLI exit pattern violation | GPT-5.1 | `process` calls `exit 1` on errors. ACE pattern requires returning status codes, exit only in `exe/` | `cli.rb:10-12, 42-77` |
| Missing CLI integration tests | GPT-5.1, GLM-4.6 | No end-to-end CLI test for `process` command verifying success/failure flows | `test/` |

### MEDIUM Priority (ace-prompt specific)

| Issue | Source | Description | Location |
|-------|--------|-------------|----------|
| README path violation | GPT-5.1 | Uses `../../.ace-taskflow/...` - violates ADR-004 (no `../` paths) | `README.md:36` |
| Unused parameter | GPT-5.1 | `base_dir` parameter in `update_symlink` not used | `prompt_archiver.rb:68-88` |
| Simplify file output | GPro | Redundant directory checks in CLI file output logic | `cli.rb:48-56` |
| Add output validation | GLM-4.6 | Validate output path format before writing | `cli.rb` |

### LOW Priority (ace-prompt specific)

| Issue | Source | Description | Location |
|-------|--------|-------------|----------|
| Add --dry-run option | GLM-4.6 | Useful for testing without side effects | `cli.rb` |
| Add handbook examples | GLM-4.6 | Workflow examples in handbook/ directory | `handbook/` |
| Content validation | GLM-4.6 | Consider adding prompt content validation step | `prompt_processor.rb` |

### OUT OF SCOPE (ace-git-worktree - separate task)

These items affect ace-git-worktree, not ace-prompt:
- `auto_push_task: true` default behavior
- `TaskFetcher` project root regression
- `TaskWorktreeOrchestrator` branch push issue
- CLI tests for `--no-push`, `--push-remote` flags
- `TaskIDExtractor` regex anchoring

## Implementation Plan

### Phase 1: Critical Fixes (HIGH)

1. **Fix CLI exit pattern**
   - Change `exit_on_failure?` to return `false`
   - Replace `exit 1` with `return 1` in `process` method
   - Update `exe/ace-prompt` to capture and exit with return value
   - Add tests asserting return codes

2. **Add CLI integration tests**
   - Test `process` with temp project root and prompt file
   - Verify content output, archive creation, `_previous.md` symlink
   - Test `--output` to file
   - Test error paths (missing prompt file, unwritable output)

### Phase 2: Medium Fixes

3. **Fix README path**
   - Remove `../` path reference
   - Either point to gem-local `docs/usage.md` or remove external reference

4. **Clean up unused parameter**
   - Remove `base_dir` parameter from `update_symlink` or use it

5. **Simplify file output logic**
   - Use `FileUtils.mkdir_p` without redundant checks

6. **Add output path validation**
   - Validate output path is writable before processing

### Phase 3: Enhancements (LOW)

7. **Add --dry-run option** (optional for this subtask)

## Estimated Effort

- Phase 1: 2-3 hours
- Phase 2: 1-2 hours
- Phase 3: Optional / future task

**Total: 3-5 hours**

## Files to Modify

```
ace-prompt/
├── lib/ace/prompt/cli.rb           # Fix exit pattern, add validation
├── lib/ace/prompt/molecules/
│   └── prompt_archiver.rb          # Clean unused param
├── exe/ace-prompt                   # Handle return codes
├── README.md                        # Fix path reference
└── test/
    └── integration/
        └── cli_integration_test.rb  # NEW: Add CLI tests
```
