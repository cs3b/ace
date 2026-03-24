# ace-search README Review Summary

## ace-search specific changes

### Content fixes
1. **DWIM jargon**: Expanded "DWIM" to "DWIM — Do What I Mean" on first use in README intro paragraph. The acronym appeared 10+ times across user-facing docs without ever being spelled out.
2. **Preset path**: `docs/getting-started.md` said presets are defined in `.ace/search/config.yml` but they are individual YAML files in `.ace/search/presets/<name>.yml`. Fixed to reference the shipped `code` preset and correct directory.

### No changes needed
- **Gemspec**: summary/description already match README tagline
- **docs/usage.md**: complete CLI reference, no issues
- **docs/handbook.md**: skills and workflow tables accurate
- **Layout**: already follows new pattern (centered header, badges, nav, GIF, intro, How It Works, Use Cases, footer)

## Checklist observations

| Check | Result |
|-------|--------|
| Stale terminology | Clean — no renamed concepts |
| Gemspec matches README | Already aligned |
| Broken doc cross-links | All resolve correctly |
| Undocumented executables | Only `ace-search`, fully documented |
| False feature claims | All features verified in implementation (`--hybrid`, `--fzf`, presets, git scoping) |
| Self-referential links | None |
| Dead anchor links | None |
| Jargon without definition | **DWIM** — fixed |
| Platform constraints | Prerequisites (rg, fd) properly in getting-started.md |
| Status output example | GIF covers this; no inline output example added (low priority) |

## Checklist refinement

This was the cleanest package reviewed so far. The checklist caught the DWIM jargon and preset path issues. No new checklist items to add from this review.
