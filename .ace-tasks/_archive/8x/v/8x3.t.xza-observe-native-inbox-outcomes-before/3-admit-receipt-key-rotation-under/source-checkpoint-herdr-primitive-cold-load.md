# Herdr primitive cold-load source checkpoint

Base: `331ddef96`. This checkpoint is independent of the uncommitted v2 direct Inbox work.

The existing `ace/herdr/errors` owns the unchanged generic and executor error hierarchy. The broad Herdr entrypoint requires this owner; Inbox and both executor primitives explicitly require it. No configuration loader, RubyGems exemption, Lab-defined constant, native effect or admission contract was added.

A fresh bounded Ruby child (`--disable=gems,rubyopt`, explicit source/dependency load paths) requires each of errors, Inbox, ProtectedInbox, HerdrExecutor and NativeQueueExecutor separately. It checks error inheritance and TabMaterializationError behavior, and refuses broad `ace/herdr.rb` or Herdr configuration loading. These children only load source; no native clients or service startup are called.

## Executed evidence

- Before repair: `herdr/04f7fb77-4c0d-4156-bf1e-d4250e6466b8`, 1/1 FAIL: standalone errors require raised missing `Ace::Herdr::Error`.
- Final primitive regression plus existing ProtectedInbox and HerdrExecutor tests: `herdr/05e3a224-5ff0-4306-989c-0c629647961d`, 50/117 PASS, seed 3840.
- Inspected pure NativeQueueExecutor methods at lines 28,37,56,67,75,87,98,108,122: `herdr/273c6505-e68e-4a4e-9155-a94da4823f21`, 9/32 PASS, seed 38351. Real process/liveness methods were excluded.
- Exploratory bare Endcap require: `herdr/f54b0c74-dbc7-49b8-8b8b-51e611fc7762` retained FAIL because ServiceEvidence expects prior EvidenceJournal loading. That unsupported independent bare entry is outside this Herdr error repair; the actual Owner source graph supplies the journal. It was removed from the focused regression, not fixed by broad loading.

Reports are retained under this worktree's `.ace-local/test/reports/`. No installed or native acceptance and no whole xza.3 closure is claimed. Independent review remains required before integration.
