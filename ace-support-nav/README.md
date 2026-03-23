# ace-support-nav

Protocol-aware navigation and resource discovery for the ACE ecosystem.

[Use Cases](#use-cases) | [Features](#features) | [Usage](#usage) | [Configuration](#configuration) | [Ruby API](#ruby-api)

`ace-support-nav` powers `ace-nav` resolution behavior across project, user, and gem sources, with consistent URI lookup, override targeting, and fast cached discovery.

## Use Cases

**Resolve ACE resources without memorizing file paths** - use `ace-nav resolve` with protocols like `wfi://`, `guide://`, `tmpl://`, `skill://`, and `task://`.

**Target the right override layer explicitly** - use `@project`, `@user`, or specific gem aliases to bypass cascade ambiguity.

**Discover matching resources quickly** - use wildcard and prefix patterns to list candidate workflows, prompts, templates, and skills.

**Navigate task specs through the same interface** - use `task://` references so task lookup shares the same navigation workflow as handbook resources.

## Works With

- **[ace-task](../ace-task)** for `task://` resolution and task metadata retrieval.
- **[ace-bundle](../ace-bundle)** for loading resources resolved through `wfi://`, `guide://`, `tmpl://`, and related protocols.
- **[ace-support-config](../ace-support-config)** for layered config behavior used by navigation settings.

## Features

- Automatic handbook discovery across `ace-*` gem sources.
- URI resolution for `wfi://`, `tmpl://`, `guide://`, `sample://`, `skill://`, and `task://`.
- Override-aware source targeting with `@` aliases.
- Smart multi-result detection for wildcard, directory, and prefix patterns.
- Fuzzy matching support for partial references.
- Cached lookups via `.ace-local/nav` for fast repeated resolution.
- Standard CLI subcommands: `resolve`, `list`, `create`, `sources`.

## Installation

Add to your Gemfile:

```ruby
gem "ace-support-nav"
```

Or install directly:

```bash
gem install ace-support-nav
```

## Usage

### Basic Resolution

```bash
# Cascade search (project > user > gem)
ace-nav resolve wfi://setup
ace-nav resolve tmpl://minitest
ace-nav resolve guide://configuration
ace-nav resolve skill://as-task-plan

# Source-specific resolution
ace-nav resolve wfi://@ace-git/setup
ace-nav resolve tmpl://@project/minitest
ace-nav resolve wfi://@user/setup
```

### Content Retrieval

```bash
ace-nav resolve wfi://setup --content
ace-nav resolve wfi://@ace-git/setup --content
```

### Resource Creation

```bash
ace-nav create wfi://bundle
ace-nav create tmpl://@ace-test/minitest
```

### Resource Discovery

```bash
# Auto-list patterns
ace-nav resolve prompt://
ace-nav resolve prompt://guidelines/
ace-nav resolve "prompt://format/*"
ace-nav resolve "wfi://create*"

# Prefix-based listings
ace-nav resolve prompt://focus/
ace-nav resolve prompt://focus/quality/
ace-nav resolve wfi://review/

# Explicit list mode
ace-nav list 'wfi://*'
ace-nav list 'skill://*'
ace-nav list 'tmpl://@project/*'
ace-nav list 'wfi://*test*'
```

### Task Navigation

`task://` delegates to `ace-task`, allowing task references to resolve through the same navigation surface.

```bash
# Basic task navigation
ace-nav resolve task://083
ace-nav resolve task://083 --path
ace-nav resolve task://083 --content
ace-nav resolve task://083 --tree

# Supported task reference formats
ace-nav resolve task://018
ace-nav resolve task://task.018
ace-nav resolve task://v.0.9.0+task.018
ace-nav resolve task://backlog+025

# Shell integration
nvim "$(ace-nav resolve task://083 --path)"
```

## Configuration

Configuration is read from `.ace/nav/config.yml` (with normal ACE cascade behavior).

```yaml
handbooks:
  sources:
    - gem: "ace-*"
    - path: "/opt/handbooks"
      alias: "handbooks"

extension_inference:
  enabled: true
  fallback_order:
    - shorthand
    - full
    - generic
    - bare

protocols:
  wfi:
    inferred_extensions: [".wfi.md", ".md", ".markdown.md", ""]
  tmpl:
    inferred_extensions: [".tmpl.md", ".md", ".markdown.md", ""]
  guide:
    inferred_extensions: [".guide.md", ".md", ".markdown.md", ""]
  prompt:
    inferred_extensions: [".prompt.md", ".md", ".markdown.md", ""]
  sample:
    inferred_extensions: [".sample.md", ".md", ".markdown.md", ""]
```

Built-in aliases:
- `@project` -> `./.ace-handbook`
- `@user` -> `~/.ace-handbook`

### Extension Inference

Extension inference enables shorthand resolution by trying protocol-specific and generic filename variants when an exact path is not found.

Examples:
- `ace-nav resolve wfi://setup` tries `setup.wfi.md`, `setup.md`, `setup.markdown.md`, `setup`
- `ace-nav resolve tmpl://custom` tries `custom.tmpl.md`, `custom.md`, `custom.markdown.md`, `custom`

Disable inference:

```yaml
extension_inference:
  enabled: false
```

Customize fallback order:

```yaml
extension_inference:
  fallback_order:
    - bare
    - full
    - shorthand
```

### Override System

Cascade priority:
1. `@project` - `./.ace-handbook`
2. `@user` - `~/.ace-handbook`
3. `@gem` - bundled gem resources

Examples:
- `ace-nav resolve wfi://setup`
- `ace-nav resolve wfi://@ace-git/setup`
- `ace-nav resolve wfi://@project/setup`

## Ruby API

```ruby
require "ace/support/nav"

Ace::Support::Nav.config

Dry::CLI.new(Ace::Support::Nav::CLI).call(arguments: ["resolve", "wfi://setup"])

engine = Ace::Support::Nav::Organisms::NavigationEngine.new
result = engine.resolve("wfi://setup")
```

## Development

```bash
bundle install
ace-test ace-support-nav
```

## Documentation

- Command help: `ace-nav --help`

## Part of ACE

`ace-support-nav` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
