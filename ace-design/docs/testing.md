# Verification

Run `bin/ace-test ace-design fast` for isolated contract tests and `bin/ace-test ace-design all` for fast plus real Node/browser and isolated installed-gem feature tests. No network or model calls occur in these tests. Missing browser dependencies are a failure, not a skipped pass.

Install the browser runtime as in README, then provision the feature lane's explicit browser cache (independent of ace-test's temporary HOME):

```sh
PLAYWRIGHT_BROWSERS_PATH="$PWD/.ace-local/design/runtime/browsers" npx --prefix .ace-local/design/runtime playwright install chromium
bin/ace-test ace-design all
```

The default monorepo `bin/ace-test-suite` runs the fast lane. Feature tests use temporary sessions and localhost fixtures, verify clean/findings/incomplete reports, preserve existing output, reject traversal/symlink escape, install gems with isolated GEM_HOME, resolve packaged resources and project all packaged design skills to `.agents/skills`. Runner feature tests inject only the LLM boundary and exercise real context snapshots, concurrent slots, partial failures, cancellation, targeted revision, publication recovery and selection hashes. Installed CLI checks include prompt forwarding and a zero-call dry-run. These tests do not certify aesthetic quality.

## Live design benchmark

Six fixed briefs and fixtures live in `handbook/benchmarks`: three sites and three apps. Copy each to separate baseline/candidate sessions; use identical model, environment and fixture bytes. Generate A/B/C, record observed time to first usable comparison, compare hierarchy/composition, request a less dense B and measure the targeted feedback round. Use `handbook/templates/design/benchmark-result.template.md` to distinguish objective checks, human judgments and model judgments. Optional live generation is separate from deterministic package tests and may incur provider cost.

For inspiration, exercise three source states: unchanged revision (no proposal), changed revision (evidenced candidate or explained rejection), unavailable source (preserve successful revision and partial failure). Keep each prior decision and dedupe repeated proposals. A proposal with unexecuted comparative checks remains experimental. This release supplies the workflow and reproducible assets; it does not assert a measured aesthetic improvement over competitors.
