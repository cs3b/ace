---
description: "E2E runner input for Forgejo PR delivery lifecycle"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-create.runner.md
    - ./TC-002-ready.runner.md
    - ./TC-003-merge.runner.md
    - ./TC-004-response-loss.runner.md
    - ./TC-005-teardown.runner.md
---

# E2E Test Runner: Forgejo PR delivery lifecycle

Tool under test: ace-git (Forgejo provider, delivery lifecycle)
Required tools: ace-git, git, docker, curl
Workspace root: (current directory)
Disposable server: `$FORGEJO_URL` (container `ace-e2e-forgejo`, Forgejo 8.0)

The scenario setup provisioned users (`e2e-lab`, `e2e-fork`), the base
repository (`e2e-lab/base`), a same-server fork (`e2e-fork/base`), branches
(`feature/canonical`, `feature/forked`), the server configuration
(`.ace/git/config.yml`, server name `e2e-forgejo`), and the `fj` keys file.
The admin API token is in `/tmp/ace-e2e-lab-token` (raw API/curl use).

Execute each goal in order. Record every observation, including failures —
a classified failure with the expected category IS the expected outcome for
the refusal goals; an unexpected crash is not.

## Rules

- Setup ownership belongs to `scenario.yml`; do not re-implement setup.
- Use only the declared tools. All `ace-git pr` calls must pass
  `--server e2e-forgejo` (or rely on `--default-server`).
- Save all artifacts to `results/tc/{NN}/` directories.
- Do not assign PASS/FAIL verdicts in runner output.
- Do not fabricate output; all evidence must come from real command execution.
- The Ruby binary for `ace-git` inside the sandbox is whatever `bin/ace-git`
  resolves to (the sandbox copied `mise.toml`; run it through `bin/ace-git`).

## Artifact conventions

- Save stdout to `{name}.stdout`, stderr to `{name}.stderr`, exit code to
  `{name}.exit` (numeric only).
- For JSON outputs also save the parsed JSON verbatim as `{name}.json` when
  the output is parseable.
