---
id: 8wq.t.3e2
status: done
priority: medium
created_at: "2026-09-27 02:15:38"
estimate: 
dependencies: []
tags: [ace-llm, release, codex, presets]
---

# Release ace-llm 0.40.0 to RubyGems so installed codex presets stop failing (ace-task plan blocked)

## Kontekst

Installed `ace-llm` is 0.38.4; its Codex presets (`presets/codex/{ro,rw}.yml`) still pass
`--full-auto`, which codex-cli 0.156.1 rejects (`error: unexpected argument '--full-auto' found`).
This breaks every codex-first LLM delegation — observed 2026-09-27 while generating the plan for
8wq.t.1vz: `ace-task plan 8wq.t.1vz` and `--refresh` both failed; `--model gemini:...` failed on
revoked Gemini Code Assist tier; `--model claude:...` failed on expired OAuth.

The monorepo source is already fixed (0.40.0, commits `8df88565d` + `b7fe3742e`): presets use
explicit `--sandbox read-only|workspace-write`. The gap is purely release/publish + install —
publish 0.40.0 (fitting the OTP HITL flow, see 8wm.t.vs3) and reinstall in agent environments.

## Interim workaround (2026-09-27)

User-level cascade override mirroring the fixed presets (harmless to keep after release):
`~/.ace/llm/presets/codex/ro.yml` and `rw.yml` with `cli_args: [--sandbox, read-only|workspace-write]`.

## Ze źródła

Follow-up z 8wq.t.1vz (Plan Retrieval Guard: plan-generation stalls → follow-up fix task).
