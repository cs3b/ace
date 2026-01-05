# ace-context CLI Interface

## Current Implementation

- **Framework**: OptionParser (custom)
- **Entry Point**: `ace-context/exe/ace-context`
- **Lines of Code**: 224
- **Migration Needed**: Yes

## Commands

### Default (load context)

Load context from presets, files, or protocol URLs.

**Usage**: `ace-context [INPUT] [options]`

**INPUT types**:
- Preset name (e.g., `project`, `base`)
- File path (e.g., `/path/to/config.yml`, `./context.md`)
- Protocol URL (e.g., `wfi://workflow`, `guide://testing`)

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--preset NAME` | `-p` | string | Load from preset (repeatable) |
| `--presets NAMES` | | string | Load multiple presets (comma-separated) |
| `--file FILE` | `-f` | string | Load from file (repeatable) |
| `--inspect-config` | | flag | Show merged config without execution |
| `--embed-source` | `-e` | flag | Embed source document in output |
| `--list` | `-l` | flag | List available presets |
| `--output MODE` | `-o` | string | Output mode: stdio, cache, file path |
| `--format FORMAT` | | enum | markdown, yaml, xml, markdown-xml, json |
| `--max-size BYTES` | | integer | Maximum file size (default: 1MB) |
| `--timeout SECONDS` | | integer | Command timeout (default: 30) |
| `--debug` | `-d` | flag | Enable debug output |
| `--help` | `-h` | flag | Show help |
| `--version` | `-v` | flag | Show version |

**Examples**:
```bash
ace-context                          # Load default preset
ace-context project                  # Load project preset
ace-context wfi://create-task        # Load via protocol URL
ace-context -p base -p custom        # Load and merge multiple presets
ace-context project --output stdio   # Output to stdout
ace-context project --output cache   # Save to cache
ace-context --embed-source           # Embed source in output
ace-context --list-presets           # List available presets
```

## Output Behavior

- **stdio**: Print to stdout
- **cache**: Save to `.cache/ace-context/[name].md`
- **file path**: Save to specified file
- **Auto-format**: Based on line count threshold (uses cache for large output)

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/context/cli.rb
class CLI < Thor
  desc "load [INPUT]", "Load context from preset, file, or protocol"
  option :preset, type: :string, repeatable: true, aliases: "-p"
  option :file, type: :string, repeatable: true, aliases: "-f"
  option :output, type: :string, aliases: "-o"
  option :format, type: :string, enum: %w[markdown yaml xml markdown-xml json]
  option :embed_source, type: :boolean, aliases: "-e"
  option :quiet, type: :boolean, aliases: "-q"
  def load(input = nil)
    require_relative "commands/load_command"
    Commands::LoadCommand.new(input, options).execute
  end
  default_task :load

  desc "list", "List available presets"
  def list
    require_relative "commands/list_command"
    Commands::ListCommand.new(options).execute
  end

  desc "inspect [INPUT]", "Inspect configuration without execution"
  def inspect(input = nil)
    require_relative "commands/inspect_command"
    Commands::InspectCommand.new(input, options).execute
  end
end
```

### Migration Notes

- Convert OptionParser to Thor options
- Split into 3 commands: `load` (default), `list`, `inspect`
- Move output mode logic to LoadCommand
- Add `--quiet` flag for ConfigSummary suppression
- Handle repeatable options (--preset, --file) using Thor arrays
