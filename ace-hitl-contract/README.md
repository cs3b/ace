# ace-hitl-contract

Shared provider protocol for ACE HITL request orchestration and delivery adapters. It has no runtime gem dependencies and performs no service, assignment or transport initialization.

```ruby
require "ace/hitl/contract"

ref = Ace::Hitl::Providers::Ref.from_env
result = Ace::Hitl::Providers::DeliverResult.new(ref: ref, state: :delivered)
```

The protocol owns `Ref`, `AskResult`, `DeliverResult` and the provider error hierarchy under `Ace::Hitl::Providers`. Full registry and locked assignment authority remain in `ace-hitl`. Runtime adapters use this leaf package without loading the privileged HITL lifecycle.

Run package tests from the ACE checkout with `bin/ace-test ace-hitl-contract all`.
