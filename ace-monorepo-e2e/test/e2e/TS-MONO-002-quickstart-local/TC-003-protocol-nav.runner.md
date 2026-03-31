# Goal 3 — Protocol Navigation

## Goal

Follow quick-start section 6 ("The protocol system") and verify that protocol resolution and content loading work as documented.

## Workspace

Save all output to `results/tc/03/`.

## Steps

1. Run `ace-nav list 'wfi://*'` and save output to `results/tc/03/nav-wfi.stdout` and exit code to `results/tc/03/nav-wfi.exit`.
2. Run `ace-nav list 'guide://*'` and save output to `results/tc/03/nav-guide.stdout`.
3. Run `ace-bundle project` and save output to `results/tc/03/bundle-project.stdout` and exit code to `results/tc/03/bundle-project.exit`.
4. Run `ace-nav sources` and save output to `results/tc/03/nav-sources.stdout`.

## Constraints

- Use only `ace-nav` and `ace-bundle` commands as documented in quick-start.md.
- Do not fabricate output.
