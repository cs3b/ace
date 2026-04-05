# Consumer Update Matrix

| Consumer | Required change | Contract locked by spike |
|---|---|---|
| `ace-assign` resolver/catalog/runtime | Enumerate public skills from canonical skill metadata, normalize legacy `skill:`/`workflow:` to `source:`, keep explicit internal `wfi://...` runtime support | Public discovery excludes internal skills; runtime still supports explicit internal sources |
| `ace-lint` schema and validator | Allow capability skills without `skill.execution.workflow`; keep `assign:` limited to workflow/orchestration kinds; validate public/internal discovery constraints where schema can express them | Capability-without-workflow is valid; workflow/orchestration keep workflow binding requirement |
| Provider projection sync | Mirror canonical skill frontmatter without changing assignment ownership semantics | Projections stay consumers of canonical skills, not owners |
| Usage/docs | Describe skill-first public discovery, direct capability skills, and internal-only `wfi://...` execution | Documentation must match resolver and validator behavior |
