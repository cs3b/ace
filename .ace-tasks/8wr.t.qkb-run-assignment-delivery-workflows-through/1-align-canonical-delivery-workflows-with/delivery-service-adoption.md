# Required delivery producer and consumer adoption

qkb.0 source prepares neutral workflow entrypoints and assignment catalog consumers.
Do not publish them until qkb.1 removes obsolete names, regenerates normal projections
and proves fresh installed resolution across every listed consumer.

The authorized qjx merge executor is the producer. Its handler consumes the existing
exact scoped ServicePolicy claim and calls the neutral provider merge primitive
with the claimed candidate SHA and PR target. It emits the executor-owned terminal
receipt with native evidence, through the existing service request journal.
The handler must not call worker DeliveryCoordinator#perform(operation: "merge"):
that method consumes a completed receipt and cannot execute its own pending request.

The assignment worker is the consumer. DeliveryCoordinator verifies the completed
service receipt, exact assignment/attempt/project/head/PR resource and observed merged
PR, then appends a delivery result to the same qjl evidence ref. No transport journal,
new grant dialect or credential-derived authorization is introduced.

Required installed gates for qkb.1 and lab-config gad.b adoption:

- Install the actual configured integrator/executor merge handler and exact operation
  grants; source fixtures or injected handlers cannot establish this acceptance.
- Prove worker dispatch -> authorized executor neutral merge -> owned native terminal
  evidence -> worker receipt consumption, with exact SHA and resource throughout.
- Reject absent/wrong grants, stale SHA, altered receipt evidence and uncertain merge;
  preserve uncertainty without blind retry. Red CI alone does not reject integration.
- Prove all new wfi/skill entrypoints resolve outside ACE and old names fail; ship all
  consumer/catalog/projection updates in the same release as their removal.
- Keep publication separately authorized and retain task in progress until these
  executed gates and independent exact-head review pass.
