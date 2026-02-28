# ace-sim Usage

## Preset-Driven Run (Canonical)

```bash
ace-sim run \
  --preset validate-idea \
  --source path/to/source.md
```

`--source` must be an existing readable file path.
Built-in presets include provider/synthesis defaults, so `--source` is enough.

## Override Preset Defaults with CLI

```bash
ace-sim run \
  --preset validate-idea \
  --source path/to/source.md \
  --steps draft,plan,work \
  --provider codex:mini \
  --provider google:gflash \
  --repeat 2
```

## Final Suggestions Synthesis (Optional)

```bash
ace-sim run \
  --preset validate-task \
  --source path/to/source.md
```

- `--synthesis-workflow` enables a final run-level synthesis stage.
- Common choices:
  - `wfi://task/review` for task-focused synthesis
  - `wfi://idea/review` for idea-focused synthesis
- `--synthesis-provider` is optional; when omitted, the first run provider is used.

## Precedence

1. Explicit CLI flag
2. Preset file (`.ace/sim/presets/*.yml`, fallback `.ace-defaults/sim/presets/*.yml`)
3. Global sim defaults (`.ace-defaults/sim/config.yml`)

## Step Configs

- Step configs are markdown bundle configs at `.ace/sim/steps/*.md` (fallback `.ace-defaults/sim/steps/*.md`).
- Default step configs use strict sections (`project_context`, step workflow, `input`) and instruction/report headings.
- Default preset `validate-idea` runs `draft -> plan -> work` with synthesis workflow `wfi://idea/review`.
- Default preset `validate-task` runs `plan -> work` with synthesis workflow `wfi://task/review`.

## Artifacts

Top-level:
- `.cache/ace-sim/simulations/<run-id>/session.yml`
- `.cache/ace-sim/simulations/<run-id>/synthesis.yml`
- `.cache/ace-sim/simulations/<run-id>/final/source.original.md` (when synthesis enabled)
- `.cache/ace-sim/simulations/<run-id>/final/input.md` (when synthesis enabled)
- `.cache/ace-sim/simulations/<run-id>/final/output.sequence.md` (when synthesis enabled)
- `.cache/ace-sim/simulations/<run-id>/final/suggestions.report.md` (when synthesis enabled)
- `.cache/ace-sim/simulations/<run-id>/final/source.revised.md` (when synthesis enabled)

Per chain (`provider x repeat`):
- `.cache/ace-sim/simulations/<run-id>/chains/<provider>-<iteration>/<NN-step>/input.md`
- `.cache/ace-sim/simulations/<run-id>/chains/<provider>-<iteration>/<NN-step>/user.bundle.md`
- `.cache/ace-sim/simulations/<run-id>/chains/<provider>-<iteration>/<NN-step>/user.prompt.md`
- `.cache/ace-sim/simulations/<run-id>/chains/<provider>-<iteration>/<NN-step>/output.md`

## Behavior Notes

- One independent full chain runs per provider x repeat.
- Step 1 copies `--source` into `input.md`.
- Step N copies previous `output.md` into next `input.md`.
- Step success is minimal: `output.md` exists and is non-empty.
- If one chain fails, only that chain stops; other chains continue.
- `--dry-run` never mutates source ideas/tasks.
- If synthesis is enabled, final run status also depends on final suggestions generation.
- Synthesis input is an aggregate of executed steps only. If you run `--steps draft`, only draft appears in `final/input.md`.
