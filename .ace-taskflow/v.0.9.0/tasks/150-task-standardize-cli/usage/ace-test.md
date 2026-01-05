# ace-test CLI Interface

## Current Implementation

- **Framework**: OptionParser (complex with CliArgumentParser molecule)
- **Entry Point**: `ace-test-runner/exe/ace-test`
- **Lines of Code**: 312
- **Migration Needed**: Yes

## Commands

### Default (test)

Run tests with intelligent argument parsing.

**Usage**: `ace-test [package] [target] [options] [files...]`

**Positional Arguments**:
- **Package** (optional): `ace-*`, `./path`, `/path`
- **Target** (optional): atoms, molecules, organisms, models, unit, integration, system, all, quick
- **Files**: `test/file.rb` or `test/file.rb:42` (line number)

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--format FORMAT` | `-f` | enum | progress, progress-file, json |
| `--report-dir DIR` | `-d` | string | Report storage directory |
| `--no-save` | | flag | Skip saving reports |
| `--fail-fast` | | flag | Stop on first failure |
| `--fix-deprecations` | | flag | Auto-fix deprecated patterns |
| `--filter PATTERN` | | string | Run tests matching pattern |
| `--group GROUP` | `-g` | string | Specific test group |
| `--verbose` | `-v` | flag | Detailed output |
| `--[no-]color` | | boolean | Colored output (default: true) |
| `--config FILE` | `-c` | string | Configuration file |
| `--timeout SECONDS` | | integer | Timeout for execution |
| `--parallel` | | flag | Run in parallel (experimental) |
| `--per-file` | | flag | Execute each file separately |
| `--direct` | | flag | Force in-process execution |
| `--subprocess` | | flag | Force subprocess execution |
| `--max-display N` | | integer | Max failures to display |
| `--profile [N]` | | integer | Show N slowest tests |
| `--cleanup-reports` | | flag | Clean up old reports |
| `--cleanup-keep N` | | integer | Reports to keep |
| `--cleanup-age DAYS` | | integer | Delete older reports |
| `--set-default-rake-test` | | flag | Set ace-test as rake default |
| `--unset-default-rake-test` | | flag | Remove ace-test as rake default |
| `--check-rake-test` | | flag | Check rake integration |
| `--help` | `-h` | flag | Show help |
| `--version` | | flag | Show version |

**Examples**:
```bash
ace-test                         # Run all tests
ace-test atoms                   # Run atom tests only
ace-test ace-context             # Run tests in ace-context
ace-test ace-nav atoms           # Run atom tests in ace-nav
ace-test test/foo_test.rb        # Run specific file
ace-test test/foo_test.rb:42     # Run test at line
ace-test --profile 20            # Show 20 slowest tests
ace-test --fail-fast --verbose   # Stop on first failure
ace-test --cleanup-reports       # Clean old reports
```

## CliArgumentParser

Complex argument parsing that disambiguates:
- Packages (ace-*, paths)
- Targets (atoms, molecules, etc.)
- Files (test/*.rb, file.rb:42)
- Patterns

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/test_runner/cli.rb
class CLI < Thor
  desc "run [PACKAGE] [TARGET]", "Run tests"
  option :format, type: :string, aliases: "-f", enum: %w[progress progress-file json]
  option :report_dir, type: :string, aliases: "-d"
  option :save_reports, type: :boolean, default: true
  option :fail_fast, type: :boolean
  option :fix_deprecations, type: :boolean
  option :filter, type: :string
  option :group, type: :string, aliases: "-g"
  option :verbose, type: :boolean, aliases: "-v"
  option :color, type: :boolean, default: true
  option :config_path, type: :string, aliases: "-c"
  option :timeout, type: :numeric
  option :parallel, type: :boolean
  option :per_file, type: :boolean
  option :direct, type: :boolean
  option :subprocess, type: :boolean
  option :max_display, type: :numeric
  option :profile, type: :numeric
  option :quiet, type: :boolean, aliases: "-q"
  def run(*args)
    require_relative "commands/run_command"
    Commands::RunCommand.new(args, options).execute
  end
  default_task :run

  desc "cleanup", "Clean up old test reports"
  option :keep, type: :numeric, default: 10
  option :age, type: :numeric, default: 30
  def cleanup
    require_relative "commands/cleanup_command"
    Commands::CleanupCommand.new(options).execute
  end

  desc "rake ACTION", "Manage rake integration"
  def rake(action)
    require_relative "commands/rake_command"
    Commands::RakeCommand.new(action, options).execute
  end

  desc "fix", "Auto-fix deprecated test patterns"
  def fix
    require_relative "commands/fix_command"
    Commands::FixCommand.new(options).execute
  end
end
```

### Migration Notes

- Complex migration due to:
  - CliArgumentParser for positional arg disambiguation
  - Multiple operation modes (test, cleanup, rake, fix)
  - Special exit handling (`exit!` vs `exit`)
- Keep CliArgumentParser molecule - use in RunCommand
- Split into explicit commands: run, cleanup, rake, fix
- Preserve `exit!` behavior for Minitest compatibility
- Thor varargs (`*args`) for flexible positional handling
- Add ConfigSummary integration
