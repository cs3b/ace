# Goal 2 Verification - Cache clear lifecycle for ace-models

## Expectation

`ace-models clear` succeeds and removes seeded cache files under the configured
`XDG_CACHE_HOME` path.

## PASS Criteria

- `results/tc/02/clear.exit` is `0`
- `results/tc/02/clear.stdout` includes `Cache cleared successfully`
- `results/tc/02/pre-cache-state.txt` lists `api.json`
- `results/tc/02/post-cache-state.txt` does not list `api.json`
