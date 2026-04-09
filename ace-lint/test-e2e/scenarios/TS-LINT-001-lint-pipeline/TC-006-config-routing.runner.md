# Goal 6 — Configuration Routing

## Goal

Test that ace-lint discovers configuration from `.ace/lint/ruby.yml` and routes files to different validators based on group patterns. Also verify that `--validators` CLI flag overrides the config.

Set up the following config at `.ace/lint/ruby.yml`:
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

Then lint both `legacy/app.rb` and `modern/app.rb` and verify both succeed. Then re-lint with `--validators rubocop` to prove CLI overrides config.

## Workspace

Save all output to `results/tc/06/`. Capture:
- Config-based routing: stdout, stderr, exit code
- CLI override: stdout, stderr, exit code

## Constraints

- Use the existing `fixtures/legacy/app.rb` and `fixtures/modern/app.rb` paths and create only the `.ace/lint/ruby.yml` config required for routing.
- All artifacts must come from real tool execution, not fabricated.
