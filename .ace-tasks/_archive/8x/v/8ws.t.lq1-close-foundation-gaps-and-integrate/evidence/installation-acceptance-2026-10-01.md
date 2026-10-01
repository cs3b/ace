# Published Installation Acceptance — 2026-10-01 (lq1.1 closure)

## Verdict

**FINAL: pass — classification SAFE — exact-version acceptance pass — findings 0**

- Pipeline: TS-MONO-001 runner+verifier PASS 4/4 (`8x0f3w4`), host completion record present, `status: pass`, no uncertain execution.
- Both install modes (normal + `--full-index`) exit 0 with all 20 manifest packages at exact versions in lockfile, activated receipts, and actually required (loaded) from isolated gem paths.
- Consumer edges proven: ace-bundle / ace-review / ace-task each resolve `ace-git-github` 0.2.0 through their own published dependency edge (`~> 0.2` in the released gemspec), no direct Gemfile entry, `~> 0.2` requirement in the consumer lockfile spec, registry-only sources.
- Supersession verified: 0.44.1→0.44.2 (bundle), 0.56.0→0.56.1 (review), 0.38.0→0.38.1 (task), 0.41.1→0.42.0 (llm), 0.35.2→0.36.0 (providers-cli), 0.40.6→0.41.0 (test-runner-e2e), 0.6.8→0.6.9 (support-cli), 0.27.0→0.27.1 (test-runner), 0.1.2→0.2.0 (github) — none of the old versions appear anywhere.
- Manifest: 20 packages, frozen at `e38b87fe6d04` (schema v1, `.ace-local/release/installation-manifest.json`, immutable copy `installation-manifest.json` here).

## Publication events covered

7 gems published 2026-10-01 09:12 UTC in one operator burst (HITL 8wtc4k):
ace-support-cli 0.6.9, ace-llm 0.42.0, ace-bundle 0.44.2, ace-llm-providers-cli 0.36.0,
ace-task 0.38.1, ace-test-runner-e2e 0.41.0, ace-review 0.56.1.
This closes the 2026-09-29 caveat where published consumers still pinned
`ace-git-github ~> 0.1.1`. Prior proof `release-proof-2026-09-29.md` remains partial
historical evidence (older graph).

## Fixes made during verification (source, merged to main)

1. `install_receipt.rb` UTF-8-safe reads — sandbox goals run under `env -i` where Ruby defaults to US-ASCII.
2. `SafeCapture` output scrubbed to valid UTF-8 — non-UTF-8 CLI output crashed prompt concat (Encoding::CompatibilityError).
3. Verifier artifact section excludes bundler machinery (compact index alone is ~97MB under `--full-index`) with per-file/total budgets.
4. Retry lifecycle: host-side setup state, digest-bound revalidation, runner-owned deletion confinement, metadata invalidation at attempt start.
5. Scenario contract: literal artifact paths declared (validator-exact), LANG injected into `env -i` blocks.

## Boundary

Lab deployment and full system acceptance belong to lab-config gad.a/gad.2. This receipt
proves the published RubyGems dependency graph only — it is not a claim that the Lab is
installed or ready.
