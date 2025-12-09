---
id: v.0.9.0+task.135
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Migrate ace-llm YAML config loading from Symbol to String keys

## Description

Migrate ace-llm YAML configuration loading from permitting Symbol keys to String-only keys for improved security and consistency. Currently, `client_registry.rb` uses `YAML.safe_load` with `permitted_classes: [Symbol, Date]`, which creates a theoretical DoS vector via symbol table exhaustion. While current risk is low (configs are local/repo-controlled), defense-in-depth practices suggest removing unnecessary Symbol support. This change will also improve consistency with other gems in the monorepo.

**Category**: Tech Debt, Security

**Scope**: ace-llm gem only (client_registry.rb YAML loading)

## Acceptance Criteria

- [ ] `client_registry.rb` YAML loading removes Symbol from permitted_classes
- [ ] Date support is retained if still needed for last_synced fields
- [ ] All existing provider YAML configs continue to work (they already use string keys)
- [ ] Tests verify that symbol keys are NOT supported (add regression test)
- [ ] Tests verify that string keys continue to work correctly
- [ ] Deprecation notice in comments is removed (the one added in the original code)
- [ ] All ace-llm tests pass

## Implementation Notes

### Current State

**File**: `ace-llm/lib/ace/llm/molecules/client_registry.rb`
- Line 243: `YAML.safe_load(content, permitted_classes: [Symbol, Date], aliases: true)`
- Lines 233-240: Deprecation notice and comments explaining symbol support

**Testing**: All existing tests in `test/molecules/client_registry_test.rb` use string keys in YAML configs (good!)

**Provider Configs**: All `.ace.example/llm/providers/*.yml` files already use string keys

### Migration Strategy

1. **Change YAML.safe_load call**:
   - Remove `Symbol` from permitted_classes
   - Keep `Date` if needed for `last_synced` field parsing
   - Keep `aliases: true` for YAML anchor/alias support
   - Proposed: `permitted_classes: [Date]` or `permitted_classes: []` if Date not needed

2. **Update comments**:
   - Remove deprecation notice (lines 233-240)
   - Update docstring to reflect string-only key requirement
   - Document that Date is supported only for timestamp fields if retained

3. **Add regression test**:
   - Create test that verifies symbol keys are rejected or converted
   - Verify YAML with symbol keys triggers appropriate behavior
   - Test file: `test/molecules/client_registry_test.rb`

4. **Verify Date usage**:
   - Check if `last_synced` field is actually parsed as Date or just stored as string
   - If parsed as Date object, keep `Date` in permitted_classes
   - If stored as string, remove `Date` from permitted_classes

5. **Documentation**:
   - Update any developer docs that reference YAML config format
   - Ensure provider YAML schema documentation specifies string keys only

### Risk Assessment

**Low Risk**:
- All existing configs use string keys
- All tests use string keys
- No code found accessing config with symbol keys (`:key` syntax)
- Change is purely defensive/hardening

**Breaking Change**: None expected
- If any user configs used symbol keys, this would break them
- However, all example configs and tests use strings
- Risk is limited to undocumented usage

### Related Files

- `/Users/mc/Ps/ace-meta/ace-llm/lib/ace/llm/molecules/client_registry.rb` (primary change)
- `/Users/mc/Ps/ace-meta/ace-llm/test/molecules/client_registry_test.rb` (add tests)
- `/Users/mc/Ps/ace-meta/ace-llm/.ace.example/llm/providers/*.yml` (verify compatibility)
