# Goal 6 -- Setup Commit Fallback

## Goal

Validate the first setup commit path from quick-start guidance: attempt an
intent-based commit, then verify deterministic `-m` fallback remains usable.

## Workspace

Save all output to `results/tc/06/`.

## Steps

1. Prepare staged setup changes:

   ```bash
   printf 'quick-start setup marker\n' >> QUICKSTART_SETUP.md
   git add QUICKSTART_SETUP.md
   git status --short > results/tc/06/pre-status.stdout
   ```

2. Attempt goal-based commit and capture evidence:

   ```bash
   ace-git-commit -i "set up ace tooling" > results/tc/06/goal-commit.stdout 2> results/tc/06/goal-commit.stderr
   echo $? > results/tc/06/goal-commit.exit
   ```

3. Prepare a second staged change for deterministic fallback verification:

   ```bash
   printf 'fallback marker\n' >> QUICKSTART_SETUP.md
   git add QUICKSTART_SETUP.md
   git status --short > results/tc/06/fallback-pre-status.stdout
   ```

4. Execute deterministic fallback commit command:

   ```bash
   ace-git-commit --only-staged --no-split -m "chore: set up ace tooling" > results/tc/06/fallback-commit.stdout 2> results/tc/06/fallback-commit.stderr
   echo $? > results/tc/06/fallback-commit.exit
   ```

5. Capture commit evidence:

   ```bash
   git log --oneline -n 3 > results/tc/06/log.stdout
   git show --name-only --pretty=medium HEAD > results/tc/06/head-show.stdout
   ```

## Constraints

- Use real `git` and `ace-git-commit` execution only.
- Do not fabricate failures or fallback output.
- Keep all artifacts under `results/tc/06/`.
