---
id: 8wp.t.qm5
status: done
needs_review: false
priority: high
created_at: "2026-09-26 17:44:36"
estimate: 
dependencies: []
tags: [hitl, ci]
---

# CI: run test suite as non-root user in container (act runner euid 0 violates no-root contracts)

## Settlement note

MOOT: CI removed systemically 2026-09-26 (runner deleted, forgejo actions off; policy 'we run test - we merge - done'). Local builders already run as non-root - not an issue. Closed per top-overseer audit addendum; see the Captain's merge-policy decision in AGENTS.md.
