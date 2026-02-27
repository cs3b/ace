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

Optional final synthesis can generate a last-mile report:

```bash
ace-sim run \
  --preset validate-idea \
  --source path/to/source.md \
  --provider glite \
  --synthesis-workflow wfi://task/review-work \
  --synthesis-provider claude:haiku
```

See `docs/usage.md` for full usage.
