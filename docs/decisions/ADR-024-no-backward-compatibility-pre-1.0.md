# ADR-024: No Backward Compatibility Until 1.0.0

## Status
Accepted - January 2026

## Context

ACE is in pre-1.0.0 development with a single user (internal development). During this phase:

1. **Rapid Experimentation**: Gems are being restructured, renamed, and refactored frequently
2. **Naming Convention Changes**: Recent work (Task 202) involves renaming gems like `ace-config` to `ace-support-config`, `ace-timestamp` to `ace-b36ts`
3. **Single User**: The only consumer of these gems is the internal mono-repo
4. **Maintenance Overhead**: Backward compatibility shims (require path redirects, namespace aliases, deprecation warnings) add complexity without benefit

Maintaining backward compatibility during this phase creates unnecessary work:
- Writing and testing compatibility shims
- Planning deprecation timelines (e.g., "Remove in 1.0.0, target: 2027-06-01")
- Documenting migration paths for non-existent external users
- Carrying legacy code that slows development

## Decision

**No backward compatibility mechanisms will be provided for pre-1.0.0 gems.**

This means:
1. **No require path shims**: When a gem is renamed, the old `require` path is removed immediately
2. **No namespace aliases**: When a namespace changes, the old constant is not aliased
3. **No deprecation warnings**: Changes are made directly without warning periods
4. **No migration guides**: External users don't exist yet; CHANGELOG is sufficient

### What This Applies To

- All `ace-*` gems (ace-lint, ace-docs, ace-review, etc.)
- All `ace-support-*` gems (ace-support-core, ace-support-config, ace-b36ts, etc.)
- All `ace-llm-*` gems (ace-llm, ace-llm-providers-cli, etc.)

### When This Changes

This decision expires at 1.0.0 release. At that point:
- Semantic versioning backward compatibility rules apply
- Deprecation cycles become mandatory for breaking changes
- Migration guides required for MAJOR version bumps

## Implementation

### For Gem Renames

```ruby
# BEFORE (with backward compatibility)
# lib/ace/old_name.rb
warn "[Deprecation] require 'ace/old_name' is deprecated..."
require "ace/new_name"

# lib/ace/new_name.rb
module Ace
  OldName = NewName  # Alias
end

# AFTER (no backward compatibility)
# lib/ace/old_name.rb - DELETED
# lib/ace/new_name.rb - No alias, no deprecation warning
```

### For Namespace Changes

```ruby
# BEFORE
module Ace
  module Support
    module Timestamp; end
  end
  Timestamp = Support::Timestamp  # Backward compat alias
end

# AFTER
module Ace
  module Support
    module Timestamp; end
  end
  # No alias - use Ace::Support::Timestamp directly
end
```

### CHANGELOG Documentation

All breaking changes are documented in CHANGELOG.md under the appropriate version. This provides sufficient history for the internal user.

## Consequences

### Positive

- **Faster Development**: No time spent writing compatibility code
- **Cleaner Codebase**: No legacy shims cluttering the code
- **Simpler Testing**: No need to test deprecated code paths
- **Clear Intent**: Code reflects current architecture, not historical baggage
- **Reduced Confusion**: No mixed old/new patterns in the same codebase

### Negative

- **Immediate Updates Required**: When a gem changes, all usages must be updated in the same PR
- **No Gradual Migration**: Can't update consumers incrementally

### Neutral

- **Mono-Repo Advantage**: All consumers are in the same repository, so updating them together is straightforward
- **Git History**: Breaking changes are still tracked in git for reference

## Related Decisions

- **ADR-015**: Mono-Repo Migration - enables updating all consumers together
- **ADR-020**: Semantic Versioning - defines when backward compatibility becomes mandatory (1.0.0)

## References

- Task 202: Rename Support Gems and Executables for Naming Consistency
- Semantic Versioning 2.0.0: https://semver.org/ (pre-1.0.0 allows breaking changes in MINOR versions)
