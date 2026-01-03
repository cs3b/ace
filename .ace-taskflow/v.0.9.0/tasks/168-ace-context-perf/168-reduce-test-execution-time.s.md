---
id: v.0.9.0+task.168
status: draft
priority: medium
estimate: 4h
dependencies: []
---

# Optimize ace-context test performance (15s to under 5s)

## Behavioral Specification

### User Experience
- **Input**: Developer runs `ace-test ace-context` to execute test suite
- **Process**: Tests execute with properly mocked commands and optimized file I/O
- **Output**: Full test results in <5 seconds (down from 14.94s)

### Expected Behavior
Developers experience faster test execution. The mega-test file is split for maintainability. CLI tests consistently use CommandMockHelper instead of bypassing with Open3.capture3.

### Interface Contract

```bash
# No changes to public interfaces
# Test structure improvements:
# - context_loader_test.rb split into focused files
# - CLI tests use CommandMockHelper consistently
```

### Success Criteria

- [ ] Test suite runs in <5 seconds (currently 14.94s)
- [ ] All 177 tests pass
- [ ] context_loader_test.rb split into 3-4 focused files
- [ ] CLI tests use CommandMockHelper (no Open3.capture3 bypass)

## Objective

Reduce ace-context test execution time by 66%+ (from 15s to <5s) by splitting mega-test file, ensuring consistent mock usage, and reducing filesystem I/O.

## Scope of Work

### Root Cause Analysis (from investigation)
- Mega-test file: `context_loader_test.rb` (989 lines, 32 tests)
- Some CLI tests use Open3.capture3 directly, bypassing CommandMockHelper
- Many mktmpdir calls creating real filesystem structures
- Git repo setup in tests (system("git init"))

### Key Files to Modify
- `ace-context/test/organisms/context_loader_test.rb` - split into multiple files
- `ace-context/test/integration/cli_embed_source_test.rb:60` - use CommandMockHelper
- `ace-context/test/integration/cli_preset_composition_test.rb` - use mocks
- `ace-context/test/molecules/preset_manager_test.rb` - mock preset loading

### Optimizations
1. Split context_loader_test.rb (989 lines) into 3-4 focused test files
2. Replace Open3.capture3 with CommandMockHelper in CLI integration tests
3. Use mocked presets for unit tests (avoid real file I/O)
4. Leverage test_mode more effectively

## Out of Scope

- ❌ Changes to production code in ace-context
- ❌ Reducing test coverage
- ❌ Removing integration tests that validate real behavior
