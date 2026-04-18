# Release Install Verification Guide

This guide documents the public install verification job behind
`TS-MONO-001-rubygems-install`.

## Goal

Classify post-release install behavior using real RubyGems installs as one of:

- `SAFE`
- `LAG_DETECTED`
- `METADATA_BROKEN`

## Run The Verification

```bash
ace-test-e2e ace-monorepo-e2e TS-MONO-001
```

The scenario runs normal install first, then full-index fallback, then writes a
classification proof artifact from those outcomes.

## Classification Meaning

| Normal install | Full-index install | Classification | Operator guidance |
| --- | --- | --- | --- |
| exit `0` | any | `SAFE` | Normal install path is safe for onboarding. |
| non-zero | exit `0` | `LAG_DETECTED` | Use `bundle install --full-index` until propagation catches up. |
| non-zero | non-zero | `METADATA_BROKEN` | Treat release metadata as broken; investigate before onboarding-safe claims. |

## Evidence Priority

Use this order when reviewing results:

1. Final install outcomes (normal and fallback exit behavior)
2. Installed gem end state from scenario artifacts
3. Supporting command telemetry (`stdout`, `stderr`, extra captures)
