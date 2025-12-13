# Code Review

## Summary

This diff introduces substantial improvements across multiple areas:
- **ace-git-worktree v0.4.1**: Major refactoring with new `TaskIDExtractor` atom and `TaskPusher` molecule to properly handle hierarchical subtask IDs
- **ace-prompt v0.1.0**: New gem for prompt workspace management with full ATOM architecture
- **Task Management**: Updates to task 121 (ace-prompt orchestrator) and new task 123 for subtask ID fixes

The changes demonstrate excellent understanding of ATOM architecture and Ruby best practices, with comprehensive test coverage. Main concerns are CLI pattern compliance and documentation path standards.

## ✅ Strengths

### Architecture & Design
- **Perfect ATOM adherence**: Both gems follow atoms/molecules/organisms structure flawlessly
- **Centralized logic**: `TaskIDExtractor` atom eliminates code duplication across 6+ files
- **Clean separation**: Prompt functionality properly separated into reader, archiver, and processor
- **Mono-repo integration**: ace-prompt properly integrated with Gemfile, binstubs, and build system

### Testing Quality
- **Comprehensive coverage**: 135 tests for `TaskIDExtractor` covering edge cases
- **Integration tests**: Subtask workflow integration tests verify cross-component behavior
- **Proper test patterns**: Uses stubs to avoid external dependencies, tests error paths
- **Edge case handling**: Unicode, large content, timestamp collisions all tested

### Code Quality
- **Ruby idioms**: Proper use of keyword arguments, frozen strings, modules
- **Error handling**: Graceful fallbacks and informative error messages throughout
- **Documentation**: Clear inline comments and method documentation

## 🔴 Critical Issues

### 1. CLI Exit Pattern Violation in ace-prompt
**File**: `ace-prompt/lib/ace/prompt/cli.rb:10-12, 48, 71, 76`

```ruby
# Current (violates ACE testing patterns)
def self.exit_on_failure?
  true  # Should be false
end

def process
  # ...
  exit 1 if error  # Should return 1
end
```

**Fix**:
```ruby
def self.exit_on_failure?
  false
end

def process
  # ...
  return 1 if error
  return 0 on success
end
```

**Update**: `ace-prompt/exe/ace-prompt` to capture return value:
```ruby
exit_code = Ace::Prompt::CLI.start(ARGV)
exit(exit_code || 0)
```

**Impact**: Critical - prevents tests from completing properly per `docs/testing-patterns.md`

## 🟡 High Priority Issues

### 1. Missing CLI Integration Tests
**File**: `ace-prompt/test/`

The current test suite lacks end-to-end CLI tests that verify:
- `process` command returns proper status codes
- File output with `--output` option
- Error handling for missing files

**Add**: `ace-prompt/test/integration/cli_integration_test.rb` with tests for:
- Successful process flow (returns 0)
- File output creation (returns 0)
- Missing prompt file error (returns 1)

### 2. README Path Violation (ADR-004)
**File**: `ace-prompt/README.md:36`

```markdown
<!-- Current (violates ADR-004) -->
See: ../../.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/ux/usage.md
```

**Fix**: Remove external reference or use gem-local documentation:
```markdown
<!-- Fixed -->
Additional documentation available in the gem's handbook/ directory.
```

## 🟢 Medium Priority Issues

### 1. Unused Parameter in PromptArchiver
**File**: `ace-prompt/lib/ace/prompt/molecules/prompt_archiver.rb:69`

```ruby
# Current
def self.update_symlink(symlink_path, target_path, base_dir)
  # base_dir parameter not used
end
```

**Fix**: Remove unused parameter:
```ruby
def self.update_symlink(symlink_path, target_path)
```

Update call site at line 46 accordingly.

### 2. Simplify File Output Logic
**File**: `ace-prompt/lib/ace/prompt/cli.rb:60-61`

```ruby
# Current
output_dir = File.dirname(output_mode)
FileUtils.mkdir_p(output_dir) unless output_dir == "." || File.directory?(output_dir)
```

**Simplify to**:
```ruby
FileUtils.mkdir_p(File.dirname(output_mode))
```

## 📋 Detailed File-by-File Feedback

### ace-git-worktree/atoms/task_id_extractor.rb
- ✅ **Excellent**: Robust regex patterns with TaskReferenceParser fallback
- ✅ **Good**: Handles all ACE task ID formats including subtasks
- 💡 **Consider**: Add debug logging when regex fallback is used

### ace-prompt/organisms/prompt_processor.rb
- ✅ **Clean**: Simple orchestration of read → archive flow
- ✅ **Good**: Proper error propagation
- 💡 **Future**: Consider adding content validation step

### ace-prompt/cli.rb
- ✅ **Complete**: Thor CLI with proper option handling
- ❌ **Critical**: Exit pattern violation needs fixing
- 💡 **Enhancement**: Consider adding `--dry-run` option

### Test Files
- ✅ **Comprehensive**: Excellent coverage across all layers
- ✅ **Proper**: Uses stubs correctly to avoid external dependencies
- ✅ **Edge cases**: Unicode, large content, timestamp collisions handled

## 🔍 Security Review

- ✅ **Path validation**: Uses ProjectRootFinder to prevent directory traversal
- ✅ **Input sanitization**: Task references validated with regex
- ✅ **File operations**: Relative paths used for symlinks
- ✅ **Command execution**: GitCommand uses argument arrays (no shell injection)

## 📊 Performance Review

- **TaskIDExtractor**: O(1) regex operations, negligible overhead
- **PromptArchiver**: File I/O bound but reasonable for prompt sizes
- **Test suite**: Good use of stubs avoids slow git operations

## 🎯 Architectural Compliance

### ATOM Pattern
- ✅ **Atoms**: Pure functions (TaskIDExtractor, TimestampGenerator)
- ✅ **Molecules**: Focused operations (TaskFetcher, PromptArchiver)
- ✅ **Organisms**: Business orchestration (TaskWorktreeOrchestrator, PromptProcessor)
- ✅ **Models**: Data structures (WorktreeConfig)

### Dependency Management
- ✅ **External deps**: Minimal and justified (thor, ace-support-core)
- ✅ **Internal deps**: Proper layering maintained

## 🚀 Prioritised Action Items

### Must Fix (Critical)
1. **Fix CLI exit pattern** in ace-prompt (`cli.rb:10-12, 48, 71, 76`)
2. **Update exe/ace-prompt** to handle return codes
3. **Add CLI integration tests** for end-to-end validation

### Should Fix (High)
4. **Fix README path** violation (ADR-004 compliance)
5. **Add integration tests** for ace-git-worktree push options

### Could Fix