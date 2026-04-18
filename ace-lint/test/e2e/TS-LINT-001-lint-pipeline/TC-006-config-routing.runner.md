# Goal 6 — Configuration Routing

## Goal

Test that ace-lint discovers configuration from `.ace/lint/ruby.yml` and routes files to different validators based on group patterns. Also verify that `--validators` CLI flag overrides config, following the public example in `ace-lint/docs/usage.md`.

Set up the documented grouped-validator config at `.ace/lint/ruby.yml`:
```yaml
groups:
  legacy:
    patterns:
      - "**/legacy/**/*.rb"
    validators:
      - rubocop
  modern:
    patterns:
      - "**/modern/**/*.rb"
    validators:
      - standardrb
  default:
    patterns:
      - "**/*.rb"
    validators:
      - standardrb
```

Then lint both `legacy/app.rb` and `modern/app.rb` and verify both succeed. Re-lint with `--validators rubocop` to prove CLI override precedence.

## Workspace

Save all output to `results/tc/06/`. Capture:
- Config-based routing: stdout, stderr, exit code
- CLI override: stdout, stderr, exit code

## Constraints

- Scenario setup copies the fixture tree into the sandbox root, so use `legacy/app.rb` and `modern/app.rb` directly. Do not prefix them with `fixtures/`.
- Scenario setup already installs deterministic validator shims into the sandbox runtime PATH; use the provided environment as-is.
- Create only the `.ace/lint/ruby.yml` config from public docs.
- All artifacts must come from real tool execution, not fabricated.
