# ace-hitl-contract

Shared provider protocol for ACE HITL request orchestration and delivery
adapters. It has no runtime gem dependencies and performs no service,
assignment, or transport initialization.

> **State owner:** none. This is a leaf wire-protocol package. HITL events are
> owned by `ace-hitl` in `.ace-local/hitl/`; adapters and transports own no task
> state. See [docs/lab-flow.md](../docs/lab-flow.md).

```ruby
require "ace/hitl/contract"

ref = Ace::Hitl::Providers::Ref.from_env
result = Ace::Hitl::Providers::DeliverResult.new(ref: ref, state: :delivered)
```

The protocol owns `Ref`, `AskResult`, `DeliverResult` and the provider error
hierarchy under `Ace::Hitl::Providers`. Runtime adapters use this leaf package
without loading the HITL lifecycle.

`Ref.new(session: "$0", pane: "%0")` preserves paired native tmux IDs; existing
Herdr token pairs such as `workspace:1`/`pane:1` remain valid. Native IDs use
canonical nonnegative decimal digits (no leading zero except 0) and must appear
together. Mixed or cross-field IDs, non-String values, non-ASCII-compatible
encodings and components over 128 characters raise `InvalidRefError`. Direct
construction and `from_env` strip outer whitespace; `canonical: true` refuses
it for wire/persisted addresses. Diagnostic `session_source`/`pane_source`
labels never select grammar. Consumers validate the whole pair through the
constructor; component-only `Ref.validate!` is removed. Valid syntax never
grants target authority or adds tmux execution to a Herdr controller.

Run package tests from the ACE checkout with
`bin/ace-test ace-hitl-contract all`.

`Ace::Hitl::Contract::ManagedEnvelope.load(json, expected: {...})` validates
`ace.hitl.managed/v1` and exact expected assignment, attempt and correlation
fields. The installed gem includes `managed.v1.schema.json` and shared examples
under `lib/ace/hitl/contract/examples`. HITL owns envelope semantics; this leaf
contains only the pure wire codec, with no dependency on Herdr, assignment or a
service.

The nested `ace.hitl.ref/v1` reverse address and Hermes `message/v1` retain
their own schemas. A nil reverse address explicitly selects pane-less
consumption. Ordinary payload digests refer to the exact UTF-8 payload bytes.
Structural validation never grants authority or proves business success.

`RequestEnvelope.load` is the closed union of the managed schema and
`OperatorEnvelope` (`ace.hitl.operator-question/v1`). The operator variant fixes
`context: operator-question` and `kind: question`, names the real requester,
project, immutable incarnation/correlation and nonsecret question/input
digests. It rejects assignment, attempt, reverse, effects, OTP and publication
fields. `RequestEnvelope.from_facts` also checks exact attribution, project,
classification and question payload binding. Its operator schema and example
ship as `operator-question.v1.schema.json` and
`examples/operator-question.json`. Structural validation grants no identity or
execution authority.

The opt-in `test/edge/reverse_schema_test.rb` checks the complete published
schema and runtime codec against the native/Herdr and malformed-pair matrix
using Python `jsonschema==4.25.1`. Install that test-only validator in an
isolated venv and supply its Python executable through the runner fixture
`environment.overrides.ACE_HITL_SCHEMA_PYTHON`; the default package run skips
this external validator check.

> **Planned (L2):** the unified report/question/reply interface and configurable
> adapters are not available yet. The managed/operator envelope variants above
> are retained wire types used by existing adapter tests; they are not required
> by the local file-based flow and do not create an authority, journal, or
> second state store.
