# Goal 4 — Configuration Cascade

## Goal

Follow quick-start section 7 ("Customization") and verify project-level config and prompt
overrides are loaded and discoverable in the workspace.

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
4. Validate effective config resolution from `.ace`:
   ```bash
   ruby -I ace-support-config/lib -e '
     require "ace/support/config"
     resolver = Ace::Support::Config.create(config_dir: ".ace", defaults_dir: ".ace-defaults", gem_path: "ace-git-commit")
     config = resolver.resolve_namespace("git", filename: "commit")
     puts "resolved-source=#{config.source}"
     puts "max_subject_length=#{config.data["max_subject_length"]}"
     puts "body_wrap=#{config.data["body_wrap"]}"
   ' > results/tc/04/cascade-resolution.stdout 2> results/tc/04/cascade-resolution.stderr
   echo $? > results/tc/04/cascade-resolution.exit
   ```
5. Produce an explicit cascade check summary:
   ```bash
   printf "commit.yml=%s\n" "$(cat results/tc/04/override-path.txt)" > results/tc/04/cascade-check.txt
   printf "prompt=%s\n" "$(cat results/tc/04/prompt-path.txt)" >> results/tc/04/cascade-check.txt
   ```

## Constraints

- Use only `ace-config`, `ace-handbook`, and `ruby` command-line tools
- Do not fabricate output.
- Keep all output artifacts in `results/tc/04/`.
