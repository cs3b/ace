# Migration Guide: ace-core and ace-test-support Renaming

## Overview

As part of ACE ecosystem v1.0 preparation, we've aligned our infrastructure gem naming to follow the `ace-support-*` pattern. This creates a clear distinction between:

- **`ace-*` gems**: Functional capability gems WITH direct CLI tools
- **`ace-support-*` gems**: Infrastructure and support gems WITHOUT direct CLI tools (library-only)

## Gem Renaming

The following gems have been renamed:

| Old Name | New Name | Purpose |
|----------|----------|---------|
| `ace-core` | `ace-support-core` | Core configuration cascade and shared functionality |
| `ace-test-support` | `ace-support-test-helpers` | Shared test utilities for development |

## What STAYS THE SAME (No Breaking Changes)

- **Module namespaces remain unchanged**:
  - `Ace::Core` (NOT Ace::Support::Core)
  - `Ace::TestSupport` (NOT Ace::Support::TestHelpers)
- **Require paths remain unchanged**:
  - `require 'ace/core'`
  - `require 'ace/test_support'`
- **All APIs and functionality remain identical**
- **No code changes required in your gems**

## Migration Steps

### For Gem Developers

1. **Update your gemspec dependencies**:

```ruby
# Old
spec.add_dependency 'ace-core', '~> 0.10'
spec.add_development_dependency 'ace-test-support', '~> 0.9'

# New
spec.add_dependency 'ace-support-core', '~> 0.10'
spec.add_development_dependency 'ace-support-test-helpers', '~> 0.9'
```

2. **Update your Gemfile** (if using path dependencies):

```ruby
# Old
gem 'ace-core', path: '../ace-core'
gem 'ace-test-support', path: '../ace-test-support'

# New
gem 'ace-support-core', path: '../ace-support-core'
gem 'ace-support-test-helpers', path: '../ace-support-test-helpers'
```

3. **No code changes needed** - require paths and module names stay the same!

4. **Bump your gem's patch version** and update CHANGELOG

### For Application Developers

If you're using these gems in a Ruby application:

1. **Update your Gemfile**:

```ruby
# Old
gem 'ace-core', '~> 0.10'

# New
gem 'ace-support-core', '~> 0.10'
```

2. **Run `bundle update`** to get the new gems

3. **No code changes needed** - your require statements stay the same

## Version Mapping

The new gems start with the same version as the old gems:

- `ace-support-core` starts at v0.10.0 (same as final ace-core)
- `ace-support-test-helpers` starts at v0.9.2 (same as final ace-test-support)

## Affected Gems

The following ACE gems have been updated to use the new names (with patch version bumps):

### Runtime Dependencies on ace-support-core:
- ace-context (0.16.0 → 0.16.1)
- ace-docs (0.6.1 → 0.6.2)
- ace-git-commit (0.11.0 → 0.11.1)
- ace-git-diff (0.1.1 → 0.1.2)
- ace-lint (0.3.0 → 0.3.1)
- ace-llm (0.9.4 → 0.9.5)
- ace-nav (0.10.1 → 0.10.2)
- ace-review (0.11.1 → 0.11.2)
- ace-search (0.11.2 → 0.11.3)
- ace-taskflow (0.15.1 → 0.15.2)
- ace-test-runner (0.1.5 → 0.1.6)

### Development Dependencies on ace-support-test-helpers:
- ace-git-diff
- ace-nav
- ace-review
- ace-search
- ace-support-markdown (0.1.2 → 0.1.3)
- ace-test-runner (also has runtime dependency)

## Deprecation Notice

The old gems (`ace-core` and `ace-test-support`) are now deprecated and will be marked as such on RubyGems. They will remain available for a transition period but will not receive updates.

## Timeline

- **November 2025**: New gems published, old gems deprecated
- **December 2025**: Final reminder to migrate
- **January 2025**: Old gems marked as fully deprecated (but still available)

## Getting Help

If you encounter any issues during migration:

1. Check that you've updated all references in gemspecs and Gemfiles
2. Ensure you've run `bundle update` after making changes
3. Verify tests pass with the new dependencies
4. Report issues at: https://github.com/cs3b/ace-meta/issues

## Why This Change?

This naming convention makes it immediately clear which gems provide CLI tools (ace-*) versus which are library-only infrastructure (ace-support-*). This improves discoverability and sets clear expectations for gem functionality.