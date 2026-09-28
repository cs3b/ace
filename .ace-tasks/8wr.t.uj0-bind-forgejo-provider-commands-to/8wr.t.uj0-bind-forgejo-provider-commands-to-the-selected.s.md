---
id: 8wr.t.uj0
status: pending
priority: medium
created_at: "2026-09-28 20:21:07"
estimate: 
dependencies: []
tags: [forge-neutral]
---

# Bind Forgejo provider commands to the selected server repository

## Behavioral specification

Parent: `8wr.t.qk1` (follow-up from qk1.0 delivery review, feedback `8wruavkr` Forgejo half and `8wruavkw`).

Input: a Forgejo server selection and a PR lifecycle/cleanup operation. Process: bind every `fj` invocation to the resolved server's repository (equivalent of GitHub's `--repo HOST/OWNER/REPO`) and, when the real `fj` surface exposes merge-commit evidence, feed it into cleanup proof. Output: `--server NAME` selections can never be silently retargeted to the checkout's repository; Forgejo cleanup gains authoritative merge-commit proof where `fj` provides it.

### Success criteria and verification

1. Every `fj` read/mutation command in `ace-git-forgejo` passes the resolved server's repository identity explicitly, or the provider refuses with a classified failure when the CLI cannot express it. Test with scripted runners asserting exact argv.
2. Forgejo cleanup proof uses authoritative merge-commit evidence when `fj` exposes it; without it, the conservative retain behavior is unchanged. Test classification end-to-end with a fake runner.
3. Verify against the real `fj` installed on the lab (`fj --help` per subcommand) before relying on any newly assumed flag; record the observed surface in this task folder.

Run `ace-test ace-git-forgejo all`, `ace-test ace-git-worktree all`, then `ace-test-suite`. Part of the qkc authorized endpoint matrix.
