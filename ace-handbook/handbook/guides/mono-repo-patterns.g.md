# Mono-Repo Development Patterns

Patterns for developing ACE gems within the mono-repo structure.

## Gemfile vs Gemspec

Individual gems do NOT have their own `Gemfile`. The mono-repo uses a single root `Gemfile` for all development.

| File | Location | Purpose |
|------|----------|---------|
| `Gemfile` | Root only | Development dependencies for entire mono-repo |
| `*.gemspec` | Each gem | Runtime dependencies for gem distribution |

**Why no per-gem Gemfile?**
- All gems developed together in mono-repo context
- Root Gemfile includes all gems as path dependencies
- `ace-test` and binstubs use root Gemfile
- CI uses root Gemfile
- Simplifies dependency management and version consistency

## bin/ vs exe/ Distinction

| Directory | Purpose |
|-----------|---------|
| `bin/` | Mono-repo development binstubs for running executables without installation |
| `exe/` | Gem distribution executables that get installed with the gem |

**Pattern**: bin/ wrappers use root Gemfile, exe/ uses gem's own gemspec dependencies.

## Mono-Repo Binstub Pattern

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Wrapper script to run ace-gem with proper bundler context
require "pathname"

# Find the ace root directory
ace_meta_root = Pathname.new(__FILE__).dirname.parent.realpath

# Set the Gemfile location
ENV["BUNDLE_GEMFILE"] = ace_meta_root.join("Gemfile").to_s

# Load bundler
require "bundler/setup"

# Now require and run the actual ace-gem executable
load ace_meta_root.join("ace-gem/exe/ace-gem").to_s
```

## Development Workflow

```bash
# Run any ace gem directly without installation
./bin/ace-gem --help
./bin/ace-search --query "pattern"
./bin/ace-git-worktree --task 123

# All binstubs use root Gemfile for consistent environment
# No need to install gems locally during development
```

## Production Examples

| Binstub | Wraps |
|---------|-------|
| `bin/ace-docs` | `ace-docs/exe/ace-docs` |
| `bin/ace-search` | `ace-search/exe/ace-search` |
| `bin/ace-lint` | `ace-lint/exe/ace-lint` |
| `bin/ace-git-worktree` | `ace-git-worktree/exe/ace-git-worktree` |

## Adding a New Gem

1. Create gem directory at repo root: `ace-new-gem/`
2. Add path dependency to root Gemfile: `gem "ace-new-gem", path: "ace-new-gem"`
3. Create binstub in `bin/ace-new-gem` using pattern above
4. Run `bundle install` from repo root

## Related

- [ADR-015](../../../docs/decisions/ADR-015-mono-repo-ace-gems-migration.md) - Mono-repo migration decision
- [ace-gems.g.md](../../../docs/ace-gems.g.md) - Gem development overview
