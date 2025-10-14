# ADR-017: Flat Test Structure

## Status
Accepted
Date: October 14, 2025

## Context

During mono-repo migration (ADR-015), different test organization patterns emerged. Some gems used nested structure (`test/ace/gem/atoms/`), others used flat (`test/atoms/`). This inconsistency created confusion and made it harder to navigate test files.

### Problems with Nested Test Structure

1. **Deep Paths**: `test/ace/gem/atoms/parser_test.rb` is verbose and hard to navigate
2. **Inconsistency**: Some gems nested, others flat - no standard
3. **Discoverability**: Hard to quickly find test files
4. **IDE Navigation**: Longer paths complicate IDE file navigation
5. **Unclear Benefit**: Nesting doesn't add value - lib/ already has structure

### Observed Best Practice

Analysis of production gems showed flat structure worked better:
- **ace-lint**: `test/atoms/kramdown_parser_test.rb` ✓
- **ace-docs**: `test/molecules/document_analyzer_test.rb` ✓
- **ace-search**: `test/organisms/searcher_test.rb` ✓

## Decision

All ace-* gems **must** use flat test structure that directly mirrors ATOM layers:

```
test/
├── test_helper.rb
├── gem_test.rb              # Main module test
├── atoms/
│   └── parser_test.rb       # *_test.rb suffix
├── molecules/
│   └── loader_test.rb
├── organisms/
│   └── processor_test.rb
├── models/
│   └── result_test.rb
├── commands/                # CLI command tests
│   └── process_command_test.rb
├── integration/             # End-to-end tests
│   └── cli_test.rb
└── fixtures/                # Test data
    └── sample.yml
```

### Requirements

**DO:**
- ✅ Use flat structure: `test/atoms/` not `test/ace/gem/atoms/`
- ✅ Mirror ATOM layers directly
- ✅ Use `*_test.rb` suffix (not `test_*.rb`)
- ✅ Include `commands/` for CLI tests
- ✅ Include `integration/` for end-to-end tests
- ✅ Include `fixtures/` for test data

**DON'T:**
- ❌ Nest under gem namespace: `test/ace/gem/`
- ❌ Create deep directory hierarchies
- ❌ Use inconsistent naming: `test_*.rb` or `*_spec.rb`
- ❌ Mix test types in same directory

### File Naming

```ruby
# test/atoms/parser_test.rb
class ParserTest < AceTestCase
  def test_parse_valid_input
    # ...
  end
end
```

Test class name matches file: `parser_test.rb` → `ParserTest`

## Consequences

### Positive

- **Simplicity**: Shallow, easy-to-navigate structure
- **Consistency**: All gems use same pattern
- **Discoverability**: Quick to find tests
- **IDE Friendly**: Short paths in file trees
- **Clear Organization**: ATOM layers obvious at glance
- **Fast Navigation**: Less typing to reach files

### Negative

- **Migration Effort**: Existing nested tests need moving
- **Path Updates**: Require statement paths may need adjustment

### Neutral

- **No Namespace**: Test files don't mirror lib/ namespacing exactly
- **Layer Clarity**: Relies on developers knowing ATOM pattern

## Rationale

### Why Flat Over Nested?

1. **Simplicity Wins**: Shorter paths are easier to work with
2. **Structure is in lib/**: Don't duplicate it in test/
3. **Layer Visibility**: ATOM layers immediately visible
4. **Proven Pattern**: Works well in Rails and other Ruby projects
5. **Tool Compatibility**: Works better with test runners and IDEs

### Comparison

```
# ❌ Nested (verbose, complex)
test/ace/git_commit/atoms/parser_test.rb
test/ace/git_commit/molecules/loader_test.rb

# ✅ Flat (concise, clear)
test/atoms/parser_test.rb
test/molecules/loader_test.rb
```

## Implementation

### For New Gems

Create flat structure from start:
```bash
mkdir -p test/{atoms,molecules,organisms,models,commands,integration,fixtures}
touch test/test_helper.rb
```

### For Existing Gems

Flatten existing structure:
```bash
# Move tests from nested to flat
mv test/ace/gem/atoms/* test/atoms/
mv test/ace/gem/molecules/* test/molecules/
# ... etc
```

Update require statements if needed.

### test_helper.rb Standard

```ruby
# test/test_helper.rb
require 'ace/test_support'
require 'ace/gem'

# Load all gem components
Dir[File.expand_path('../lib/ace/gem/**/*.rb', __dir__)].each { |f| require f }

class GemTestCase < AceTestCase
  # Shared test setup
end
```

## Examples from Production

### ace-lint (Clean Flat Structure)
```
test/
├── atoms/kramdown_parser_test.rb
├── molecules/kramdown_linter_test.rb
├── commands/lint_command_test.rb
├── integration/cli_test.rb
└── fixtures/valid.md
```

### ace-docs (With All Layers)
```
test/
├── atoms/frontmatter_parser_test.rb
├── molecules/document_analyzer_test.rb
├── organisms/status_checker_test.rb
├── models/document_test.rb
├── commands/status_command_test.rb
└── integration/diff_workflow_test.rb
```

## Related Decisions

- **ADR-011**: ATOM Architecture House Rules - defines layers being mirrored
- **ADR-015**: Mono-Repo Migration - context for standardization
- **ADR-018**: Thor CLI Commands - commands/ testing pattern

## References

- **ace-test-support**: Provides AceTestCase base class
- **ace-test-runner**: Executes flat test structure
- **Rails Testing**: Inspiration for flat test organization
- **Minitest**: Test framework used across all gems

---

This ADR standardizes test organization across all ACE gems with a simple, flat structure that mirrors ATOM layers directly for maximum clarity and ease of navigation.
