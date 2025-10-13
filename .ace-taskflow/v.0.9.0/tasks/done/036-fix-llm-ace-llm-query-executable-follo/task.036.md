---
id: v.0.9.0+task.036
status: done
estimate: 30m
dependencies: []
---

# Fix ace-llm-query executable to follow standard pattern

## Behavioral Context

**Issue**: ace-llm-query wasn't producing any output when run via the binstub in bin/ace-llm-query

**Key Behavioral Requirements**:
- Executable must work when loaded via `load` statement from binstub
- Output must be visible when running commands like `--version` and `--help`
- Must follow same pattern as other ace-* executables

## Objective

Fixed ace-llm-query executable by removing the `if __FILE__ == $0` conditional that prevented execution when loaded via binstub.

## Scope of Work

### Deliverables

#### Modify
- `ace-llm/exe/ace-llm-query` - Removed `if __FILE__ == $0` check and made CLI run directly

## Implementation Summary

### What Was Done

- **Problem Identification**: Discovered that `ace-llm-query --version` produced no output when run through binstub
- **Investigation**: Found that `if __FILE__ == $0` check fails when file is loaded via `load` (since `__FILE__` is the exe path but `$0` is the binstub path)
- **Solution**: Removed the conditional check and made the CLI instantiate and run directly, matching the pattern used by ace-nav, ace-taskflow, and ace-test
- **Validation**: Tested that `--version`, `--help`, and actual queries work correctly through the binstub

### Technical Details

Changed from:
```ruby
# Run the CLI
if __FILE__ == $0
  cli = Ace::LLM::QueryCLI.new
  cli.run(ARGV)
end
```

To:
```ruby
# Run the CLI
cli = Ace::LLM::QueryCLI.new
cli.run(ARGV)
```

### Testing/Validation

```bash
# Test commands that now work:
./bin/ace-llm-query --version  # Shows: ace-llm-query 0.1.0
./bin/ace-llm-query --help     # Shows full help text
./bin/ace-llm-query gflash "test"  # Attempts API call (gets API key error as expected)
```

**Results**: All commands now produce proper output through the binstub

## References

- Related to: task.021 (Extract llm-query from dev-tools to ace-llm gem)
- Pattern follows: ace-nav, ace-taskflow, ace-test executables