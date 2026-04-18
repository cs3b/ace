# Goal 7 — Doctor Diagnostics

## Goal

Test ace-lint's `--doctor` mode in two documented troubleshooting environments: (1) healthy config, and (2) malformed YAML config. Verify doctor reports both states clearly.

## Workspace

Save all output to `results/tc/07/`. Capture:
- Healthy environment: stdout, stderr, exit code
- Syntax error environment: stdout, stderr, exit code

## Constraints

- Set up two subdirectories and run doctor from inside each one:
  - `valid-config/` with a valid `.ace/lint/.rubocop.yml`
  - `syntax-error/` with an intentionally malformed `.ace/lint/.rubocop.yml`
- The malformed file must be the exact config path that doctor discovers via `.ace/lint/`; do not place the syntax break in `.standard.yml` or any unrelated file.
- Follow the troubleshooting flow documented in `ace-lint/docs/usage.md` for healthy vs malformed config checks.
- Run `ace-lint --doctor` in each subdirectory and capture both outputs separately.
- Persist captures as:
  - `results/tc/07/healthy/doctor.stdout`, `.stderr`, `.exit`
  - `results/tc/07/malformed/doctor.stdout`, `.stderr`, `.exit`
- All artifacts must come from real tool execution, not fabricated.
