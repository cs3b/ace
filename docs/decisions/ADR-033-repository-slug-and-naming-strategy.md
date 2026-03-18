# ADR-033: Repository Slug and Naming Strategy

## Status

Accepted
Date: 2026-03-18

## Context

The ACE project originated under the repository slug `ace-meta` — a working name chosen during early development. As the project matured into a 25+ gem mono-repo with public-facing documentation, the slug no longer reflects the project's identity. The original idea to rename to `agentic-coding-environment` was refined into a structured brand/category positioning: **ACE** as the product brand, **ADE** (Agentic Development Environment) as the broader category.

This ADR formalizes the naming strategy so that downstream implementation tasks (GitHub rename, docs updates, gemspec metadata) can execute without re-deciding naming direction.

## Decision

### Canonical Naming Policy

1. **Canonical brand name**: ACE
2. **Canonical expanded phrase**: Agentic Coding Environment
3. **Canonical category phrase**: Agentic Development Environment (ADE)
4. **Repository slug decision**: `ace` (primary) — fallback order: `ace` → `ace-meta` → `agentic-coding-environment`
5. **Public rationale**: ACE is a short, memorable brand that matches the existing `ace-*` gem namespace and CLI command prefix. The three-letter slug maximizes discoverability and typing efficiency while maintaining perfect brand continuity with the 42-gem ecosystem. The category framing (ADE) positions ACE within the broader agentic development space without conflating brand identity with category language.

### Decision Matrix

Candidates scored on a 1–5 scale. Weights sum to 100%.

| Criterion | Weight | `ace` | `ace-meta` | `agentic-coding-environment` |
|-----------|--------|-------|-----------|------------------------------|
| Brand continuity | 30% | 5 — exact match to gem/CLI prefix | 3 — includes brand but adds `-meta` suffix | 2 — spells out expansion, loses short brand |
| Discoverability | 25% | 4 — short, searchable, may collide with unrelated projects | 3 — unique but opaque `-meta` suffix | 5 — fully descriptive, high SEO value |
| Uniqueness | 20% | 3 — common word, context-dependent | 4 — reasonably unique combination | 5 — highly unique, unlikely collisions |
| Ecosystem fit | 15% | 5 — `ace` prefix matches all gem names and CLI commands | 3 — suffix mismatch with `ace-*` pattern | 2 — no prefix match with ecosystem |
| Migration risk | 10% | 4 — rename required, but no external deps confirmed | 5 — no change needed | 3 — rename required, long URL, typing friction |

**Weighted scores:**

| Candidate | Score |
|-----------|-------|
| `ace` | 5×0.30 + 4×0.25 + 3×0.20 + 5×0.15 + 4×0.10 = **4.25** |
| `ace-meta` | 3×0.30 + 3×0.25 + 4×0.20 + 3×0.15 + 5×0.10 = **3.40** |
| `agentic-coding-environment` | 2×0.30 + 5×0.25 + 5×0.20 + 2×0.15 + 3×0.10 = **3.45** |

**Pass/fail thresholds:**
- Brand continuity: must score ≥ 3 (brand must remain recognizable)
- Migration risk: must score ≥ 3 (migration must be feasible without breaking consumers)
- Overall: weighted score ≥ 3.5 to qualify

**Result:** `ace` scores **4.25**, exceeding the 3.5 threshold and leading by > 10% margin over both alternatives. No tie-breaking needed.

### Naming Invariants

These identifiers are **not** rename targets and must remain unchanged:

- Ruby module namespace: `Ace::*`
- Gem names: `ace-*` (e.g., `ace-review`, `ace-bundle`)
- CLI binary names: `ace-*` (e.g., `ace-test`, `ace-git-commit`)
- Config directory: `.ace/`

## Consequences

- GitHub repository will be renamed from `cs3b/ace-meta` to `cs3b/ace`
- All `spec.homepage` and metadata URLs in 42 gemspecs will update to `https://github.com/cs3b/ace`
- Documentation will use "ACE (Agentic Coding Environment)" as the standard introduction phrase
- Category language ("Agentic Development Environment" / "ADE") appears only in positioning contexts, not in code or package metadata
- GitHub provides automatic redirects from old URLs indefinitely; no back-linking required
- CHANGELOGs and retrospectives retain historical `ace-meta` references unchanged
