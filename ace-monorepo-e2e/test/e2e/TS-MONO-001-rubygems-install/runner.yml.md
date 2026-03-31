---
description: "E2E runner input for RubyGems install verification"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-discover-gems.runner.md
    - ./TC-002-sandbox-install.runner.md
    - ./TC-003-fullindex-fallback.runner.md
    - ./TC-004-classify-result.runner.md
---

# E2E Test Runner: RubyGems Install Verification

Tool under test: bundle (RubyGems gem resolution)
Required tools: bundle, mise, ruby
Workspace root: (current directory)

Execute each goal sequentially. Goals build on each other — TC-004 uses
outcomes from TC-002 and TC-003 to classify the result.

## Rules

- Setup ownership belongs to `scenario.yml`; the Gemfile is already generated in the sandbox
- Execute each goal in order (1 through 4)
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not assign PASS/FAIL verdicts in runner output
- Do not fabricate output — all artifacts must come from real command execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal

## Artifact conventions

When a goal requires capturing command output:
- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to `{name}.exit`
- The `.exit` file contains only the numeric exit code (e.g., `0` or `1`)
- Summary or analysis files (.md) are optional extras — the raw captures are the primary artifacts
