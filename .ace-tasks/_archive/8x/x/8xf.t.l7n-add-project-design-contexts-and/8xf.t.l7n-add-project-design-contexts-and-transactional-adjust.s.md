---
id: 8xf.t.l7n
status: done
priority: medium
created_at: "2026-10-16 14:08:30"
estimate: 
dependencies: []
tags: [design, cli]
---

# Add project design contexts and transactional adjust

## Accepted plan

Implement the user's approved context tree in `.ace-config/design/`: defaults.md / user.md / generated design.md per context, root → site/app → view/component → named children. Add adjust skills/CLI with explicit library refresh, AI-assisted composition, byte-preserved user files during refresh, staged diff/conflict reports and transactional publication. Freeze the effective profile in new sessions; generate/revise/resume do not re-merge. Add component generation with a minimal interactive host. Keep execution presets in `.ace/design/`.

User decisions are retained verbatim in effective documents as authoritative instructions. Explicit prompt updates append to the user's decision history; only explicit newer decisions supersede earlier ones. This preserves original intent text rather than trusting a model rewrite. Agent synthesis resolves clear overrides and reports ambiguity. Files are project assets, not a sandbox.

## Acceptance

- [x] Context defaults, selection, inheritance, custom descendants and freshness checks.
- [x] Adjust CLI/skills, reports, refresh preservation, conflicts/manual edits and transactional recovery.
- [x] Immutable session assumptions and component variants.
- [x] Installed discovery, docs, deterministic tests and live smoke.
- [x] Independent review and existing PR updated.
