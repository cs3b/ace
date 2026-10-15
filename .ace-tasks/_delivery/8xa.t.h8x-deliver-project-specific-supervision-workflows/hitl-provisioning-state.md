# HITL provisioning state — h8x acceptance group 3 (updated 2026-10-12, host relay)

- Host is configuring **ace-hitl-hermes** under existing gad.8/gad.b.
- **ace-hitl-hermes 0.2.2** published and installed in the Lab operator
  runtime; **ace-hitl 0.13.1** serve interface confirmed.
- **NOT ACTIVATED**: the actual shared Hermes bot serves lab plus host
  channels, while the published transport selects one lifecycle socket and
  the service one repo authority. Captain topology decision sent via
  Telegram msg2056; existing poller preserved.
- Consequence for 8xahhp acceptance group 3 (real correlated HITL request +
  exact Telegram Reply + callback-wakes-overseer + wrong-permission
  refusal): **BLOCKED(activation gates + topology decision implementation,
  owner host gad.8/gad.b)** — the gem is present; the endpoint/admission/
  activation are missing. Distinction recorded per host correction:
  missing endpoint/admission ≠ missing gem.
- Queue-owner posture: NO HITL-ready claims; NO OTP requests via the
  not-activated path; no transport implementation duplicated from this
  side. This record is the durable reference for the group-3 WAIT state;
  re-evaluation on host activation confirmation.
