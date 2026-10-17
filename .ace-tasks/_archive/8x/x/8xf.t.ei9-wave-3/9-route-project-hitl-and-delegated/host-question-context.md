# Host operator question context — remaining .9 join

Source inspection after multi-project routing implementation found an additional
production adoption gap. Domain lab-hitl-channels.py cmd_ask accepts a channel,
question, plan/options and stable request ID; it represents genuine host operator
questions outside managed Assign attempts. The installed host groups lab-config
and omarchy must keep this bidirectional behavior.

Current generic Lifecycle::Store#create and proposal_create require real managed
assignment/attempt binding (Store#validate_binding_ids!, Proposals#proposal_revision).
Hermes validates ManagedEnvelope before publishing questions. Merely starting
one lifecycle service per host project therefore cannot preserve this host ask
surface. Synthetic task/assignment/attempt IDs would be a false execution claim
and are explicitly forbidden. New channels/v2 routing alone does not close .9.

Use the existing generic HITL request/lifecycle owner to represent an explicit
operator question context authenticated by actual kernel principal and installed
project scope, or bind to a real canonical project-command execution when one
exists. Keep execution-bound requests and authority checks intact; an unassigned
question cannot authorize a managed merge/publication. No second request ledger,
Python authority implementation or poller is permitted. Domain adapters configure
and invoke the public owner API; preserve old unresolved questions and history.

Before one-poller handoff prove real host ask→question→exact Captain Reply→correct
project answer through every existing group alongside ACE mTLS. Startup must
refuse missing authority; paused execution intent does not silently remove a
communication route. Source-level fake lifecycle tests are not this acceptance.
