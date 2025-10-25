# PathExpander Usage Documentation

## Overview

The enhanced `Ace::Core::Atoms::PathExpander` provides unified path resolution for all ACE tools, supporting:

- Protocol URIs (wfi://, guide://, tmpl://, task://, prompt://)
- Context-aware path resolution (config-relative vs project-relative)
- Environment variable expansion ($VAR, ${VAR})
- Backward compatibility with existing usage

## Available Methods

### `PathExpander.expand(path)` - Basic Expansion

**Purpose**: Expand path with tilde and environment variables (existing behavior, unchanged)

**Usage**:
```ruby
# Tilde expansion
PathExpander.expand("~/docs")
# => "/Users/username/docs"

# Environment variable expansion
PathExpander.expand("$HOME/project")
# => "/Users/username/project"

# Absolute path (unchanged)
PathExpander.expand("/absolute/path")
# => "/absolute/path"

# Relative path expansion
PathExpander.expand("./relative")
# => "/current/working/directory/relative"
```

**When to use**: For simple path expansion without protocol support or context awareness.

### `PathExpander.expand_with_context(path:, context: {})` - Context-Aware Resolution

**Purpose**: Resolve paths with awareness of config file location and project root

**Context Parameters**:
- `config_file_dir`: Directory containing the config file (for ./ ../ resolution)
- `project_root`: Project root directory (for project-relative resolution)

**Usage**:
```ruby
# Config-relative path (starts with ./ or ../)
PathExpander.expand_with_context(
  path: "./handbook/agents/",
  context: { config_file_dir: "/project/.ace/nav" }
)
# => "/project/.ace/nav/handbook/agents/"

# Project-relative path (no ./ prefix)
PathExpander.expand_with_context(
  path: "ace-docs/README.md",
  context: { project_root: "/project" }
)
# => "/project/ace-docs/README.md"

# Parent directory reference
PathExpander.expand_with_context(
  path: "../templates/task.md",
  context: { config_file_dir: "/project/.ace/nav/protocols" }
)
# => "/project/.ace/nav/templates/task.md"
```

**When to use**: When loading config files and need to resolve relative paths correctly.

### `PathExpander.protocol?(path)` - Protocol Detection

**Purpose**: Check if a path is a protocol URI

**Usage**:
```ruby
PathExpander.protocol?("wfi://setup")      # => true
PathExpander.protocol?("guide://testing")  # => true
PathExpander.protocol?("./relative/path")  # => false
PathExpander.protocol?("/absolute/path")   # => false
PathExpander.protocol?("http://example")   # => true (but won't resolve)
```

**When to use**: To conditionally handle protocol URIs vs regular paths.

### `PathExpander.register_protocol_resolver(resolver)` - Protocol Integration

**Purpose**: Register a protocol resolver (typically ace-nav) for protocol URI resolution

**Resolver Interface**:
```ruby
# Resolver must respond to #resolve(uri) and return:
# - Success: { success: true, path: "/absolute/path/to/file" }
# - Failure: { success: false, error: "Error message" }

module MyProtocolResolver
  def self.resolve(uri)
    # Resolution logic here
    { success: true, path: "/resolved/path" }
  end
end

PathExpander.register_protocol_resolver(MyProtocolResolver)
```

**When to use**: During ace-nav initialization to enable protocol resolution.

## Usage Scenarios

### Scenario 1: Config File Loading (ace-nav, ace-docs, ace-taskflow)

**Goal**: Load config files with paths that should resolve relative to the config file location

**Command**: Load protocol sources from config file
```ruby
# In .ace/nav/protocols/ace-nav.yml:
# name: ace-nav
# path: ./handbook/workflow-instructions/
# type: directory

# In ConfigLoader:
config_data = YAML.load_file(config_path)
source_path = config_data['path']

# Resolve relative to config file directory
resolved_path = PathExpander.expand_with_context(
  path: source_path,
  context: {
    config_file_dir: File.dirname(config_path),
    project_root: Ace::Core::Molecules::ProjectRootFinder.find
  }
)
# => "/project/.ace/nav/handbook/workflow-instructions/"
```

**Expected Output**: Absolute path resolved correctly from config file location

### Scenario 2: Project-Relative Paths (ace-docs, ace-context)

**Goal**: Reference documents relative to project root without ./ prefix

**Command**: Load documentation files
```ruby
# In preset configuration:
# files:
#   - "docs/architecture.md"
#   - "ace-docs/README.md"

preset_config['files'].each do |file_path|
  resolved_path = PathExpander.expand_with_context(
    path: file_path,
    context: { project_root: Ace::Core::Molecules::ProjectRootFinder.find }
  )
  # Load file from resolved_path
end
# => "/project/docs/architecture.md"
# => "/project/ace-docs/README.md"
```

**Expected Output**: Files loaded from project root

### Scenario 3: Protocol Resolution (ace-context, ace-docs)

**Goal**: Use protocol URIs in config files that resolve via ace-nav

**Command**: Load workflow via protocol
```ruby
# In context preset:
# sources:
#   - "wfi://load-context"
#   - "guide://testing"

# In ContextLoader (after ace-nav registration):
preset_config['sources'].each do |source_uri|
  if PathExpander.protocol?(source_uri)
    result = PathExpander.expand_with_context(
      path: source_uri,
      context: {}
    )
    if result[:success]
      # Load from result[:path]
    else
      # Handle error: result[:error]
    end
  else
    # Regular path handling
  end
end
```

**Expected Output**: Protocol URIs resolve to actual file paths via ace-nav

### Scenario 4: Environment Variable Expansion

**Goal**: Support environment variables in configuration paths

**Command**: Use env vars in config
```ruby
# In config file:
# cache_dir: "$XDG_CACHE_HOME/ace-nav"
# templates_dir: "${PROJECT_ROOT}/templates"

cache_path = PathExpander.expand(config['cache_dir'])
# => "/Users/username/.cache/ace-nav"

templates_path = PathExpander.expand_with_context(
  path: config['templates_dir'],
  context: { project_root: ENV['PROJECT_ROOT'] || Dir.pwd }
)
# => "/project/templates"
```

**Expected Output**: Paths with expanded environment variables

### Scenario 5: Error Handling - Protocol Without Resolver

**Goal**: Graceful error when protocol used but ace-nav not loaded

**Command**: Use protocol without ace-nav
```ruby
result = PathExpander.expand_with_context(
  path: "wfi://setup",
  context: {}
)

if result.is_a?(Hash) && !result[:success]
  puts result[:error]
  # => "Protocol 'wfi' not supported. Please ensure ace-nav is loaded and registered."
end
```

**Expected Output**: Clear error message guiding user to solution

### Scenario 6: Mixed Path Types in Config

**Goal**: Handle config files with multiple path format styles

**Command**: Process various path formats
```ruby
# Config with mixed paths:
# paths:
#   - "./local/file.md"           # Config-relative
#   - "docs/global.md"            # Project-relative
#   - "wfi://setup"               # Protocol
#   - "$HOME/.ace/custom.md"      # Env var

context = {
  config_file_dir: "/project/.ace/nav",
  project_root: "/project"
}

config['paths'].each do |path|
  resolved = PathExpander.expand_with_context(
    path: path,
    context: context
  )
  # Handle resolved path or error
end

# Results:
# => "/project/.ace/nav/local/file.md"
# => "/project/docs/global.md"
# => { success: true, path: "/project/.ace/handbook/wfi/setup.wf.md" }
# => "/Users/username/.ace/custom.md"
```

**Expected Output**: All path types resolve correctly

## Command Reference

### Ruby API

**Basic Expansion**:
```ruby
Ace::Core::Atoms::PathExpander.expand(path)
```

**Context-Aware Resolution**:
```ruby
Ace::Core::Atoms::PathExpander.expand_with_context(
  path: string,
  context: {
    config_file_dir: string,    # Optional
    project_root: string         # Optional
  }
)
```

**Protocol Detection**:
```ruby
Ace::Core::Atoms::PathExpander.protocol?(path)  # => true/false
```

**Protocol Resolver Registration**:
```ruby
Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver_object)
```

### Integration Example (ace-nav)

```ruby
# In ace-nav initialization:
require 'ace/core/atoms/path_expander'
require 'ace/nav/molecules/resource_resolver'

# Create resolver adapter
module AceNavResolver
  def self.resolve(uri)
    resolver = Ace::Nav::Molecules::ResourceResolver.new
    resource = resolver.resolve(uri)

    if resource
      { success: true, path: resource.path }
    else
      { success: false, error: "Protocol '#{uri}' could not be resolved" }
    end
  end
end

# Register with PathExpander
Ace::Core::Atoms::PathExpander.register_protocol_resolver(AceNavResolver)
```

## Tips and Best Practices

### Config File Path Resolution

**DO**: Use ./ prefix for paths relative to config file
```ruby
# In .ace/nav/protocols/source.yml
path: ./handbook/agents/  # ✅ Resolves from config file dir
```

**DON'T**: Use ./ for project-relative paths
```ruby
path: ./ace-docs/README.md  # ❌ Resolves from config dir, not project
path: ace-docs/README.md    # ✅ Resolves from project root
```

### Protocol Usage

**DO**: Check if protocol is available before using
```ruby
if PathExpander.protocol?(path)
  result = PathExpander.expand_with_context(path: path, context: {})
  handle_protocol_result(result)
else
  # Regular path handling
end
```

**DON'T**: Assume all protocols will resolve
```ruby
# ❌ May error if ace-nav not loaded
path = PathExpander.expand_with_context(path: "wfi://setup", context: {})
```

### Environment Variables

**DO**: Provide fallbacks for optional env vars
```ruby
cache_dir = PathExpander.expand(config['cache_dir'] || ".cache")
```

**DON'T**: Rely on env vars being set
```ruby
# ❌ Will fail if PROJECT_ROOT not set
path = PathExpander.expand("$PROJECT_ROOT/docs")
```

### Context Provision

**DO**: Always provide context when loading config files
```ruby
context = {
  config_file_dir: File.dirname(config_path),
  project_root: Ace::Core::Molecules::ProjectRootFinder.find
}
PathExpander.expand_with_context(path: path, context: context)
```

**DON'T**: Use expand_with_context without context
```ruby
# ❌ Context is empty, falls back to less reliable resolution
PathExpander.expand_with_context(path: "./file.md", context: {})
```

## Troubleshooting

### "Protocol not supported" error

**Issue**: Using protocol URI but ace-nav not loaded

**Solution**:
```ruby
# Ensure ace-nav is loaded and registered
require 'ace/nav'
# ace-nav should auto-register during initialization
```

### Paths resolve to wrong location

**Issue**: Config-relative paths resolving from wrong directory

**Solution**: Always provide `config_file_dir` in context
```ruby
context = {
  config_file_dir: File.dirname(config_file_path)  # ✅ Explicit config dir
}
```

### Environment variables not expanding

**Issue**: `$VAR` appearing as literal string

**Solution**: Check env var is actually set
```ruby
ENV['MY_VAR']  # Verify it's set
PathExpander.expand("$MY_VAR/path")  # Will expand if set
```

## Migration Notes

### From Direct File.expand_path

**Legacy**:
```ruby
path = File.expand_path(relative_path, config_dir)
```

**New**:
```ruby
path = PathExpander.expand_with_context(
  path: relative_path,
  context: { config_file_dir: config_dir }
)
```

### From Manual Protocol Checking

**Legacy**:
```ruby
if path.include?("://")
  # Call ace-nav manually
else
  # Expand path
end
```

**New**:
```ruby
PathExpander.expand_with_context(path: path, context: {})
# Handles both protocols and regular paths
```

## Performance Considerations

- **Protocol detection**: < 1ms (regex pattern match)
- **Path expansion**: < 5ms (stdlib operations)
- **Protocol resolution**: < 100ms (delegates to ace-nav caching)
- **No caching overhead**: PathExpander resolves fresh each time

For high-frequency path resolution, consider caching results at application level.
