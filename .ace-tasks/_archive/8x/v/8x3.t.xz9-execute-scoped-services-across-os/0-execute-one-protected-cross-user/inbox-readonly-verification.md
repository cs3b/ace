# Local retained inbox verification checkpoint — 2026-10-05

Independent review approved `073ec3a7e181c03fc06ce5ea800340b02f600baa`, integrated at `0786c817ae1d426ed2d8639d56450a55016a7083`. The read-only reconciliation API requires a nonnil exact registration and verifies retained signed settlement without a state transition. Initial rejection and regression remain in the evidence directory.

- Independent final tests: 50 tests / 307 assertions, execution `549e1c60-0d18-4400-90e0-ea7d20077848`.
- Herdr all: 476 tests / 1,638 assertions, execution `ec4bed17-84a4-4e32-8e56-d6e23e7b62a4`.
- Combined suite on the exact integration revision: 11,252 passed / 24 skipped / zero failures or errors / 34,482 assertions. All 51 completion records match their detailed summaries, with unique execution and entry IDs. See `evidence/inbox-readonly/combined-suite-manifest.json`.

This checkpoint does not enable canonical Endcap handlers or protected startup. Subsequent consumer work identified that the existing shared lock path could create a missing lock; strict no-create retention locking and its refusal regression are being added before consumer acceptance. This bounded checkpoint is not whole-task completion or installed proof.
