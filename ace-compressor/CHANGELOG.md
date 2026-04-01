# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.24.7] - 2026-04-01

### Fixed
- Embedded concrete rule-heavy fixture content in TC-004 E2E runner so policy classifier reliably triggers refusal.

## [0.24.6] - 2026-03-31

### Changed
- Role-based compression defaults.

## [0.24.5] - 2026-03-29

### Changed
- Role-based compressor model default.


## [0.24.4] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.24.3] - 2026-03-29

### Fixed
- **ace-compressor v0.24.3**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.24.2] - 2026-03-29

### Fixed
- Bumped `ace-support-*` dependency constraints to currently publishable versions so this package remains installable from RubyGems.

## [0.24.1] - 2026-03-23

### Fixed
- Report true compression gains for ace-bundle inputs by reading the `.meta.json` sidecar instead of comparing against already-compressed content.
- Skip re-compression when ace-bundle has already compressed the content, preventing output size inflation.

## [0.24.0] - 2026-03-23

### Changed
- Refreshed the package README to the current ACE layout pattern with use-case-led structure, integration links, feature summary, and updated quick-start guidance aligned to the current CLI surface.

## [0.23.2] - 2026-03-22

### Changed
- Normalized installation and quick-start README examples to fenced code blocks and updated command examples to consistent `mise exec --` execution format.

## [0.23.1] - 2026-03-22

### Changed
- Refreshed the README structure with dedicated purpose/install sections, preserved quick-start command coverage, and added a canonical ACE footer link.

## [0.23.0] - 2026-03-21

### Changed
- Added initial `TS-COMP-001` value-gated smoke E2E coverage for `ace-compressor`, including scenario runner/verifier contracts and an ADD/SKIP decision record with unit-coverage evidence.

## [0.22.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.22.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.21.3] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.21.2] - 2026-03-13

### Fixed
- Preserved markdown frontmatter-only files during exact compression by falling back to raw content emission when no parseable blocks remain.

## [0.21.1] - 2026-03-09

### Fixed
- Preserved stable logical source identity for ACE-native inputs resolved through `ace-bundle`, so preset/protocol/config runs no longer key cache entries or emit `FILE|...` records from ephemeral temp bundle paths.

### Changed
- Separated source identity from content file resolution in the runner/cache pipeline so compression still operates on concrete files while cache manifests and output records use stable user-facing source paths.

### Technical
- Expanded resolver, cache-store, runner, and command regression coverage for repeated ACE-native input runs, stable cache hits, and deterministic emitted source records.

## [0.21.0] - 2026-03-09

### Added
- Added `mode: "agent"` support to `Ace::Compressor.compress_text`, routing in-memory text compression through the agent engine while preserving the content-only return contract.

### Changed
- Changed fenced markdown handling to pass through nested `ContextPack` records directly instead of re-encoding them as opaque `CODE|markdown|...` payloads during recompression.

### Technical
- Added regression coverage for nested `ContextPack` passthrough and agent-mode `compress_text` behavior.

## [0.20.0] - 2026-03-09

### Added
- Added optional `labels:` parameter to `CacheStore#manifest` for stable cache keys independent of filesystem paths, enabling cache reuse across tmpdir-based callers.

## [0.19.2] - 2026-03-09

### Added
- Added `compress_text` convenience method to `ExactCompressor` and top-level `Ace::Compressor` module for in-memory text compression without filesystem access.

## [0.19.1] - 2026-03-09

### Fixed
- Fixed temporary directory leak in `InputResolver` — each CLI run now cleans up its temp dir via `ensure` block in `CompressionRunner`.
- Removed unused `@resolved_files` instance variable from `InputResolver`.

## [0.19.0] - 2026-03-09

### Added
- Added `--source-scope` with `merged|per-source` modes so `ace-compressor compress` can emit one output per resolved source while preserving existing merged behavior by default.
- Added per-source runner behavior and regression coverage to keep per-source output ordering stable and deterministic.

### Changed
- Changed input resolution so protocol URLs like `wfi://...` are routed through `ace-bundle` resolution instead of being treated as missing filesystem paths.
- Updated usage docs with per-source examples, option documentation, and output-path constraints for multi-input per-source runs.

### Technical
- Expanded command, runner, and resolver tests to cover invalid source-scope errors, per-source path emission ordering, and unresolved protocol URL failures.

## [0.18.0] - 2026-03-09

### Added
- Added ACE-native source input resolution so `ace-compressor compress` accepts preset names and YAML bundle config files directly.
- Added an input resolver molecule and focused molecule-level tests for preset/config detection, mixed-source resolution, and failure messaging.

### Changed
- Changed compression runner flow to normalize inputs before mode dispatch, preserving existing ContextPack output contracts across exact/compact/agent modes.
- Updated usage documentation with preset/config examples, mixed-source behavior, and explicit resolver failure conditions.

### Fixed
- Fixed cache stem generation for resolver-produced sources outside the repository root so preset/config flows no longer crash during canonical cache path derivation.

### Technical
- Expanded command and molecule regression coverage for resolved preset/config paths and external-source cache canonicalization.

## [0.17.0] - 2026-03-09

### Added
- Added `ace-compressor benchmark` to compare `exact`, `compact`, and `agent` on live files using byte/line deltas plus retention coverage against the exact baseline.
- Added shared per-machine workflow cache support with configurable `shared_cache_dir` and `shared_cache_scope` so stable `wfi://...` sources can be reused across worktrees on the same machine.

### Changed
- Changed the CLI entrypoint to route benchmark runs separately while preserving existing `compress` behavior and output paths.
- Changed cache handling so eligible shared-cache hits hydrate back into the normal local canonical cache path.

### Technical
- Added retention reporting and benchmark runner internals to keep comparison/reporting logic out of the normal compression path.
- Expanded command and organism regression coverage for benchmark output and cross-project shared workflow cache reuse.

## [0.16.0] - 2026-03-09

### Changed
- Changed exact-mode workflow encoding to compact long natural-language list items into shorter phrase slugs while preserving stable `LIST|...` structure and item order.
- Changed exact-mode shell fence handling so script-like bash blocks collapse into single `CODE|bash|...` records instead of many verbose `CMD|...` lines.

### Technical
- Added regression coverage for compact narrative list slugs and script-style shell block normalization.
- Bumped cache contracts so exact, compact, and agent workflow reruns refresh artifacts generated with the previous list/shell encoding.

## [0.15.0] - 2026-03-09

### Added
- Added deterministic post-LLM list-item compaction so agent mode shortens verbose list payloads while preserving item identity and ordering.

### Changed
- Changed exact-mode table encoding to store semantic `cols=` and `rows=` data instead of escaped markdown table syntax, dramatically reducing table-heavy pack size.
- Changed compact-mode table parsing to understand structured table records while preserving existing strategy and loss metadata behavior.

### Technical
- Expanded exact/compact/command regression coverage for structured table records and deterministic list-item compaction.
- Bumped cache contracts so exact, compact, and agent reruns refresh stale artifacts after the table/list encoding changes.

## [0.14.0] - 2026-03-08

### Fixed
- Moved agent-mode model and prompt-template defaults out of Ruby and into `ace-compressor` config/protocol defaults.
- Registered `ace-compressor` template sources under gem-local `.ace-defaults/nav/protocols/tmpl-sources/` so agent prompts resolve via `tmpl://`.
- Rebuilt agent mode as payload-only rewriting over exact output so the LLM rewrites `SUMMARY|`, `FACT|`, and long `LIST|...` values without regenerating `ContextPack` structure or leaking prompt scaffolding into packs.

### Technical
- Added regression coverage for config-driven `agent_model`, `agent_template_uri`, and deprecated `agent_provider` fallback behavior.
- Bumped the agent cache contract to invalidate stale refusal/fallback artifacts from earlier agent-mode implementations.

## [0.13.0] - 2026-03-08

### Added
- Added explicit degraded-success fallback metadata (`FALLBACK|source=...|from=agent|to=exact|...`) for `--mode agent` provider/validation failure paths.
- Added runner/command plumbing for fallback detection and human-readable degraded notices while preserving machine-readable fallback records.

### Changed
- Changed agent failure handling to degrade to exact-mode output with fidelity failure evidence instead of refusal artifacts.
- Changed usage contract/docs to describe agent degraded fallback (`FALLBACK|...`) and exit `0` behavior.
- Changed agent-mode cache manifest contract keying to refresh stale pre-fallback artifacts.

### Technical
- Expanded organism/runner/command regression coverage for degraded agent fallback behavior and zero-exit verification.

## [0.12.0] - 2026-03-08

### Added
- Added a dedicated single-source agent minification prompt template (`handbook/templates/agent/minify-single-source.template.md`) for resource-driven prompt composition.

### Changed
- Hardened `agent` single-source output contract by replacing plan-template prompt composition with a dedicated minification template and stronger success-path fidelity checks.
- Expanded agent-mode validation to reject summary-only output, enforce numeric fidelity, and require compressed output to be smaller than exact baseline.

### Technical
- Added agent-mode regression coverage for required command/example retention, numeric token preservation, summary-collapse rejection, and size gate behavior.

## [0.11.0] - 2026-03-08

### Added
- Added `agent` compression mode with protocol-composed prompt flow (`ace-bundle`), `ace-llm` invocation, and validator-visible concept inventory markers.
- Added `AgentCompressor` organism and targeted tests for pass/fail/provider-unavailable spike behavior.

### Changed
- Extended CLI and compression runner mode contracts to support `--mode agent` routing and mode-aware refusal messaging.
- Updated usage documentation with the single-source agent spike contract, expected output markers, and refusal/fallback guidance.

### Technical
- Expanded command and runner regression coverage for agent-mode acceptance, refusal handling, and metadata contract stability.

## [0.10.3] - 2026-03-07

### Technical
- Applied shine-cycle polish to compact mode internals: added high-level class documentation and replaced table-strategy magic numbers with named constants.

## [0.10.2] - 2026-03-07

### Technical
- Completed fit-cycle review/apply-feedback/release flow for PR #243; no actionable findings remained after feedback synthesis retries.

## [0.10.1] - 2026-03-07

### Technical
- Completed valid-cycle review/apply-feedback/release flow for PR #243; no medium+ correctness findings required code changes.

## [0.10.0] - 2026-03-07

### Added
- Added explicit compact-mode reduction metadata records: `LOSS|...` and `EXAMPLE_REF|...`.
- Added cross-source example deduplication that collapses duplicate examples to references with provenance.

### Changed
- Changed compact table encoding to emit explicit per-table strategy metadata (`preserve`, `schema_plus_key_rows`, `summarize_with_loss`).
- Changed compact table reduction to report data-row-only retained/original counts and preserve sensitive table content.
- Updated compact usage documentation to include the new `TABLE|...|strategy=...`, `LOSS|...`, and `EXAMPLE_REF|...` contract.

### Technical
- Expanded compact organism/command regression coverage for table strategy selection, loss signaling, example-ref collapse, and mimicry-required example preservation.

## [0.9.0] - 2026-03-07

### Added
- Added mixed-source compact-mode behavior with per-source policy classes (`narrative-heavy`, `mixed`, `rule-heavy`) and fidelity/refusal metadata records (`FIDELITY|`, `REFUSAL|`, `GUIDANCE|`).
- Added rule-preservation fidelity checks for mixed documents (`compact_with_exact_rule_sections`) so policy-bearing records can pass compact mode without forced refusal.

### Changed
- Changed compact-mode execution to preserve safe-source output even when other sources refuse and to return non-zero outcome when refusal metadata is present.
- Added compatibility for interface-contract invocations with optional leading `compress` verb (`ace-compressor compress ...`).

### Technical
- Expanded classifier, compact organism, and command test coverage for mixed-doc pass/fail paths, partial-refusal output retention, and refusal-driven exit semantics.

## [0.8.0] - 2026-03-07

### Added
- Added compact-mode narrative policy classification with runtime `POLICY|class=...|action=...` metadata records.
- Added `CompactCompressor` and classifier atoms for `narrative-heavy` aggressive compaction and `unknown` conservative fallback.

### Changed
- Extended CLI/runtime mode support from exact-only to `exact|compact`, including mode-aware validation and dispatch.
- Generalized explicit binary/empty-input error messaging to reflect the active compression mode.

### Technical
- Added compact-mode organism/command/atom tests and regression checks for policy emission, fallback behavior, and size reduction versus exact mode.
- Updated README and usage docs with compact-mode command examples and output contract details.

## [0.7.1] - 2026-03-07

### Fixed
- Emitted each `FILE|...` record inline with its source records so multi-file exact packs have unambiguous file scope.
- Canonicalized prose `Example: ...` markers into `EXAMPLE|tool=...` records instead of leaving them as plain facts.
- Replaced ad-hoc section-derived list records with stable `LIST|section|[...]` output while still promoting problem-context lists to `PROBLEMS|[...]`.

### Technical
- Updated exact-mode regression tests, usage docs, and changelog text to match the finalized ContextPack/3 contract.

## [0.7.0] - 2026-03-07

### Changed
- Migrated exact-mode output to ContextPack/3 with semantic canonical encoding for headings, prose,
  lists, and fenced/table content.
- Introduced section-scoped output (`FILE|`, `SEC|`) and typed semantic records (`SUMMARY|`, `FACT|`, `RULE|`,
  `CONSTRAINT|`, `PROBLEMS|`, `LIST|section|[...]`, `EXAMPLE|`, `CMD|`, `FILES|`, `TREE|`, `CODE|`) in the
  exact-mode wire format.

### Added
- Added a canonical block transformation layer between markdown parsing and pack encoding for deterministic markdown normalization.

### Technical
- Fixed exact-mode source scoping so each `FILE|...` record now directly precedes that source's records.
- Updated tests, CLI help text, and docs to describe the ContextPack/3 contract.

## [0.6.0] - 2026-03-07

### Changed
- Switched exact-mode pack output from verbose `ContextPack/1` key-value records to compact `ContextPack/2` fixed-position records with a source table and implicit section context.

### Technical
- Reduced repeated exact-mode overhead by removing per-record `src=`, `id=`, and `sec=` fields.
- Updated cache keys, tests, and usage docs for the `ContextPack/2` wire format.

## [0.5.0] - 2026-03-07

### Changed
- Switched `ace-compressor` to a single-command CLI: `ace-compressor [SOURCES...]` no longer requires the `compress` subcommand.
- Added `--output` for explicit pack save destinations and `--format path|stdio|stats` for console rendering.
- Default command behavior now writes/read a canonical cache artifact under `.ace-local/compressor` and prints the saved path.
- Reworked `--format stats` into a human-readable summary showing cache state plus original-vs-packed byte and line deltas.

### Technical
- Added canonical cache manifests and metadata sidecars keyed by source content SHA-256 plus mode.
- Reused cached packs for unchanged source sets instead of recompressing on repeat runs.
- Backfill missing stats totals into existing cache metadata on cache hits so older cache entries remain usable.

## [0.4.3] - 2026-03-07
### Technical
- Removed dead `return 0` from `Compress#call` (dry-cli ignores the return value).
- Expanded README with quick-start examples and link to `docs/usage.md`.

## [0.4.2] - 2026-03-07

### Technical
- Removed redundant `uniq` pass in directory traversal — `Find.find` never yields duplicate paths.

## [0.4.1] - 2026-03-07

### Fixed
- Binary files with supported extensions (`.md`, `.txt`) in directories are now correctly skipped during traversal instead of being silently included and producing garbage output.

### Technical
- Added usage documentation (`docs/usage.md`) covering all CLI commands, output format, scenarios, error conditions, and troubleshooting.

## [0.4.0] - 2026-03-07

### Added
- Added explicit unresolved markers for image-only markdown references in exact mode output.
- Added explicit fallback markers for fenced-code blocks in exact mode output.
- Added table-preservation records so markdown tables are represented structurally in output.

### Fixed
- Preserved imperative modality and numeric facts with dedicated command-level regression tests.

### Technical
- Expanded exact-mode command and organism test coverage for unresolved/fallback/table hardening.

## [0.3.0] - 2026-03-06

### Added
- Added exact-mode support for multi-file and directory inputs with deterministic source ordering.
- Added merged pack output with per-record source provenance (`src=...`) and multi-source header metadata.

### Fixed
- Added loud failures for explicit binary inputs and directories with no supported markdown/text files.
- Added duplicate explicit source collapse so repeated paths emit once.

## [0.2.0] - 2026-03-06

### Added
- Bootstrap runnable exact-mode single-file compression path.
