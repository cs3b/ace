# ace-hitl-contract

Shared provider protocol for ACE HITL request orchestration and delivery adapters. It has no runtime gem dependencies and performs no service, assignment or transport initialization.

```ruby
require "ace/hitl/contract"

ref = Ace::Hitl::Providers::Ref.from_env
result = Ace::Hitl::Providers::DeliverResult.new(ref: ref, state: :delivered)
```

The protocol owns `Ref`, `AskResult`, `DeliverResult` and the provider error hierarchy under `Ace::Hitl::Providers`. Full registry and locked assignment authority remain in `ace-hitl`. Runtime adapters use this leaf package without loading the privileged HITL lifecycle.

`Ref.new(session: "$0", pane: "%0")` preserves paired native tmux IDs; existing
Herdr token pairs such as `workspace:1`/`pane:1` remain valid. Native IDs use canonical
nonnegative decimal digits (no leading zero except 0) and must appear together.
Mixed or cross-field IDs, non-String values, non-ASCII-compatible encodings and
components over 128 characters raise `InvalidRefError`. Direct construction and
`from_env` strip outer whitespace; `canonical: true` refuses it for wire/persisted
addresses. Diagnostic `session_source`/`pane_source` labels never select grammar.
Consumers validate the whole pair through the constructor; component-only
`Ref.validate!` is removed. Valid syntax never grants target/attempt authority or
adds tmux execution to a Herdr controller.

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

The opt-in `test/edge/reverse_schema_test.rb` checks the complete published schema
and runtime codec against the same native/Herdr and malformed-pair matrix using
Python `jsonschema==4.25.1` (Draft202012Validator). Install that test-only validator
in an isolated venv and supply its Python executable through runner fixture
configuration `environment.overrides.ACE_HITL_SCHEMA_PYTHON`; run the absolute
test file with `bin/ace-test ace-hitl-contract ... --config-path /absolute/fixture.yml`.
The default package run skips this external validator check; no runtime gem
dependency or production configuration is added.
