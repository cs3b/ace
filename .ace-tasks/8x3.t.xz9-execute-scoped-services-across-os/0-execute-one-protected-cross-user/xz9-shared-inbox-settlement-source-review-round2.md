# Shared Inbox settlement source review — corrected round

Exact frozen SHA: `07ee624430518909945eb4fa2b970c386a096821`, cumulative shared core atop previously approved consumer `943444bcc28b3387d825a45624e6ef3ca99c9a0c`. Verdict: **APPROVE bounded source checkpoint**. No remaining actionable finding found in this delta.

The original REQUEST CHANGES at `f44062226250f1cc8823bc7540b97e417013a8bd` and failed receipt `d7eb1077-89f8-41c4-8780-93b0aac614e2` remain historical evidence. Correction decodes every existing live/archive copy under the original no-create event lock; checks filename/event identity and inbox attribution; refuses missing, malformed or differing decoded records. Identical records with different JSON formatting are accepted. Thus a favorable live copy no longer hides corrupt or conflicting retained archive data.

Independent execution in isolated reviewer worktree:

`bin/ace-test ace-assign feat /Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/.ace-local/review/inbox_inventory_boundary_test.rb`

**23 tests / 137 assertions / 0 failures / 0 errors**, immutable receipt `913cc39b-e505-4b22-bfa4-31fba220aa15`. This includes the actual-RSA signed consumed corrupt-archive regression that failed on the original candidate, plus inherited checkpoint tests covering malformed archive, different attempt/claim, identical reformatted copy, missing no-create lock, archived positive settlement, empty set, unregistered retention, canonical corruption and incomplete/superseded settlement. Tests use a real canonical Git journal and real temporary retained files; controlled identity/endpoint fixtures do not establish installed acceptance.

The helper remains source-owned, with no new wire operation or fabricated peer. It verifies the supplied attempt events from the selected immutable commit, shared canonical provenance and current signed consumed/completed claim. Caller must hold lifecycle exclusion and use that snapshot in eventual journal CAS; this is not a self-contained fresh-release operation. Scope-owner integration, finish/recover/startup and full installed acceptance are outside this verdict. No broad duplicate suite or native probes were run; no production source changed during review.
