# PathExpander Usage Documentation

## Overview

The `Ace::Core::Atoms::PathExpander` class provides unified path resolution for all ACE tools with automatic context inference:

- **Instance-based API**: Create expander for a source file, resolve multiple paths without repeating context
- **Automatic context inference**: source_dir and project_root inferred from source file
- **Protocol URIs**: wfi://, guide://, tmpl://, task://, prompt://
- **Context-aware resolution**: Source-relative (./) vs project-relative paths
- **Environment variable expansion**: $VAR, ${VAR}
- **Backward compatibility**: Class methods preserved for utilities

## Quick Start

### For Source Documents (Config, Workflow, Template, Prompt)

```ruby
# Create expander with inferred context
config_path = ".ace/nav/protocols/ace-nav.yml"
expander = PathExpander.for_file(config_path)

# Resolve multiple paths - context inferred once!
expander.resolve("./handbook/agents/")      # Source-relative
expander.resolve("ace-docs/README.md")       # Project-relative
expander.resolve("wfi://setup")              # Protocol
expander.resolve("$HOME/.ace/custom.md")     # Env var
```

### For CLI Arguments

```ruby
# Create expander for CLI context
expander = PathExpander.for_cli

# Resolve CLI argument path
cli_path = ARGV[0]
resolved = expander.resolve(cli_path)
```

## API Reference

### Factory Methods

#### `PathExpander.for_file(source_file)` - Primary Factory

**Purpose**: Create expander with context inferred from source file

**Behavior**:
- Automatically sets `source_dir` to directory of source file
- Automatically detects `project_root` via ProjectRootFinder
- Returns instance ready to resolve paths

**Usage**:
```ruby
# For config file
expander = PathExpander.for_file(".ace/nav/config.yml")

# For workflow file
expander = PathExpander.for_file("handbook/workflow-instructions/commit.wf.md")

# For any source document
expander = PathExpander.for_file(document_path)
```

#### `PathExpander.for_cli()` - CLI Factory

**Purpose**: Create expander for CLI context (no source file)

**Behavior**:
- Uses `Dir.pwd` as `source_dir`
- Automatically detects `project_root` via ProjectRootFinder
- Returns instance ready to resolve CLI argument paths

**Usage**:
```ruby
expander = PathExpander.for_cli
resolved = expander.resolve(ARGV[0])
```

### Instance Methods

#### `#resolve(path)` - Resolve Path

**Purpose**: Resolve path using instance's inferred context

**Behavior**:
- Source-relative (./, ../): Resolves from `source_dir`
- Project-relative (no prefix): Resolves from `project_root`
- Absolute paths: Returns expanded absolute path
- Protocol URIs: Delegates to registered resolver
- Environment variables: Expands $VAR and ${VAR}

**Usage**:
```ruby
expander = PathExpander.for_file(config_path)

# Various path types
expander.resolve("./local/file.md")        # => "/config/dir/local/file.md"
expander.resolve("docs/global.md")          # => "/project/root/docs/global.md"
expander.resolve("/absolute/path")          # => "/absolute/path"
expander.resolve("wfi://setup")             # => Delegates to ace-nav
expander.resolve("$HOME/.ace/custom.md")    # => "/Users/user/.ace/custom.md"
```

#### `#source_dir` - Get Source Directory

**Purpose**: Access the inferred source directory

```ruby
expander = PathExpander.for_file(".ace/nav/config.yml")
expander.source_dir  # => "/project/.ace/nav"
```

#### `#project_root` - Get Project Root

**Purpose**: Access the detected project root

```ruby
expander = PathExpander.for_file(config_path)
expander.project_root  # => "/project"
```

### Class Methods (Utilities & Backward Compatibility)

#### `PathExpander.expand(path)` - Simple Expansion

**Purpose**: Stateless expansion with tilde and environment variables only (backward compatible)

**Usage**:
```ruby
# Tilde expansion
PathExpander.expand("~/docs")
# => "/Users/username/docs"

# Environment variable expansion
PathExpander.expand("$HOME/project")
# => "/Users/username/project"
```

**When to use**: Quick stateless expansion without context awareness or protocols

#### `PathExpander.protocol?(path)` - Protocol Detection

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

### Scenario 1: Document Loading (ace-nav, ace-docs, ace-taskflow)

**Goal**: Load documents (config files, workflows, templates) with paths that should resolve relative to the source document location

**Command**: Load protocol sources from config file
```ruby
# In .ace/nav/protocols/ace-nav.yml:
# name: ace-nav
# path: ./handbook/workflow-instructions/
# type: directory

# In ConfigLoader:
config_path = ".ace/nav/protocols/ace-nav.yml"
config_data = YAML.load_file(config_path)

# Create expander with inferred context
expander = PathExpander.for_file(config_path)

# Resolve path - context already inferred!
resolved_path = expander.resolve(config_data['path'])
# => "/project/.ace/nav/handbook/workflow-instructions/"
```

**Expected Output**: Absolute path resolved correctly from source document location

### Scenario 2: Multiple Paths from Same Document (ace-docs, ace-context)

**Goal**: Resolve multiple paths from a preset configuration efficiently

**Command**: Load documentation files from preset configuration
```ruby
# In preset configuration file at /project/.ace/context/presets/project.yml:
# files:
#   - "docs/architecture.md"
#   - "ace-docs/README.md"
#   - "./local/custom.md"
#   - "wfi://load-context"

preset_path = ".ace/context/presets/project.yml"
preset_config = YAML.load_file(preset_path)

# Create expander once - context inferred from preset file
expander = PathExpander.for_file(preset_path)

# Resolve multiple paths - NO repeated context!
preset_config['files'].each do |file_path|
  resolved_path = expander.resolve(file_path)
  load_file(resolved_path)
end
# Results:
# => "/project/docs/architecture.md"              (project-relative)
# => "/project/ace-docs/README.md"                (project-relative)
# => "/project/.ace/context/presets/local/custom.md"  (source-relative)
# => "/project/handbook/wfi/load-context.wf.md"  (protocol via ace-nav)
```

**Expected Output**: All paths resolved correctly, context inferred only once

### Scenario 3: Protocol Resolution (ace-context, ace-docs)

**Goal**: Use protocol URIs in config files that resolve via ace-nav

**Command**: Load workflow via protocol
```ruby
# In context preset at /project/.ace/context/presets/base.yml:
# sources:
#   - "wfi://load-context"
#   - "guide://testing"

preset_path = ".ace/context/presets/base.yml"
preset_config = YAML.load_file(preset_path)

# Create expander with inferred context
expander = PathExpander.for_file(preset_path)

# In ContextLoader (after ace-nav registration):
preset_config['sources'].each do |source_uri|
  if PathExpander.protocol?(source_uri)
    result = expander.resolve(source_uri)
    if result[:success]
      # Load from result[:path]
    else
      # Handle error: result[:error]
    end
  else
    # Regular path resolution
    resolved = expander.resolve(source_uri)
    # Load from resolved path
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

### Scenario 5: Error Handling - Missing Context

**Goal**: Validation error when required parameters are nil

**Command**: Attempt to create instance with nil parameters
```ruby
# Both parameters nil - raises ArgumentError
begin
  PathExpander.new(source_dir: nil, project_root: nil)
rescue ArgumentError => e
  puts e.message
  # => "PathExpander requires both source_dir and project_root"
end

# One parameter nil - also raises ArgumentError
begin
  PathExpander.new(source_dir: "/dir", project_root: nil)
rescue ArgumentError => e
  puts e.message
  # => "PathExpander requires both source_dir and project_root"
end
```

**Expected Output**: Clear validation error on initialization

**Note**: Factory methods (`for_file`, `for_cli`) handle context inference, so this error only occurs with direct `new()` usage

### Scenario 5b: Error Handling - Protocol Without Resolver

**Goal**: Graceful error when protocol used but ace-nav not loaded

**Command**: Use protocol without ace-nav
```ruby
expander = PathExpander.for_file(config_path)

result = expander.resolve("wfi://setup")

if result.is_a?(Hash) && !result[:success]
  puts result[:error]
  # => "Protocol 'wfi' not supported. Please ensure ace-nav is loaded and registered."
end
```

**Expected Output**: Clear error message guiding user to solution

### Scenario 6: Mixed Path Types in Document

**Goal**: Handle documents with multiple path format styles

**Command**: Process various path formats from a config file
```ruby
# Config file at /project/.ace/nav/config.yml with mixed paths:
# paths:
#   - "./local/file.md"           # Source-relative
#   - "docs/global.md"            # Project-relative
#   - "wfi://setup"               # Protocol
#   - "$HOME/.ace/custom.md"      # Env var

config_path = "/project/.ace/nav/config.yml"
config = YAML.load_file(config_path)

# Create expander once
expander = PathExpander.for_file(config_path)

# Resolve all paths with single expander instance
config['paths'].each do |path|
  resolved = expander.resolve(path)
  # Handle resolved path or error
end

# Results:
# => "/project/.ace/nav/local/file.md"           (source-relative)
# => "/project/docs/global.md"                   (project-relative)
# => { success: true, path: "/project/.ace/handbook/wfi/setup.wf.md" } (protocol)
# => "/Users/username/.ace/custom.md"            (env var)
```

**Expected Output**: All path types resolve correctly using same expander instance

### Scenario 7: CLI Argument Path Resolution

**Goal**: Resolve paths from CLI arguments where there's no source document

**Command**: Process CLI path argument
```ruby
# User runs: ace-context ./presets/custom.yml

cli_path = ARGV[0]  # => "./presets/custom.yml"

# Create expander for CLI context (uses Dir.pwd as source_dir)
expander = PathExpander.for_cli

# Resolve the CLI argument
resolved_path = expander.resolve(cli_path)
# => "/current/working/dir/presets/custom.yml"
```

**Expected Output**: CLI paths resolve relative to current directory

## Command Reference

### Ruby API

**Instance-Based API (Preferred)**:
```ruby
# Create expander for source document
expander = PathExpander.for_file(source_file_path)

# Create expander for CLI
expander = PathExpander.for_cli

# Resolve paths using instance
resolved = expander.resolve(path)

# Access inferred context
expander.source_dir      # => "/path/to/source/dir"
expander.project_root    # => "/path/to/project"
```

**Class Methods (Utilities & Backward Compatibility)**:
```ruby
# Simple stateless expansion
PathExpander.expand(path)

# Protocol detection
PathExpander.protocol?(path)  # => true/false

# Protocol resolver registration
PathExpander.register_protocol_resolver(resolver_object)

# Other utilities
PathExpander.join(*parts)
PathExpander.dirname(path)
PathExpander.basename(path, suffix = nil)
PathExpander.absolute?(path)
PathExpander.relative(path, base)
PathExpander.normalize(path)
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

### Instance Creation

**DO**: Create expander once per source document, reuse for multiple paths
```ruby
# ✅ Efficient - context inferred once
expander = PathExpander.for_file(config_path)
config['paths'].each { |path| expander.resolve(path) }
```

**DON'T**: Create new expander for every path
```ruby
# ❌ Inefficient - repeated context inference
config['paths'].each do |path|
  expander = PathExpander.for_file(config_path)  # Wasteful!
  expander.resolve(path)
end
```

### Document Path Resolution

**DO**: Use ./ prefix for paths relative to source document
```ruby
# In .ace/nav/protocols/source.yml
path: ./handbook/agents/  # ✅ Resolves from source document directory
```

**DON'T**: Use ./ for project-relative paths
```ruby
path: ./ace-docs/README.md  # ❌ Resolves from source dir, not project
path: ace-docs/README.md    # ✅ Resolves from project root
```

### Protocol Usage

**DO**: Check if protocol is available and handle errors
```ruby
if PathExpander.protocol?(path)
  result = expander.resolve(path)
  if result[:success]
    # Use result[:path]
  else
    # Handle result[:error]
  end
else
  # Regular path resolution
  resolved = expander.resolve(path)
end
```

**DON'T**: Assume all protocols will resolve without checking
```ruby
# ❌ May return error hash if protocol resolver not available
result = expander.resolve("wfi://setup")
File.read(result)  # Error! result might be a Hash, not a String
```

### Environment Variables

**DO**: Provide fallbacks for optional env vars
```ruby
# Using class method for simple expansion
cache_dir = PathExpander.expand(config['cache_dir'] || ".cache")
```

**DON'T**: Rely on env vars being set
```ruby
# ❌ Will leave literal string if env var not set
path = PathExpander.expand("$PROJECT_ROOT/docs")
```

### Factory Method Usage

**DO**: Use `for_file()` for documents, `for_cli()` for CLI arguments
```ruby
# ✅ For config/workflow/template files
expander = PathExpander.for_file(document_path)

# ✅ For CLI arguments
expander = PathExpander.for_cli
```

**DON'T**: Use direct `new()` unless you need explicit control
```ruby
# ❌ Unnecessary - factory methods handle this
expander = PathExpander.new(
  source_dir: File.dirname(path),
  project_root: ProjectRootFinder.find
)

# ✅ Let factory do the work
expander = PathExpander.for_file(path)
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

**Issue**: Source-relative paths resolving from wrong directory

**Solution**: Verify you're using correct factory method
```ruby
# ✅ For source documents - uses document's directory
expander = PathExpander.for_file(document_path)

# ✅ For CLI - uses current working directory
expander = PathExpander.for_cli
```

### ArgumentError: PathExpander requires both parameters

**Issue**: Missing required parameters in direct `new()` call

**Solution**: Use factory methods instead of direct instantiation
```ruby
# ❌ Error-prone - manual parameter management
expander = PathExpander.new(source_dir: dir, project_root: root)

# ✅ Preferred - automatic context inference
expander = PathExpander.for_file(document_path)
expander = PathExpander.for_cli
```

### Resolved path is wrong type (Hash instead of String)

**Issue**: Protocol resolution returned error hash, code expected string

**Solution**: Check if path is protocol and handle both return types
```ruby
resolved = expander.resolve(path)

if resolved.is_a?(Hash)
  # Protocol resolution - check success
  if resolved[:success]
    File.read(resolved[:path])
  else
    handle_error(resolved[:error])
  end
else
  # Regular path - string result
  File.read(resolved)
end
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
config_path = ".ace/nav/config.yml"
config = YAML.load_file(config_path)

config['paths'].each do |path|
  resolved = File.expand_path(path, File.dirname(config_path))
  # Process resolved path
end
```

**New**:
```ruby
config_path = ".ace/nav/config.yml"
config = YAML.load_file(config_path)

# Create expander once
expander = PathExpander.for_file(config_path)

# Resolve multiple paths efficiently
config['paths'].each do |path|
  resolved = expander.resolve(path)
  # Process resolved path
end
```

### From Manual Context Management

**Legacy**:
```ruby
# Repeated context construction
config['files'].each do |file|
  context = {
    source_dir: File.dirname(config_path),
    project_root: ProjectRootFinder.find
  }
  resolved = some_resolver(file, context)
end
```

**New**:
```ruby
# Context inferred once
expander = PathExpander.for_file(config_path)
config['files'].each do |file|
  resolved = expander.resolve(file)
end
```

### From Manual Protocol Checking

**Legacy**:
```ruby
if path.include?("://")
  # Call ace-nav manually
  resolved = AceNav.resolve(path)
else
  # Expand path manually
  resolved = File.expand_path(path)
end
```

**New**:
```ruby
# PathExpander handles both automatically
expander = PathExpander.for_file(source_file)
resolved = expander.resolve(path)
# Works for both protocols and regular paths
```

## Performance Considerations

- **Instance creation**: < 1ms (factory methods with context inference)
- **Protocol detection**: < 1ms (regex pattern match on class method)
- **Path resolution**: < 5ms per path (stdlib operations)
- **Protocol resolution**: < 100ms (delegates to ace-nav caching)
- **Instance reuse**: No overhead for multiple resolve() calls on same instance

**Best Practice**: Create expander instance once per source document, reuse for all paths from that document.

```ruby
# ✅ Efficient - one context inference, many resolutions
expander = PathExpander.for_file(config_path)
config['100_paths'].each { |path| expander.resolve(path) }  # ~0.5s total

# ❌ Inefficient - repeated context inference
config['100_paths'].each do |path|
  PathExpander.for_file(config_path).resolve(path)  # ~10s total
end
```
