# Agent Harnesses (Optional)

Use this document when you need a **harness-native** skill tree or integration package for a specific coding agent (Claude Code, Codex CLI, Gemini CLI, OpenCode, Pi, and similar). It is **not** required for the default ACE setup path.

Default first-use setup stays in [Quick Start](quick-start.md): root `AGENTS.md` + `.agents/skills/`.

## When you need this

- Your harness only discovers skills under a native folder (for example `.claude/skills/` or `.codex/skills/`)
- You want harness-specific frontmatter or integration assets from `ace-handbook-integration-*`
- You are migrating from a harness-first layout to the agents-first default (or vice versa)

If agents already load `AGENTS.md` and `.agents/skills/`, you can skip this page.

## Install integration packages (optional)

Add only the provider packages you need:

```bash
bundle add --group "development, test" \
  ace-handbook-integration-claude \
  ace-handbook-integration-codex
# Also available: ace-handbook-integration-gemini,
# ace-handbook-integration-opencode, ace-handbook-integration-pi
```

Then:

```bash
bundle install
```

## Project harness-native skill trees

Default handbook sync writes `.agents/skills/` only:

```bash
bundle exec ace-handbook sync
```

To generate a harness-native projection, pass an explicit provider:

```bash
bundle exec ace-handbook sync --provider claude   # → .claude/skills/
bundle exec ace-handbook sync --provider codex    # → .codex/skills/
bundle exec ace-handbook sync --provider gemini   # → .gemini/skills/
bundle exec ace-handbook sync --provider opencode # → .opencode/skills/
bundle exec ace-handbook sync --provider pi       # → .pi/skills/
```

Canonical skills still live in package `handbook/skills/`. Harness folders are generated projections—do not hand-edit them as source of truth.

## Root guidance files

| File | Role |
|------|------|
| `AGENTS.md` | Primary agent instruction file (default path) |
| `docs/tools.md` | Expanded day-to-day practices and CLI reference |
| `CLAUDE.md` | Thin pointer for Claude Code when present—not a parallel primary guide |

Refresh starters with:

```bash
bundle exec ace-config sync ace-support-core --force
```

## Verify harness projections

```bash
bundle exec ace-handbook status
ls .claude/skills .codex/skills 2>/dev/null
```

Missing harness trees do **not** block default readiness when `.agents/skills/` and `AGENTS.md` are present.

## Related

- [Quick Start](quick-start.md) — default agents-first install
- [Tools Reference](tools.md) — CLI inventory and agent engineering practices
- ADR-027 — canonical skill platform and projection model
