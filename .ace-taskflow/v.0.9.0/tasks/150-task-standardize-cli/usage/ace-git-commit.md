# ace-git-commit CLI Interface

## Current Implementation

- **Framework**: OptionParser (custom, in exe)
- **Entry Point**: `ace-git-commit/exe/ace-git-commit`
- **Lines of Code**: 128
- **Migration Needed**: Yes

## Commands

### Default (commit)

Generate and execute git commit with LLM-generated messages.

**Usage**: `ace-git-commit [options] [files...]`

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--intention INTENTION` | `-i` | string | Provide context for LLM message generation |
| `--message MESSAGE` | `-m` | string | Use provided message directly (no LLM) |
| `--model MODEL` | | string | Override default LLM model (e.g., glite, gflash) |
| `--only-staged` | `-s` | flag | Commit only staged changes |
| `--dry-run` | `-n` | flag | Show what would be committed |
| `--debug` | `-d` | flag | Enable debug output |
| `--verbose` | | flag | Enable verbose output |
| `--quiet` | `-q` | flag | Suppress informational messages |
| `--force` | `-f` | flag | Force operation |
| `--help` | `-h` | flag | Show help |
| `--version` | `-v` | flag | Show version |

**Examples**:
```bash
ace-git-commit                              # Generate message for all changes
ace-git-commit -i 'fix auth bug'            # Generate with intention
ace-git-commit -m 'feat: add feature'       # Use specific message
ace-git-commit src/auth.rb                  # Commit specific file
ace-git-commit lib/ test/                   # Commit directories
ace-git-commit '**/*.rb'                    # Commit matching glob pattern
ace-git-commit --only-staged                # Commit only staged changes
ace-git-commit --model gflash -i 'refactor' # Use different model
```

## Path Behavior

- Supports files, directories, and glob patterns (*, ?, [], {})
- When paths provided: resets staging, stages only matching files, commits
- Glob patterns expanded to git-tracked files only

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/git_commit/cli.rb
class CLI < Thor
  desc "commit [FILES...]", "Generate and execute git commit"
  option :intention, type: :string, aliases: "-i", desc: "Context for LLM message generation"
  option :message, type: :string, aliases: "-m", desc: "Use message directly (no LLM)"
  option :model, type: :string, desc: "Override default LLM model"
  option :only_staged, type: :boolean, aliases: "-s", desc: "Commit only staged changes"
  option :dry_run, type: :boolean, aliases: "-n", desc: "Show what would be committed"
  option :debug, type: :boolean, aliases: "-d", desc: "Enable debug output"
  option :verbose, type: :boolean, desc: "Enable verbose output"
  option :quiet, type: :boolean, aliases: "-q", desc: "Suppress informational messages"
  option :force, type: :boolean, aliases: "-f", desc: "Force operation"
  def commit(*files)
    require_relative "commands/commit_command"
    Commands::CommitCommand.new(files, options).execute
  end
  default_task :commit
end
```

### Migration Notes

- Simple migration: single command with options
- Move CLI class from exe to lib/ace/git_commit/cli.rb
- Create CommitCommand class to wrap CommitOrchestrator
- Thor handles varargs (`*files`) naturally
- Add ConfigSummary integration before orchestrator call
