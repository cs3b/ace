# Standardized Review Runner Integration - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Ad-hoc Lint Review via CLI Flag

**Goal**: Run a code review that includes both LLM analysis and deterministic lint findings

```bash
ace-review --preset code-deep --lint --pr 123

# Expected output:
# Review session saved: .ace-local/review/sessions/2026-03-06-...
#
# === Review Report ===
#
# ## Deterministic Findings (lint:standardb)
# - WARNING lib/foo.rb:42 - Unused variable `x` [style]
# - ERROR lib/bar.rb:15 - Missing frozen_string_literal [correctness]
#
# ## LLM Analysis (google:gemini-2.5-flash)
# - HIGH: Missing error handling in user_handler.rb:42-55
# - MEDIUM: Consider extracting shared logic...
#
# Findings: 2 lint, 3 LLM | Session: abc123
```

### Scenario 2: Preset-Configured Runners

**Goal**: Configure a preset that always runs lint alongside LLM reviewers

```yaml
# .ace/review/presets/comprehensive.yml
runners:
  - type: llm
  - type: lint
    config:
      format: json

reviewers:
  - name: code-quality
    model: google:gemini-2.5-pro
    focus: code_quality
```

```bash
ace-review --preset comprehensive --pr 123

# Expected output: Combined report with lint + LLM findings (lint always included)
```

### Scenario 3: Lint Runner Unavailable (Graceful Degradation)

**Goal**: Review continues when ace-lint is not installed

```bash
ace-review --lint --pr 123

# Expected output:
# WARNING: ace-lint not found, skipping lint runner
# (proceeds with LLM-only review as normal)
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
