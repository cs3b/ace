# Goal 1 - fixture-backed success

- Create `results/tc/01/bin/agy` as an executable stub that:

  - writes its argv payload to `results/tc/01/agy.argv.json`
  - prints `--help` output and exits `0` when called with `--help`
  - prints a deterministic JSON success envelope when called in print mode

- Run:

  - `env PATH="$PWD/results/tc/01/bin:/usr/bin:/bin" ruby ./ace-llm/exe/ace-llm agy:flash "Return token AGY_OK" --no-fallback --json`

- Capture:

  - `results/tc/01/success.stdout`
  - `results/tc/01/success.stderr`
  - `results/tc/01/success.exit`
