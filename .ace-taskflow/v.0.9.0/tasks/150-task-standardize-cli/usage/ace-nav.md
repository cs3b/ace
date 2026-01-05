# ace-nav CLI Interface

## Current Implementation

- **Framework**: OptionParser (custom CLI class)
- **Entry Point**: `ace-nav/lib/ace/nav/cli.rb`
- **Lines of Code**: 219
- **Migration Needed**: Yes

## Commands

### Default (navigate)

Resource discovery and navigation with protocol support.

**Usage**: `ace-nav <path-or-uri> [options]`

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--path` | | flag | Display resource path |
| `--content` | | flag | Display resource content |
| `--create [PATH]` | | string | Create resource from template |
| `--list` | | flag | List matching resources |
| `--tree` | | flag | Display resources in tree format |
| `--verbose` | | flag | Show detailed information |
| `--sources` | | flag | Show available sources |
| `--help` | `-h` | flag | Show help |
| `--version` | `-v` | flag | Show version |

**Examples**:
```bash
ace-nav wfi://setup                         # Find first matching workflow
ace-nav wfi://@ace-git/setup               # From specific source
ace-nav wfi://setup --content              # Show content
ace-nav 'wfi://*' --list                   # List all workflows
ace-nav wfi://setup --create               # Create from template
ace-nav --sources                          # Show available sources
```

## Protocol Support

- `wfi://` - Workflow instructions
- `tmpl://` - Templates
- `guide://` - Guides
- `prompt://` - Prompts
- `cmd://` - Command delegation

## Magic Behavior

- `protocol://` (empty path) → auto-list with wildcard
- Patterns with `*` or `?` → force list mode
- Patterns ending with `/` → force list mode (prefix pattern)

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/nav/cli.rb
class CLI < Thor
  desc "resolve URI", "Resolve resource path or content"
  option :path, type: :boolean, desc: "Display resource path"
  option :content, type: :boolean, desc: "Display resource content"
  option :verbose, type: :boolean, desc: "Show detailed information"
  option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary"
  def resolve(uri)
    require_relative "commands/resolve_command"
    Commands::ResolveCommand.new(uri, options).execute
  end
  default_task :resolve

  desc "list PATTERN", "List matching resources"
  option :tree, type: :boolean, desc: "Display in tree format"
  option :verbose, type: :boolean, desc: "Show detailed information"
  def list(pattern)
    require_relative "commands/list_command"
    Commands::ListCommand.new(pattern, options).execute
  end

  desc "create URI [TARGET]", "Create resource from template"
  option :verbose, type: :boolean, desc: "Show detailed information"
  def create(uri, target = nil)
    require_relative "commands/create_command"
    Commands::CreateCommand.new(uri, target, options).execute
  end

  desc "sources", "Show available sources"
  option :verbose, type: :boolean, desc: "Show detailed information (JSON)"
  def sources
    require_relative "commands/sources_command"
    Commands::SourcesCommand.new(options).execute
  end
end
```

### Migration Notes

- Split single flow into 4 explicit commands: resolve, list, create, sources
- Handle magic wildcard expansion in resolve command (redirect to list)
- Maintain cmd:// delegation in resolve command
- Add ConfigSummary integration
- Note: Current CLI class (`Cli`) should be renamed to `CLI` for consistency
