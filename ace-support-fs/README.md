---
doc-type: user
title: ace-support-fs
purpose: Documentation for ace-support-fs/README.md
ace-docs:
  last-updated: 2025-12-29
  last-checked: 2026-03-21
---

# ace-support-fs

Filesystem utilities for ace-* gems. Provides unified path expansion, project root detection, and directory traversal functionality.

## Installation

Add to your gemspec:

```ruby
spec.add_dependency "ace-support-fs", "~> 0.1"
```

## Components

### PathExpander (Atom)

Path expansion with protocol URIs, environment variables, and relative path support.

```ruby
require "ace/support/fs"

# Factory methods for context-aware resolution
expander = Ace::Support::Fs::Atoms::PathExpander.for_file("config/settings.yml", project_root: "/app")
expander.resolve("./local.yml")     # => "/app/config/local.yml"
expander.resolve("lib/models")      # => "/app/lib/models"
expander.resolve("$HOME/.config")   # => "/Users/you/.config"

# CLI context (current directory)
expander = Ace::Support::Fs::Atoms::PathExpander.for_cli
expander.resolve("./relative")      # => "{cwd}/relative"

# Stateless class methods
Ace::Support::Fs::Atoms::PathExpander.expand("$HOME/file")     # => "/Users/you/file"
Ace::Support::Fs::Atoms::PathExpander.protocol?("wfi://test")  # => true
Ace::Support::Fs::Atoms::PathExpander.join("a", "b", "c")      # => "a/b/c"
```

### ProjectRootFinder (Molecule)

Detect project root directory by looking for marker files (.git, Gemfile, etc).

```ruby
require "ace/support/fs"

# Find project root from current directory
finder = Ace::Support::Fs::Molecules::ProjectRootFinder.new
finder.find           # => "/path/to/project" or nil
finder.find_or_current  # => "/path/to/project" or Dir.pwd
finder.in_project?    # => true/false

# Class methods for convenience
Ace::Support::Fs::Molecules::ProjectRootFinder.find
Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current

# Custom markers and start path
finder = Ace::Support::Fs::Molecules::ProjectRootFinder.new(
  markers: %w[.git package.json],
  start_path: "/some/path"
)
```

### DirectoryTraverser (Molecule)

Find configuration directories in the directory hierarchy.

```ruby
require "ace/support/fs"

# Find .ace directories from current to project root
traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new
traverser.traverse                   # => ["/deep/path", "/path"] (dirs with .ace)
traverser.find_config_directories    # => ["/deep/path/.ace", "/path/.ace"]
traverser.directory_hierarchy        # => All directories from cwd to root
traverser.build_cascade_priorities   # => {"/deep/.ace" => 0, "/path/.ace" => 10, ...}

# Custom config directory name
traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new(config_dir: ".myconfig")
```

## Environment Variables

- `PROJECT_ROOT_PATH` - Override project root detection with explicit path

## Thread Safety

All components are thread-safe with proper mutex synchronization for shared state (cache, protocol resolver).

## License

See LICENSE.txt
