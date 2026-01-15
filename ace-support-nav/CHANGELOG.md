# Changelog

All notable changes to ace-support-nav will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.17.1] - 2026-01-15

### Changed
- Migrate CLI commands to Hanami pattern
  - Move commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`
  - Update test file references for new namespace

## [0.17.0] - 2026-01-12

### Changed
- **BREAKING**: Renamed gem from `ace-nav` to `ace-support-nav`
  - Namespace changed from `Ace::Nav` to `Ace::Support::Nav`
  - Import path changed from `require "ace/nav"` to `require "ace/support/nav"`
  - Gem dependency changed from `ace-nav` to `ace-support-nav`
  - Executable remains `ace-nav` for backwards compatibility
  - User config path `.ace/nav/` preserved for backward compatibility

### Migration Guide
```ruby
# Before
require "ace/nav"
Ace::Nav.config
Ace::Nav::CLI.start(ARGV)

# After
require "ace/support/nav"
Ace::Support::Nav.config
Ace::Support::Nav::CLI.start(ARGV)
```

## Previous Releases (as ace-nav)

For detailed changes prior to 0.17.0, see the git history of the ace-nav directory before the rename (commit da99d457b and earlier).

### Notable releases before rename:

- **0.16.1**: Eliminated wrapper pattern in dry-cli commands
- **0.16.0**: Migrated CLI framework from Thor to dry-cli
- **0.15.0**: Thor CLI migration with standardized command structure
- **0.14.0**: Minimum Ruby version raised to 3.3.0
- **0.13.0**: Renamed `.ace.example/` to `.ace-defaults/`
- **0.10.0**: Added task:// Protocol Support
- **0.9.0**: Initial release with core navigation functionality
