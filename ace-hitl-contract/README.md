# ace-hitl-contract

Shared provider protocol for ACE HITL request orchestration and delivery adapters. It has no runtime gem dependencies and performs no service, assignment or transport initialization.

```ruby
require "ace/hitl/contract"

ref = Ace::Hitl::Providers::Ref.from_env
result = Ace::Hitl::Providers::DeliverResult.new(ref: ref, state: :delivered)
```

The protocol owns `Ref`, `AskResult`, `DeliverResult` and the provider error hierarchy under `Ace::Hitl::Providers`. Full registry and locked assignment authority remain in `ace-hitl`. Runtime adapters use this leaf package without loading the privileged HITL lifecycle.

Run package tests from the ACE checkout with `bin/ace-test ace-hitl-contract all`.

`Ace::Hitl::Contract::ManagedEnvelope.load(json, expected: {...})` validates
`ace.hitl.managed/v1` and exact expected assignment, attempt and correlation
fields. The installed gem includes `managed.v1.schema.json` and shared examples
under `lib/ace/hitl/contract/examples`. HITL owns envelope semantics; this leaf
contains only the pure wire codec, with no dependency on Herdr, assignment or
the privileged service.

The nested `ace.hitl.ref/v1` reverse address and Hermes `message/v1` retain their
own schemas. A nil reverse address explicitly selects pane-less consumption.
Ordinary payload digests refer to the exact UTF-8 payload bytes. OTP envelopes
contain neither answer bytes nor their digest; folder answers and callback
effects are prohibited for that kind. A non-secret OTP question remains valid.
Effect references identify authorization and result evidence; structural
validation never grants authority or proves business success.

`examples/ingress-checkpoints.json` publishes separate y24 ingress observation
examples: healthy/drained permits only a coverage-backed absence claim; healthy
with unresolved ingress is not drained; unknown has no usable checkpoint. These
transport observations are not native consumption or business effect receipts.
The ingress `received_at` belongs to its accepted transport ingress item.
