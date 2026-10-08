# Prepared delivery composition candidate

Scope: qkb.1 SC2/SC7 source composition, not installed acceptance or a new
create/update/ready authorization decision. Merge uses the existing exact service
authorization and approved candidate owners.

The current PreparedWorkBuilder captures only the selected fork root and its
descendants. Outer preset create-pr/ready steps are not admitted to that worker.
The fixture will select a reviewed project preset before registration, through
the existing PresetLoader/TaskAssignmentCreator/PresetExpander ownership, with a
fork root and an explicit protected-merge child within that root. Its immutable
step body consumes the maintained protected delivery instructions. No graph
expansion, step injection or move to another attempt occurs after registration.

The actual PreparedWorker fetches that captured graph, activates its original
queue and invokes the maintained provider launcher. The controlled provider starts
the selected merge child through the actual PreparedQueue/AssignmentExecutor,
then performs candidate submission and independent review in the same original
attempt. It selects fresh authority generation only for the first new service
request and retains the complete request parameters and bytes for exact replay.

Public sequence:

1. `ace-lab service request` with project/assignment/attempt/mapping/scope/service,
   exact approved head/candidate generation, original authority generation,
   explicit authorization, stable request ID and bounded input FILE.
2. `ace-lab service status` with the retained original request and exact selectors.
   Uncertain or unavailable status does not finish the queue step or resend effects.
3. `ace-assign delivery --operation merge` with the same original selectors,
   service request, input digest and target; the existing coordinator verifies
   canonical imported result and delivery event without executing merge again.
4. Only succeeded canonical delivery permits the actual Executor to finish that
   child. The test verifies one provider effect, one accepted delivery event,
   unchanged ref on consumption/replay and captured step bytes despite source edits.

Reuse ProtectedServiceBoundaryFixture and the existing neutral merge producer
boundary. Extract reusable test helpers from the concrete service fixture only
after its author freezes SC5, preserving its existing tests. OS/kernel facts and
remote provider calls are injected; canonical clients, sockets, journal, handler,
queue and workflow command dispatch remain actual maintained owners. No native,
installed or privileged probes.

## Independent direction review — 2026-10-08

Root reviewed this composition against `PreparedWorkBuilder`'s actual immutable
fork-descendant selection and qkb.1 SC2/SC7. Direction approved: keep the original
attempt and candidate, compose the delivery child before registration, and reuse
the public receiver and canonical consumer. Implementation must use maintained
shipped workflow instructions, not fixture-only command prose. A refused or
uncertain delivery must leave the child unfinished; replay preserves the original
parameters. This is approval of the implementation direction, not code acceptance,
task promotion, installed acceptance, or a decision on protected PR ordering.
