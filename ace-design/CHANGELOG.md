# Changelog

## [Unreleased]

## [0.2.0] - 2026-10-16

### Added
- Repeatable `--prompt-append`, inherited session briefs and explicit base replacement, with frozen composition and effective dry-run output.
- Intent commands `explore`, `recreate` and `reimagine`, immutable image/URL/session sources, and a unified pinned preset catalog with original external processes and typed artifacts.
- Preset inspection, JSON output, model-free planning, and model-assisted unpublished profile proposals.
- Inherited project contexts with defaults.md, user.md and effective design.md, transactional AI-assisted adjust/refresh, inspectable reports, freshness checks and site/app adjust skills.
- View/component task scopes, packaged context defaults and immutable design assumptions in generation sessions.
- Preset-driven coding-agent generation with shared context/fixtures, per-variant prompts and model assignments, dry-run, status, resume, revision history and explicit selection.
- Site/app exploration, implementation and audit skills with a shared fast feedback process.
- Local session validation and loopback preview, pinned Playwright/axe inspection and runtime doctor.
- Curated contextual cards, six benchmark briefs and an inspiration-to-reviewed-change workflow.

### Changed
- Replace `generate`, `--context` and `--design-context` with intent commands, `--input` and `--profile`; group project rules under `profile show/adjust/refresh`.
- Drive site/app exploration through the CLI runner; declare variable-count session variants and bind selection to both artifact and fixture hashes.
- Compare scaled desktop, tablet and mobile previews with collapsible direction notes.
- Create mockup sessions under `.ace-local/design/<base36-token>/` using ace-b36ts millisecond tokens.
- Give default inspection output directories a unique suffix to avoid same-timestamp collisions.

### Fixed
- Require Node 22.12+ for the pinned inspection dependency and regenerate skills from canonical sources.
- Isolate embedded variants from gallery DOM access while retaining shared fixtures, and return not-found for directory requests.
- Preserve child exit status with surviving descendants, clean up interrupted captures, and reject fractional execution limits.
- Retry readonly profile reads safely when the first publisher creates the transaction lock.
- Validate missing shared inputs before session allocation and provide complete skill metadata and domain-specific benchmark fixtures.
- Reject runner sessions missing their task kind or frozen design digest with an actionable error and omit empty user-decision sections.
- Reuse fresh design ancestors during targeted adjustment and retain the exact published candidate for manual-edit recovery.
- Preserve the original worker failure or interrupt when diagnostic writes fail, and join every worker before releasing the session lock.
- Avoid re-raising a caller-handled exception after a successful run; retain recoverable state when final persistence fails.
- Preserve incomplete browser evidence when browser cleanup fails.
- Report missing, dangling and cyclic session symlinks as actionable session errors.
- Use `.template.md` filenames so all packaged design templates resolve through `tmpl://`.
