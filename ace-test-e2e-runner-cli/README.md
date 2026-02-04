# ace-test-e2e-runner-cli

CLI for running LLM-driven end-to-end tests defined in `test/e2e/*.mt.md`.

## Commands

- `ace-e2e-test --help`
- `ace-e2e-test-suite --help`

## Configuration

Default configuration lives in `.ace-defaults/e2e/config.yml` and is overridden by project/user config via the ACE config cascade.

## Output Formats

Use `--format` to select output style:

- `progress` (default): per-test progress lines + summary
- `progress-file`: minimal dot-based progress
- `json`: structured output with summary

Examples:

```bash
ace-e2e-test ace-coworker --format progress
ace-e2e-test-suite --format progress-file
ace-e2e-test-suite --format json
```
