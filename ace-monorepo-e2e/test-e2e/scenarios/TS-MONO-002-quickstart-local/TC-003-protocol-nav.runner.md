# Goal 3 — Protocol Navigation

## Goal

Follow quick-start section 6 ("The protocol system") and verify protocol discovery is
functionally available from the local project.

## Workspace

Save all output to `results/tc/03/`.

## Steps

1. Discover workflows:
   ```bash
   ace-nav list 'wfi://*' > results/tc/03/nav-wfi.stdout 2> results/tc/03/nav-wfi.stderr
   echo $? > results/tc/03/nav-wfi.exit
   ```
2. Discover guides:
   ```bash
   ace-nav list 'guide://*' > results/tc/03/nav-guide.stdout 2> results/tc/03/nav-guide.stderr
   echo $? > results/tc/03/nav-guide.exit
   ```
3. Inspect sources:
   ```bash
   ace-nav sources > results/tc/03/nav-sources.stdout 2> results/tc/03/nav-sources.stderr
   echo $? > results/tc/03/nav-sources.exit
   ```
4. Build the project bundle context:
   ```bash
   ace-bundle project > results/tc/03/bundle-project.stdout 2> results/tc/03/bundle-project.stderr
   echo $? > results/tc/03/bundle-project.exit
   ```

## Constraints

- Use only `ace-nav` and `ace-bundle` commands as documented in quick-start.md.
- Do not fabricate output.
- Keep all output artifacts under `results/tc/03/`.
