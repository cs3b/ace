# ace-search CLI Interface

## Current Implementation

- **Framework**: OptionParser (custom, in exe)
- **Entry Point**: `ace-search/exe/ace-search`
- **Lines of Code**: 272
- **Migration Needed**: Yes

## Commands

### Default (search)

Unified file and content search with intelligent pattern matching.

**Usage**: `ace-search [options] PATTERN [SEARCH_PATH]`

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--type TYPE` | `-t` | enum | Search type: file, content, hybrid, auto |
| `--files` | `-f` | flag | Search for files only |
| `--content` | `-c` | flag | Search in file content only |
| `--case-insensitive` | `-i` | flag | Case insensitive search |
| `--whole-word` | `-w` | flag | Match whole words only |
| `--multiline` | `-U` | flag | Enable multiline matching |
| `--hidden` | | flag | Include hidden files |
| `--after NUM` | `-A` | integer | Show NUM lines after match |
| `--before NUM` | `-B` | integer | Show NUM lines before match |
| `--context NUM` | `-C` | integer | Show NUM lines of context |
| `--glob PATTERN` | `-g` | string | File glob pattern to include |
| `--include PATHS` | | string | Include only these paths (comma-separated) |
| `--exclude PATHS` | `-e` | string | Exclude paths (comma-separated) |
| `--since TIME` | | string | Files modified since TIME |
| `--before TIME` | | string | Files modified before TIME |
| `--staged` | | flag | Search staged files only |
| `--tracked` | | flag | Search tracked files only |
| `--changed` | | flag | Search changed files only |
| `--json` | | flag | Output in JSON format |
| `--yaml` | | flag | Output in YAML format |
| `--files-with-matches` | `-l` | flag | Only print filenames |
| `--max-results NUM` | | integer | Limit number of results |
| `--fzf` | | flag | Use fzf for interactive selection |
| `--preset NAME` | `-p` | string | Use search preset |
| `--help` | `-h` | flag | Show help |
| `--version` | | flag | Show version |

**Examples**:
```bash
ace-search "TODO"                       # Auto-detect: search content
ace-search "*.rb" --files               # Find Ruby files
ace-search "class.*Manager" --content   # Regex content search
ace-search "config" --staged            # Search only staged files
ace-search "pattern" --fzf              # Interactive selection
ace-search "api" -p security            # Use security preset
```

## DWIM (Do What I Mean) Pattern

- Auto-detects search type based on pattern
- Glob patterns → file search
- Regex patterns → content search
- Simple terms → hybrid search

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/search/cli.rb
class CLI < Thor
  desc "search PATTERN [PATH]", "Search files and content"
  option :type, type: :string, enum: %w[file content hybrid auto], aliases: "-t"
  option :files, type: :boolean, aliases: "-f", desc: "Search files only"
  option :content, type: :boolean, aliases: "-c", desc: "Search content only"
  option :case_insensitive, type: :boolean, aliases: "-i"
  option :whole_word, type: :boolean, aliases: "-w"
  option :multiline, type: :boolean, aliases: "-U"
  option :hidden, type: :boolean
  option :after_context, type: :numeric, aliases: "-A"
  option :before_context, type: :numeric, aliases: "-B"
  option :context, type: :numeric, aliases: "-C"
  option :glob, type: :string, aliases: "-g"
  option :include, type: :array
  option :exclude, type: :array, aliases: "-e"
  option :since, type: :string
  option :before, type: :string
  option :staged, type: :boolean
  option :tracked, type: :boolean
  option :changed, type: :boolean
  option :json, type: :boolean
  option :yaml, type: :boolean
  option :files_with_matches, type: :boolean, aliases: "-l"
  option :max_results, type: :numeric
  option :interactive, type: :boolean, desc: "Use fzf"
  option :preset, type: :string, aliases: "-p"
  option :quiet, type: :boolean, aliases: "-q"
  def search(pattern, path = nil)
    require_relative "commands/search_command"
    Commands::SearchCommand.new(pattern, path, options).execute
  end
  default_task :search
end
```

### Migration Notes

- Single command with many options
- Convert comma-separated values to Thor arrays (--include, --exclude)
- Preserve DWIM pattern analysis in command class
- Maintain preset merging behavior
- Add ConfigSummary integration
- Move component requires to command class (lazy loading)
