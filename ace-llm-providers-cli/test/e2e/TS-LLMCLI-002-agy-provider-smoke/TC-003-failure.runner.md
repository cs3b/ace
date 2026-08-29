# Goal 3 - fixture-backed failure

- Create `results/tc/03/bin/agy` as an executable stub that:

  - prints `--help` output and exits `0` when called with `--help`
  - prints a deterministic JSON error envelope and exits `1` for print mode

- Run:

  - `env PATH="$PWD/results/tc/03/bin:/usr/bin:/bin" ruby ./ace-llm/exe/ace-llm agy:flash "Return token AGY_FAIL" --no-fallback --json`

- Capture:

  - `results/tc/03/failure.stdout`
  - `results/tc/03/failure.stderr`
  - `results/tc/03/failure.exit`
