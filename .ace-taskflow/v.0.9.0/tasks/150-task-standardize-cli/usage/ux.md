# ACE CLI UX Analysis

## Executive Summary

Analysis of 14 ace-* CLI tools reveals significant fragmentation in framework usage, option patterns, and output handling. Standardization to Thor (per ADR-018) will improve consistency, maintainability, and user experience.

---

## Current State

### Framework Distribution

| Framework | Count | Packages |
|-----------|-------|----------|
| Thor (compliant) | 5 | ace-docs, ace-git, ace-git-secrets, ace-lint, ace-prompt |
| OptionParser | 7 | ace-context, ace-git-commit, ace-llm, ace-nav, ace-review, ace-search, ace-test-runner |
| Custom case/when | 2 | ace-git-worktree, ace-taskflow |

**Compliance Rate**: 35% (5/14) currently Thor-compliant

### Entry Point Patterns

| Pattern | Packages |
|---------|----------|
| `CLI.start(ARGV)` | Thor CLIs, ace-taskflow |
| `CLI.new.run(ARGV)` | ace-nav, ace-review |
| `CLI.new(ARGV).run` | ace-git-worktree |
| `CLI.run(ARGV)` | ace-git-commit |
| Direct OptionParser | ace-context, ace-search, ace-test-runner, ace-llm |

---

## Inconsistency Catalog

### 1. Exit Code Handling

| Pattern | Packages | Issue |
|---------|----------|-------|
| `exit N` in command | ace-context, ace-search | Kills test process |
| `exit! N` | ace-test-runner | Required for Minitest |
| Return from execute | Thor CLIs | Correct pattern |
| Class variable | ace-git-secrets | Unnecessary complexity |

**Recommendation**: Commands return exit codes, exe handles `exit()`

### 2. Help Text Quality

| Quality | Packages | Notes |
|---------|----------|-------|
| Excellent | ace-git-commit, ace-test-runner, ace-review | Full examples |
| Good | ace-context, ace-search | Some examples |
| Minimal | ace-nav, ace-llm | Basic usage only |
| Auto-generated | Thor CLIs | Consistent via Thor |

**Recommendation**: Thor auto-generates help; add `long_desc` for examples

### 3. Option Naming Conflicts

| Short Flag | Packages Using | Conflicts |
|------------|----------------|-----------|
| `-v` | ace-git-commit (version), ace-review (verbose) | Different meanings |
| `-f` | ace-lint (fix), ace-search (files), ace-llm (file) | Different meanings |
| `-c` | ace-git (commits), ace-test (config), ace-llm (context) | Different meanings |
| `-q` | Many (quiet) | Consistent - KEEP |

**Recommendation**: Reserve short flags for consistent meanings:
- `-v` → verbose (version via `--version`)
- `-q` → quiet
- `-h` → help

### 4. Output Format Options

| Pattern | Packages | Notes |
|---------|----------|-------|
| `--json` | ace-search, ace-taskflow | Standalone flag |
| `--format json` | ace-git, ace-git-secrets | Enum option |
| `--output MODE` | ace-context | Output destination |
| Mixed | ace-review | Both `--json` and `--output` |

**Recommendation**: Standardize on:
- `--format FORMAT` for output format (json, markdown, text)
- `--output PATH` for output destination

### 5. Verbose/Quiet Flags

| Package | Verbose | Quiet | Debug |
|---------|---------|-------|-------|
| ace-git-commit | `--verbose` | `-q` | `-d` |
| ace-search | N/A | N/A | via ENV |
| ace-nav | `--verbose` | N/A | N/A |
| ace-review | `-v` | N/A | N/A |
| ace-test | `-v` | N/A | N/A |

**Recommendation**: All CLIs support:
- `--verbose` / `-v` - Detailed output
- `--quiet` / `-q` - Minimal output (suppresses ConfigSummary)
- `--debug` / `-d` - Debug information

### 6. Default Commands

| Package | Default | Pattern |
|---------|---------|---------|
| ace-context | load | Implicit |
| ace-git | diff | `default_task` + magic routing |
| ace-lint | lint | `default_task` + magic file detection |
| ace-prompt | process | `default_task` |
| ace-search | search | Implicit |
| ace-taskflow | show help | No default |

**Recommendation**: Use Thor `default_task` for single-purpose tools

---

## Recommended Standards

### Standard Option Set

All CLIs should support:

```ruby
# Universal options (all commands)
option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary"
option :verbose, type: :boolean, aliases: "-v", desc: "Detailed output"
option :debug, type: :boolean, aliases: "-d", desc: "Debug information"

# Output options (where applicable)
option :format, type: :string, enum: %w[text json markdown yaml]
option :output, type: :string, aliases: "-o", desc: "Output file path"
```

### Reserved Short Flags

| Flag | Meaning | Notes |
|------|---------|-------|
| `-h` | help | Thor default |
| `-v` | verbose | NOT version |
| `-q` | quiet | Suppress config summary |
| `-d` | debug | Debug output |
| `-o` | output | Output destination |
| `-f` | Available | Package-specific |

### ConfigSummary Integration

All commands display config summary to stderr unless `--quiet`:

```
$ ace-review --preset pr
Config: preset=pr model=claude-sonnet-4.5 format=markdown
...
```

### Thor CLI Template

```ruby
class CLI < Thor
  class_option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary"
  class_option :verbose, type: :boolean, aliases: "-v", desc: "Detailed output"
  class_option :debug, type: :boolean, aliases: "-d", desc: "Debug information"

  desc "command [ARGS]", "Short description"
  long_desc <<~DESC
    Detailed description.

    EXAMPLES:
      $ ace-tool command arg
      $ ace-tool command --option value
  DESC
  def command(arg = nil)
    Ace::Core::ConfigSummary.display(...) unless options[:quiet]
    require_relative "commands/command_command"
    Commands::CommandCommand.new(arg, options).execute
  end
end
```

---

## Migration Priority

### Tier 1: Simple (S) - Start Here
1. **ace-git-commit** - Single command, clear options
2. **ace-nav** - Clean structure, single flow

### Tier 2: Medium (M)
3. **ace-llm** - Provider syntax, moderate complexity
4. **ace-context** - Multiple modes, auto-format
5. **ace-git-worktree** - Already has Commands pattern
6. **ace-search** - Many options, preset system

### Tier 3: Complex (L) - Lessons Learned
7. **ace-review** - Subcommand, multi-model, arrays
8. **ace-taskflow** - 12+ subcommands, central tool
9. **ace-test-runner** - Complex parsing, special exit

---

## Success Metrics

After standardization:
- 100% Thor compliance (14/14 packages)
- Consistent `--quiet`, `--verbose`, `--debug` across all CLIs
- ConfigSummary output on all commands
- Auto-generated help via Thor
- Unified `--format` / `--output` patterns
- All tests passing (no exit code issues)

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking scripts | Keep all option names identical |
| Thor learning curve | Reference implementations available |
| Complex positional args | Keep specialized parsers where needed |
| Test failures | Each subtask runs full test suite |

---

## References

- **ADR-018**: Thor CLI Commands Pattern
- **Tool docs**: `_current/usage/ace-*.md`
- **Reference CLIs**: ace-git, ace-prompt, ace-lint
