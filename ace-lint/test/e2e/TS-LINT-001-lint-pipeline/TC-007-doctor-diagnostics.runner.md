# Goal 7 — Doctor Diagnostics

## Goal

Test ace-lint's `--doctor` mode in two environments: (1) a healthy configuration directory with valid config, and (2) a directory with a YAML syntax error in config. Verify doctor detects and reports the issue.

## Workspace

Save all output to `results/tc/07/`. Capture:
- Healthy environment: stdout, stderr, exit code
- Syntax error environment: stdout, stderr, exit code

## Constraints

- Set up two subdirectories: one with valid `.ace/lint/.rubocop.yml` and one with intentionally broken `.ace/lint/.rubocop.yml` (bad indentation/YAML syntax).
- Initialize each as a git repo (ace-lint may require it).
- Run `ace-lint --doctor` in each subdirectory and capture both outputs separately.
- All artifacts must come from real tool execution, not fabricated.
