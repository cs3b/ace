# Paired reference responsibility map

The leaf owns address syntax, typed pair semantics and wire canonicality. Runtime/Tmux already produces exact native IDs and stays unchanged. Lab and Herdr consume the leaf; they do not gain authority from its syntax.

Leaf fast tests cover accepted Herdr/native pairs, direct/environment normalization, malformed/mixed/cross-field/non-String forms, canonical decimal and length boundaries, and diagnostic-label independence. ManagedEnvelope fast tests require canonical paired wire addresses and preserve classified errors and authoritative expected-binding mismatch refusal. No mocks are needed for pure codec tests.

Consumer tests verify Herdr explicit and persisted parsing uses the same contract and rejects malformed refs before observation/submission; existing Inbox native owner, signed claim and receipt tests remain intact. Lab's accepted reverse projection continues exact recorded IDs. These are source contract tests, not a claim that Herdr executes tmux targets.

Run original focused baseline, maintained fail-before matrix, then repaired focused tests through checkout bin/ace-test with package plus absolute paths. Run full contract, Herdr, HITL and Lab packages sequentially, preserving defaults/deadlines and opt-in skips. No Assign rerun: its source is unchanged and its integrated full gate was just executed. Source independent review precedes integration, and only then does qjz rebuild/run installed SC3.
