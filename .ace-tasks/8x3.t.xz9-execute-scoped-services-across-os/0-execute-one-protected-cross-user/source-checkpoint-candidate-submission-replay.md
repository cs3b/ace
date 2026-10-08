# Candidate submission exact replay — bounded source checkpoint

2026-10-08. Existing Endcap owner only; no new wire operation or counter.
Public producer additions remain a separate uncommitted successor.

The existing pre-transfer authorization compared the original expected candidate
counter to the newly admitted current counter before JournalMutation could return
its immutable replay. An exact accepted retry therefore conflicted. The existing
submit_candidate convention is expected CURRENT candidate generation (zero before
first candidate), returning current+1; it differs from authority CAS generation.
The readiness candidate's earlier positive/new-generation wording was incorrect
and is corrected in its separately reviewed successor, not in the wire owner.

The repair authenticates the live original worker/launcher before recognizing an
exact accepted mutation. Existing mutation_result authenticates its operation,
assignment/attempt and complete parameters digest, including raw transfer
SHA/length. The original accepted-commit normalized bundle is read with the
existing bounded_blob owner and compared to retained candidate metadata. Actual
TransferCodec and CandidateTransfer still verify/re-admit the raw body; dispatch
compares resulting normalized head/tree/SHA/length before immutable replay. Raw
upload SHA and re-exported normalized bundle SHA are deliberately distinct. Fresh
CAS counter validation and current role/incarnation/terminal guards are unchanged.
Malformed retained metadata becomes typed evidence_unavailable, never acceptance.

Executed isolated actual Client/Server/Router/Git test:
`bin/ace-test ace-assign/test/feat/protected_candidate_replay_test.rb`
PASS1 test/19 assertions,22.21s,seed23391, report
assign/e9c664be-2ae1-4c4c-b627-4575cc0caf01. The retained raw report confirms the selected method and seed.
It covers first0→1, next1→2, old exact replay after a newer candidate, changed raw
bundle under same ID, fresh stale counter, replaced same-UID birth and dead worker;
ref remains unchanged for refusals/replay. Source gate only: kernel/installed
artifact directory facts injected, ordinary temp Git and real sockets. No native,
root/systemd/process-identity/installed probes or deadline increase.

Preserved earlier public-producer evidence: dc269545 one actual candidate replay
conflict (existing source defect; signed Inbox case passed); bdfb4155 failed new
check incorrectly compared raw upload SHA to normalized bundle SHA. That added
check was corrected to separate raw parameters binding from normalized admission.
Final broader public composition eb9b59e7 passed4/172 in184.325s, but belongs to
separate producer successor, not this checkpoint. No whole xz9.0/family closure.
Independent exact source reviewer verdict is required before integration.
