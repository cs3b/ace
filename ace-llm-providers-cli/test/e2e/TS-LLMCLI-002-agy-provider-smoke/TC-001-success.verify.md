# Goal 1 - fixture-backed success

- `results/tc/01/success.exit` is `0`
- `results/tc/01/success.stdout` includes `AGY_OK`
- `results/tc/01/success.stdout` includes `agy`
- `results/tc/01/agy.argv.json` shows:

  - first arg `-p`
  - an `--output-format` / `json` pair
  - a `--model` value matching the `agy:flash` alias target
