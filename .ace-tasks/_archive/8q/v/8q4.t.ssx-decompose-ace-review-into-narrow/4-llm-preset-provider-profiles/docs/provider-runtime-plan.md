# Provider Runtime Plan

## Purpose

This slice adds the missing provider-runtime layer for the composable review architecture.
Reviewer definitions should own review perspective. `ace-llm` presets should own how a
selected model is invoked.

## Core Decision

- `@preset` is a generic `ace-llm` feature, not an `ace-review`-only feature.
- `model@preset` means "use this provider/model target with this named execution profile."
- Review semantics remain in `ace-review` reviewer and pipeline definitions.

## Target Forms

- `alias`
- `provider`
- `provider:model`
- `alias@preset`
- `provider@preset`
- `provider:model@preset`

## Required Behaviors

- Preserve backward compatibility for legacy target forms.
- Resolve provider/model first-class, then attach optional preset behavior.
- Let explicit runtime options override preset defaults.
- Keep `ace-review` stable when target strings include `@preset`.

## Key Compatibility Points

- `ace-review` must pass preset-qualified targets through to `ace-llm`.
- Context-limit lookup must operate on canonical provider/model data, not raw suffixed strings.
- Filenames, slugs, and report labels must remain stable and readable.

## Why This Exists

Without this layer, provider behavior leaks into review configuration as ad hoc knobs or opaque
model strings. With it, review architecture can stay reviewer-centric while still varying runtime
behavior intentionally.
