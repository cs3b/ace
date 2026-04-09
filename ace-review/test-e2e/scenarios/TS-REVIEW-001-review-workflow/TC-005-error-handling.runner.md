# Goal 5 — Error Handling

## Goal

Test dry-run validation cases: (1) circular dependency — preset_a inherits preset_b which inherits preset_a, (2) missing reference — broken preset references nonexistent_base, (3) totally nonexistent preset. Also capture the dry-run behavior for (4) invalid model configuration. In dry-run mode model existence is not validated, so the invalid-model case is expected to prepare successfully instead of failing.

## Workspace

Save all output to `results/tc/05/`. Capture for each error case:
- `results/tc/05/circular.stdout`, `.stderr`, `.exit`
- `results/tc/05/missing-ref.stdout`, `.stderr`, `.exit`
- `results/tc/05/nonexistent.stdout`, `.stderr`, `.exit`
- `results/tc/05/invalid-model.stdout`, `.stderr`, `.exit`

## Constraints

- The sandbox has preset_a and preset_b (circular), broken (missing ref) presets.
- For invalid model, use a nonexistent provider/model name and record the actual dry-run behavior instead of forcing a failure.
- All artifacts must come from real tool execution, not fabricated.
