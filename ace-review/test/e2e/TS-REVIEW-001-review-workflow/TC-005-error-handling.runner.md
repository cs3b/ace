# Goal 5 — Error Handling

## Goal

Test error cases: (1) circular dependency — preset_a inherits preset_b which inherits preset_a, (2) missing reference — broken preset references nonexistent_base, (3) totally nonexistent preset, (4) invalid model configuration. Verify each produces a non-zero exit code with an informative error message.

## Workspace

Save all output to `results/tc/05/`. Capture for each error case:
- `results/tc/05/circular.stdout`, `.stderr`, `.exit`
- `results/tc/05/missing-ref.stdout`, `.stderr`, `.exit`
- `results/tc/05/nonexistent.stdout`, `.stderr`, `.exit`
- `results/tc/05/invalid-model.stdout`, `.stderr`, `.exit`

## Constraints

- The sandbox has preset_a and preset_b (circular), broken (missing ref) presets.
- For invalid model, pass a clearly malformed model token that fails CLI validation (for example `invalid/model`).
- All artifacts must come from real tool execution, not fabricated.

### Invalid-Model Simulation Requirement

Because dry-run intentionally does not execute LLM calls, provider resolution does not happen there.
Use a malformed model token so `ace-review` fails immediately during option validation.
- Example command pattern: `ace-review --preset code --model invalid/model --subject "files:*.rb" --dry-run`
