# Native observations — draft usage

## Genuine consumed evidence

Protected supervisor runs proposed `ace-herdr inbox observe --event event-1 --format json`. Expected observed only after a genuine exact native consumption fact, with bound event/attempt/generation/digest/runtime and authority-issued evidence reference. No signing or event transition. Codex/Pi extraction candidates and blocking runtime evidence are defined in observation-authority-contract.md; current submit receipts cannot satisfy this.

## Missing or untrusted source

A queue vanishes, matching text appears without exact client identity, or a worker supplies an observation filename. Expected uncertain; signer produces no receipt and runtime is not resent/cleaned up.

## Sign and generation race

Deployment-controlled gad.b signer verifies authority evidence and current canonical event, signs existing y23 bytes with the pinned key, then reconciles through Herdr's event lock and assign's public consumer API. Generation changed after observation/signing refuses stale proof. Positive superseded proves non-consumption and verifies replacement_target before allowing a fresh claim.
