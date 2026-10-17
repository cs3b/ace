# Retrospective — L1.0 state owners and locations

## What went well

- Research first: the parallel audits (old-lab code surface, state ownership,
  active docs) gave a concrete removal boundary before any edit, avoiding a
  speculative rewrite.
- The Captain's two decisions (full L1 scope; private store at
  `.ace-local/overseer/tasks`) removed the only blocking ambiguities early.
- Named task stores reuse the existing manager/root machinery instead of adding
  a second state service: about 200 lines of code and two test files cover the
  contract.
- Implementation and tests landed together; `ace-test ace-task all` is green
  (530 tests) and the store is untracked by construction.

## What could improve

- `ace-task plan` LLM generation stalled past the three-minute guard; the Lead
  fell back to a decision-complete plan artifact. Future runs should cache the
  fallback earlier and record the stall.
- Package README ownership was initially assigned to two workers (L1.0 and
  L1.3); the race was resolved by messages, but the assignment should have
  declared one owner for READMEs from the start.
- The ID scheme is per-root, so a project task and a private task created in the
  same two-second bucket can share an ID; callers must pass `--in _overseer`.
  Documented as a known limitation, worth revisiting in L6.

## Action items

- In future batches, write the plan artifact before dispatching implementation
  workers and include a timeout fallback in the assignment instructions.
- Keep one worker per file family; list READMEs explicitly in the docs scope.
- L6 should decide whether the private store needs a distinct ID namespace.
