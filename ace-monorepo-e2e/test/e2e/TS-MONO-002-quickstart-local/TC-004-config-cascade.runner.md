# Goal 4 — Configuration Cascade

## Goal

Follow quick-start section 7 ("Customization") and verify project-level config and prompt
overrides are loaded and discoverable in the workspace through public command
surfaces only.

## Workspace

Save all output to `results/tc/04/`.

## Steps

1. Create project-level git config override:
   ```bash
   mkdir -p .ace/git
   cat > .ace/git/commit.yml <<'EOF'
   max_subject_length: 72
   body_wrap: 80
   EOF
   echo .ace/git/commit.yml > results/tc/04/override-path.txt
   cat .ace/git/commit.yml > results/tc/04/override-content.txt
   ```
2. Run `ace-config diff --file .ace/git/commit.yml` to confirm local override visibility.
   ```bash
   ace-config diff --file .ace/git/commit.yml \
     > results/tc/04/config-diff.stdout 2> results/tc/04/config-diff.stderr
   echo $? > results/tc/04/config-diff.exit
   ```
3. Create project-level prompt override:
   ```bash
   mkdir -p .ace-handbook/prompts
   cat > .ace-handbook/prompts/git-commit.system.md << 'EOF'
   You are a commit message generator.
   Always use conventional commits format.
   EOF
   echo .ace-handbook/prompts/git-commit.system.md > results/tc/04/prompt-path.txt
   cat .ace-handbook/prompts/git-commit.system.md > results/tc/04/prompt-content.txt
   ```
4. Validate project override visibility with public CLI output:
   ```bash
   ace-config diff --file .ace/git/commit.yml \
     > results/tc/04/config-visibility.stdout 2> results/tc/04/config-visibility.stderr
   echo $? > results/tc/04/config-visibility.exit
   ```
5. Validate prompt override discoverability through public prompt loading:
   ```bash
   ace-bundle prompt://git-commit.system \
     > results/tc/04/prompt-bundle.stdout 2> results/tc/04/prompt-bundle.stderr
   echo $? > results/tc/04/prompt-bundle.exit
   ```
6. Produce an explicit cascade check summary:
   ```bash
   printf "commit.yml=%s\n" "$(cat results/tc/04/override-path.txt)" > results/tc/04/cascade-check.txt
   printf "prompt=%s\n" "$(cat results/tc/04/prompt-path.txt)" >> results/tc/04/cascade-check.txt
   printf "config_visibility_exit=%s\n" "$(cat results/tc/04/config-visibility.exit)" >> results/tc/04/cascade-check.txt
   printf "prompt_bundle_exit=%s\n" "$(cat results/tc/04/prompt-bundle.exit)" >> results/tc/04/cascade-check.txt
   ```

## Constraints

- Use only public CLI commands (`ace-config`, `ace-bundle`, `ace-handbook`)
- Do not fabricate output.
- Keep all output artifacts in `results/tc/04/`.
