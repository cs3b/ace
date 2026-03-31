# Goal 2 — Normal Bundle Install

## Goal

Run `bundle install` in the sandbox and capture the outcome. This tests whether ACE gems resolve from RubyGems.org through the standard install path.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Run `bundle install` in the sandbox root.
2. Save stdout+stderr to `results/tc/02/install.stdout`.
3. Save the exit code to `results/tc/02/install.exit`.
4. If install succeeds, run `bundle list` and save to `results/tc/02/bundle-list.stdout`.

## Constraints

- Do not use `--full-index` — that is tested in Goal 3.
- Do not modify the Gemfile.
- Capture the full output regardless of success or failure.
