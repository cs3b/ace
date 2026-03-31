# Goal 3 — Full-Index Fallback Install

## Goal

Run `bundle install --full-index` in the sandbox and capture the outcome. This tests the fallback install path used when RubyGems metadata has not fully propagated after a release.

## Workspace

Save all output to `results/tc/03/`.

## Steps

1. Remove any existing `Gemfile.lock` to ensure a clean resolution.
2. Run `bundle install --full-index` in the sandbox root.
3. Save stdout+stderr to `results/tc/03/fullindex.stdout`.
4. Save the exit code to `results/tc/03/fullindex.exit`.
5. If install succeeds, run `bundle list` and save to `results/tc/03/bundle-list.stdout`.

## Constraints

- Must use `--full-index` flag.
- Do not modify the Gemfile.
- Capture the full output regardless of success or failure.
