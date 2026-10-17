# Independent primitive source review — 2026-10-05

Candidate: `793a21c2f04836f6a6cd94282b7d2e1138781241`. Verdict: **REJECT**. Source remains outside main.

Independent Sol 6.1 review session `review-8x40mu` and root code verification confirmed:

- [ ] P1 `8x40rw7e`: failed mutation staging leaves event files; a later ordinary append can stage and accept those rejected events without their blob. Clean failed transactions and every writer boundary; reproduce failed git-add followed by append.
- [ ] P1 `8x40rw7f`: intent-only state now derives reserved, but resume transitions only running; start reuses that reservation and reconcile refuses it. Implement coherent recovery without inferring no child from absent process_start. Launch abort still requires positive no-execution/no-surviving-writer proof.

Independent supplied tests: 10 tests / 76 assertions, zero errors, receipt `assign/8x40ql` in root-owned `codex-wave5-journal-review`. Review additionally reproduced both failures. Green happy-path tests do not supersede the rejected verdict. Full protected authority and installed acceptance remain unfinished.
