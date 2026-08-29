# Goal 2 - resume flag passthrough

- Create `results/tc/02/bin/agy` as an executable stub that:

  - writes its argv payload to `results/tc/02/agy.argv.json`
  - prints `--help` output and exits `0` when called with `--help`
  - prints a deterministic JSON success envelope when called in print mode

- Run:

  - `env PATH="$PWD/results/tc/02/bin:/usr/bin:/bin" ruby ./ace-llm/exe/ace-llm agy:flash "Continue token AGY_CONTINUE" --no-fallback --json --cli-args "--continue --conversation conv-123"`

- Capture:

  - `results/tc/02/resume.stdout`
  - `results/tc/02/resume.stderr`
  - `results/tc/02/resume.exit`
