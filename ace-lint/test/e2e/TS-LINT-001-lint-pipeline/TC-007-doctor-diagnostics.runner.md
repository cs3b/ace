# Goal 7 — Doctor Diagnostics

## Goal

Test `ace-lint --doctor` in two environments: a healthy configuration directory and a directory with a YAML syntax error in config. Verify doctor detects and reports the issue.

## Workspace

Save all output to `results/tc/07/`. Capture:
- healthy environment: stdout, stderr, exit code, `pwd`, and config contents
- syntax error environment: stdout, stderr, exit code, `pwd`, and config contents

## Constraints

- Set up two subdirectories: one with valid `.ace/lint/.rubocop.yml` and one with intentionally broken `.ace/lint/.rubocop.yml`.
- Initialize each as a git repo if required.
- Run `ace-lint --doctor` in each subdirectory and capture both outputs separately.
- Capture the effective working directory and the exact `.ace/lint/.rubocop.yml` file contents used in each environment so the verifier can prove the broken config was active.
- All artifacts must come from real tool execution, not fabricated.
