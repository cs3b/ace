# ace-sim

Standalone file-chained simulation runner for ACE.

## Quick Start

```bash
ace-sim run \
  --preset validate-idea \
  --source path/to/source.md \
  --provider codex:mini \
  --dry-run
```

Preset defaults can be overridden by explicit CLI flags (`--steps`, `--provider`, `--repeat`, etc.).

See `docs/usage.md` for full usage.
