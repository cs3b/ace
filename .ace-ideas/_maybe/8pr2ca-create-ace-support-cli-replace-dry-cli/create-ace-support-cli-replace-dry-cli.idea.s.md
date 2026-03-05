---
title: Create ace-support-cli Gem to Replace dry-cli Dependency
filename_suggestion: create-ace-support-cli-replace-dry-cli
enhanced_at: 2026-03-05 00:00:00.000000000 +00:00
llm_model: claude-opus-4-6
id: 8pr2ca
status: pending
tags:
- dependency
- cli
- support
created_at: '2026-02-28 17:37:36'
source: user
---

# Create ace-support-cli Gem to Replace dry-cli Dependency

## What I Hope to Accomplish

Replace the dry-cli dependency across all ace-* gems with a purpose-built ace-support-cli package. dry-cli has recurring friction points: no built-in numeric coercion (type: :integer options arrive as strings), limited option validation, and type coercion issues that propagate to downstream libraries (e.g., strings passed to Faraday where integers/floats are expected). A custom CLI framework solves these systematically at the foundation layer instead of patching each gem individually.

## What "Complete" Looks Like

- **ace-support-cli gem** providing command registration, option parsing, and subcommand routing with an API compatible enough with dry-cli for straightforward migration
- **Built-in type coercion**: options declared as `type: :integer`, `type: :float`, or `type: :boolean` are automatically coerced before reaching command logic -- no more string-to-number bugs
- **Option validation**: required options, allowed values, range constraints, and custom validators defined declaratively in the command class
- **All ace-* gems migrated** from dry-cli to ace-support-cli with no behavioral regressions
- **dry-cli removed** from the dependency tree entirely

## Success Criteria

- Option type coercion works correctly for integer, float, boolean, and array types out of the box
- Migration path from dry-cli is mechanical: swap the base class/module, keep existing option declarations largely intact
- All existing CLI commands across ace-* gems work identically after migration
- No more workarounds for dry-cli type coercion in individual gems (e.g., manual `.to_i` / `.to_f` calls removed)
- Test coverage for option parsing, coercion, validation, and subcommand routing

---

## Original Idea

```
Create ace-support-cli gem to replace dry-cli dependency. We have recurring issues with dry-cli: type coercion for --timeout (integers/floats passed as strings to Faraday), limited option validation, no built-in numeric coercion for type: :integer options. A custom ace-support-cli package could fix these systematically across all ace-* gems instead of patching each gem individually. Could mirror dry-cli API for easy migration.
```
