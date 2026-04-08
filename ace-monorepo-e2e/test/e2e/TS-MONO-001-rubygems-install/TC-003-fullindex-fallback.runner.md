# Goal 3 — Full-Index Fallback Install

## Goal

Run `bundle install --full-index` in the sandbox with the same isolated install environment and capture the outcome. This tests the fallback install path used when RubyGems metadata has not fully propagated after a release.

## Workspace

Save all output to `results/tc/03/`.

## Constraints

- Must use `--full-index`.
- Do not modify the Gemfile.
- Capture the full output regardless of success or failure.
- If `fullindex.exit` is `0`, the success branch must always leave these artifacts on disk, even if a proof command fails:
  - `bundle-list.stdout`, `bundle-list.stderr`, `bundle-list.exit`
  - `bundle-env-install.stdout`, `bundle-env-install.stderr`, `bundle-env-install.exit`
  - `version-check.stdout`, `version-check.stderr`, `version-check.exit`
- Missing success-branch artifacts must be treated as a runner failure. Preserve stdout/stderr and `.exit` files instead of skipping them.
