# Intent runner verification — 2026-10-16

## Release review follow-up

Two completed review rounds cover complementary runtime and contracts scopes, using
`pi:zai/glm-5.3:high` through `role:review-default`. All confirmed findings were fixed;
the proposed WCAG tag change was rejected after checking the pinned axe-core rule
inventory. Third-round and final delivery status are recorded on PR #373.

The release check executed all 51 packages: 46 passed, 5 failed (12,198 passed tests,
42 failures/errors, 42 skips). A provider cancellation test raced an incomplete PID
marker; its marker publication is now atomic, and the provider package rerun passed
456 tests including 11 skips, with 1,151 assertions. The four other failing packages
(`ace-task`, `ace-hitl`, `ace-hitl-hermes`, `ace-lab`) are unchanged from origin/main
32f1dd59. Their failures include macOS path aliases, missing local groups, DNS/TLS,
unsupported PEERCRED and missing Lab fixture fields; this is source comparison, not
a fresh baseline run, and does not make the monorepo suite green.

## Earlier deterministic verification

`bin/ace-test ace-design all` passed: **72 tests, 574 assertions, zero failures/errors**.
Report: `.ace-local/test/reports/design/1dcf260a-ffa8-487a-b05e-afd5cb5c2f22/`.

Coverage includes intent/source/profile conflicts, default and explicit variant counts,
model and prompt precedence, source/skill snapshots, external completion contracts,
partial publication, resume/revision/selection, profile transactions, browser routing,
JSON output and isolated installed-gem command/skill discovery.

`bin/ace-test-suite` executed all 51 packages: **47 passed, 4 failed**;
12,148 passed tests, 41 failures/errors, 39 skips. Failures were in unchanged
`ace-task`, `ace-hitl`, `ace-hitl-hermes` and `ace-lab`, covering macOS path
canonicalization, local control-group availability, TLS DNS resolution and authority
expectations. This is not a green monorepo result.

## Live mixed-process experiment

Project: `.ace-local/design/intent-smoke` in the implementation checkout.
Session: `8xfnkhoi` under that project's `.ace-local/design/`.
All preparation and variant workers requested `codex:gpt-6.1-sol:medium@rw`;
provider fallback was disabled. One `explore` command used a custom `mixed` preset:
three fast ACE slots and one original UI UX Pro Max slot, concurrency four.

The shared supplied fixture SHA-256 was
`17673cdf7d2b77d1375604748b64e532597334d146618d78e77538c2843f4c86`.
The fixture contains three beaches and a local selection interaction. No real
product data, weather or reviews were invented.

B and C published successfully on the first attempt. A omitted required direction
notes; `resume` retried only A and D, and A then published successfully. B/C and
successful preparation were preserved. The fast prompt now explicitly names the
variant-local notes path.

D fetched and followed the pinned original UI UX Pro Max skill, ran its design-system
and focused search scripts, and produced HTML/CSS/JS plus verification evidence.
Both attempts reported required rendered keyboard, responsive, motion and reflow
checks blocked by provider permissions. The runner rejected both incomplete results;
D was not published and the three ACE results remained available in one gallery.
This validates failure preservation, **not a successful four-result external smoke**.
The catalog therefore retains candidate status and declares the browser requirement.

A B-only revision then succeeded (exit 0 while the overall session remained incomplete).
The previous B publication and its selection were archived; the current selection
was invalidated. A/C attempt counts did not change, D was not retried, and supplied
fixture bytes retained the same SHA-256. Final attempt counts: A=2, B=2, C=1, D=2.

## Independent review

An independent reviewer inspected the implementation and recovery boundaries.
Findings fixed before delivery: internal upstream symlinks, incomplete external
publication, remote session-source snapshots, GIF preview routing, malformed preset
validation and preset discovery through the supported configuration finder.
Final verdict: **approved, no remaining blocker in the reviewed implementation**.
External end-to-end verification remains limited as stated above.
