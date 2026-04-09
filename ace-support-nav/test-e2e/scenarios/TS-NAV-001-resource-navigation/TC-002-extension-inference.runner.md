# Goal 2 — Extension Inference Chain

## Goal

Test the extension inference fallback chain by resolving three resources that each match at a different level: shorthand extension (`.g.md`), full extension (`.guide.md`), and generic markdown (`.md`). For each resolution, capture the resolved path to prove which extension variant was found.

## Workspace

Save all output to `results/tc/02/`. For each resolution attempt, capture stdout, stderr, and exit code:
- `results/tc/02/shorthand.stdout`, `.stderr`, `.exit` — resolving a resource that exists as `.g.md`
- `results/tc/02/full.stdout`, `.stderr`, `.exit` — resolving a resource that exists only as `.guide.md`
- `results/tc/02/generic.stdout`, `.stderr`, `.exit` — resolving a resource that exists only as `.md`

## Constraints

- Use `ace-nav` with the `guide://` protocol to resolve resources without explicit extensions.
- The sandbox fixtures include: `markdown-style.g.md`, `coding-standards.guide.md`, `quick-reference.md`.
- Using what you learned from Goal 1, invoke ace-nav for each resource. Do not assume syntax beyond what Goal 1 revealed.
- All artifacts must come from real tool execution, not fabricated.
