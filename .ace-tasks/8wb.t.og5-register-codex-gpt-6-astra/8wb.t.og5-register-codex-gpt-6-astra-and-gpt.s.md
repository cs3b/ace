---
id: 8wb.t.og5
status: draft
priority: high
created_at: "2026-09-12 16:17:56"
estimate: TBD
dependencies: []
tags: [llm, registry, codex]
bundle:
  presets: ["project"]
  files:
    - ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml
    - .ace/llm/providers/codex.yml
    - ace-llm-providers-cli/test/fast/molecules/pi_registry_test.rb
    - ace-support-models/lib/ace/support/models/organisms/provider_sync_orchestrator.rb
    - ace-support-models/lib/ace/support/models/molecules/provider_sync_diff.rb
  commands:
    - ace-test ace-llm-providers-cli all
    - ace-test ace-llm all
    - ace-test ace-support-models all
---

# Register Codex gpt-6-astra and gpt-5.6 family in provider registry

## Objective

The shipped and tracked ACE Codex provider registry still describes the
gpt-5.3/gpt-5.4 generation. Real Lab usage has already moved on: installed
Codex CLI 0.153.4 ran a genuine `gpt-6-astra` session with native
`medium` reasoning effort on W610 (2026-09-12), proving the native target is
live while ACE source defaults remain stale. Users selecting current Codex
models through ACE (`codex:astra:high`, generic `codex`, `codex:mini`) must
resolve to real, officially supported models instead of outdated aliases.

## Behavioral Specification

### User Experience

- **Input**: users select Codex models via ACE selectors
  (`provider[:model[:thinking]]`, thinking in `low|medium|high|xhigh` —
  mirroring `ace-llm codex:astra:high "ping"`), via Lab profiles
  (`ace_target: codex:gpt-6-astra:medium`), or via explicit full model IDs.
- **Process**: registry defaults ship the current catalog on fresh installs;
  the provider sync command offers the same additions to existing
  installations without discarding operator customizations.
- **Output**: every named/generic selector resolves to the intended official
  model; explicit full IDs resolve exactly as requested; unknown models fail
  closed with no silent substitution.

### Expected Behavior

1. Update both tracked Codex registry copies to byte-identical content:
   - `ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml` (shipped
     defaults)
   - `.ace/llm/providers/codex.yml` (project registry)
2. Register exactly these additional model entries: `gpt-6-astra`,
   `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`.
3. Aliases (model scope):
   - `astra` -> `gpt-6-astra`
   - `sol`   -> `gpt-5.6-sol`
   - `terra` -> `gpt-5.6-terra`
   - `luna`  -> `gpt-5.6-luna`
   - generic `codex` -> `gpt-5.6-terra` and generic `gpt` -> `gpt-5.6-terra`
   - `mini` -> `gpt-5.6-luna`
   - preserve unrelated existing aliases (e.g. `spark` -> `gpt-5.3-codex-spark`)
4. Preserve every explicit full model ID currently listed
   (`gpt-5.3-chat-latest`, `gpt-5.3-codex`, `gpt-5.3-codex-spark`, `gpt-5.4`,
   `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.4-pro`) unless current official
   sources prove retirement; a request for any listed full ID resolves to
   exactly that model. Never blanket-substitute a flagship for an explicit
   user choice.
5. Metadata verification gate (hard requirement): every registry datum for
   the new models (limits, reasoning efforts, capabilities) must come from
   current official OpenAI/Codex documentation and the models.dev catalog
   the sync machinery consumes, with the source cited in the PR
   description. Distinguish native Codex CLI limits/reasoning from OpenAI
   API limits; record native-appropriate values. If a price, context limit,
   output limit, or account availability is not officially published, omit
   it — never fabricate. `last_synced`/`models_dev_id` bookkeeping must stay
   consistent with the sync tooling.
6. Fresh install vs existing configuration:
   - Fresh install: package defaults already contain the new catalog.
   - Existing installs: the provider sync command (ace-support-models
     `provider_sync_orchestrator`/`provider_sync_diff` path) offers the new
     models into `.ace/llm/providers/codex.yml` while preserving
     operator/project-level overrides (local aliases, locally kept/removed
     entries, edited limits). Sync must not clobber local customizations
     and must not touch unrelated providers.
7. Reasoning presets: existing `ace-llm/.ace-defaults/llm/thinking/codex/`
   levels (`low`, `medium`, `high`, `xhigh`->`high`) keep working for the
   new models exactly as native Codex supports them (W610 proved
   `gpt-6-astra` + `medium`); do not invent unsupported effort levels.

### Interface Contract

```bash
# Named aliases (new)
ace-llm codex:astra:high "ping" --no-fallback   # -> gpt-6-astra
ace-llm codex:sol:low "ping" --no-fallback      # -> gpt-5.6-sol
ace-llm codex:terra:medium "ping" --no-fallback # -> gpt-5.6-terra
ace-llm codex:luna:high "ping" --no-fallback    # -> gpt-5.6-luna

# Generic aliases (retargeted)
ace-llm codex "ping"        # provider default -> gpt-5.6-terra
ace-llm codex:gpt "ping"    # -> gpt-5.6-terra
ace-llm codex:mini "ping"   # -> gpt-5.6-luna

# Explicit full IDs (preserved; exact match, no substitution)
ace-llm codex:gpt-6-astra:medium "ping" --no-fallback  # exact W610 target
ace-llm codex:gpt-5.3-codex:low "ping" --no-fallback   # still resolves
ace-llm codex:spark "ping" --no-fallback               # alias preserved
```

**Error Handling**:

- Unknown model (`ace-llm codex:gpt-9 "ping"`) fails closed with a clear
  error listing valid models; no fallback substitution, especially not to a
  flagship, when `--no-fallback` is set or the model is explicit.
- Registry copy drift (defaults vs project registry differing bytes) must
  fail the registry test, not silently pass.

**Edge Cases**:

- Operator override: a project registry that locally pins `gpt: gpt-5.4`
  keeps its pin after sync offers the new models.
- Thinking level on a model without native support resolves/fails per the
  verified official matrix, never by silent coercion.

## Success Criteria

- [ ] Both codex registry copies byte-identical (digest match) and offering
      `gpt-6-astra`, `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna` with the
      alias map above; generic `codex`/`gpt` -> Terra, `mini` -> Luna.
- [ ] Every listed full model ID still resolves exactly; `spark` preserved;
      unknown models fail closed; `--no-fallback` keeps one exact target.
- [ ] Every new-model registry datum cites a current official source in the
      PR; nothing fabricated; native vs API distinction recorded.
- [ ] Fresh-install defaults and existing-config sync preservation both
      proven by tests (sync adds new models, preserves local overrides,
      leaves unrelated providers untouched).
- [ ] Affected package suites pass via canonical `ace-test` commands;
      `ace-task doctor` clean; changed package(s) build as gems with
      changelog entries; no publication.
- [ ] Branch pushed and one Forgejo PR opened against `main`; CI keeps the
      protected summary context `Test Suite / Test Summary (pull_request)`
      green; manual CLI verification recorded against the exact PR head SHA
      using the Lab test shell.

## Validation Questions

- Which per-model limit values do current official OpenAI/Codex docs vs
  models.dev publish for the four new models, and where should provenance
  be recorded (PR description vs task file)?
- Do `gpt-5.6-sol`/`terra`/`luna` natively support `low|medium|high`
  reasoning efforts (and does `xhigh` remain mapped to `high`)?
- Should any gpt-5.3/gpt-5.4 entry be retired based on official sources, or
  do all remain live? (Default: preserve.)
- The `pi` provider's own `gpt -> openai-codex/gpt-5.4` alias is a separate
  Pi-registry delta (already-delivered 8w3.t.1vd surface); confirm it stays
  out of scope here and gets its own later task.

## Vertical Slice Decomposition

- **Type**: standalone flat task (single capability slice: Codex provider
  registry/defaults/sync metadata). Advisory size: **medium** (two registry
  copies + sync preservation + selector regressions across three packages'
  test surfaces).
- **Verification intent**: unit-equivalent registry/alias/sync tests plus
  CLI-level manual verification on the exact head.

## Verification Plan

### Unit/component validation

- New `ace-llm-providers-cli/test/fast/molecules/codex_registry_test.rb`
  mirroring `pi_registry_test.rb`: byte-identical tracked copies, exact
  model list, exact alias map, metadata keys present only when verified.
- `ace-llm` molecules: `client_registry_test.rb`,
  `provider_model_parser_test.rb`, `model_limit_resolver_test.rb` cover
  alias resolution, `provider:model:thinking` parsing, and limits lookup for
  the new IDs.
- `ace-support-models`: `provider_sync_orchestrator_test.rb`,
  `provider_sync_diff_test.rb`, `provider_config_reader_test.rb`,
  `provider_config_writer_test.rb` cover fresh-defaults vs
  existing-config preservation and no unrelated-provider writes.

### Integration/e2e validation

- `ace-llm codex:astra:high "ping" --no-fallback` style invocations resolve
  to the expected provider/model/thinking on the PR head (Lab test shell).

### Failure/invalid path validation

- Unknown model fails closed; explicit-ID requests are never redirected to
  a different model; registry drift between the two copies fails tests;
  sync with a locally overridden alias preserves the override.

### Verification commands

```bash
ace-test ace-llm-providers-cli all   # registry + client tests
ace-test ace-llm all                 # parser/registry/limits tests
ace-test ace-support-models all      # sync preservation tests
ace-test-suite --no-color --target all  # complete deterministic suite
ace-task doctor                      # task health
```

## Scope of Work

- Codex provider registry defaults + tracked project copy, alias map, and
  verified metadata for the four new models.
- Sync preservation behavior for existing configurations.
- Selector/CLI regression tests for named aliases, generic aliases, explicit
  full IDs, and failure paths.
- Changelog entry and gem build for packages whose shipped bytes changed
  (expected: `ace-llm-providers-cli`). No publication, no release.

## Out of Scope

- Any Pi provider registry change (the Pi `gpt` alias retarget is a later,
  separate task requiring its own reproduction/ownership decision).
- `codexoai`, `codexoss`, and every other provider registry.
- Runtime/Nervus/Lab profile edits, credential work, global profiles.
- GitHub synchronization, RubyGems publication, version churn beyond the
  changed-package changelog/bump policy.
- Implementation during the review of this specification (this file is the
  reviewed contract; work starts via `wfi://task/work` after approval).

## References

- Precedent: `8w3.t.1vd` (Pi/Z.AI GLM 5.3 registry delivery, W564/PR18).
- Live-native evidence: W610 ran installed Codex CLI 0.153.4 with
  `gpt-6-astra` + `medium` reasoning on 2026-09-12.
- Delivery guide: `.ace-handbook/guides/project-delivery.g.md` (capability
  ownership, review/integration, CI evidence rules).
- Data-only change: no new CLI commands/flags/output formats, so no draft
  `ux/usage.md` is required by the drafting workflow.
