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

## Executed composition checkpoint

The maintained project preset captures the shipped `auto-merge` catalog child and `wfi://assign/drive` instructions inside the selected fork before registration. The same original PreparedWorker fetches that immutable graph, activates its actual PreparedQueue/Executor, and the controlled provider invokes the shared maintained public Lab request/status and Assign Delivery pipeline while that child remains active. Provider transport and excluded kernel/process boundaries are controlled; canonical journal, candidate/review, receiver, socket, receipt import and delivery owners remain actual. No outer preset step or replacement attempt is executed.

Executed positive **1/80 PASS in 28.21s**, report `cf0b4ae5-e6b2-4a62-ad14-784b795ddcbe`: uncertain original status leaves the active subtree incomplete; canonical succeeded delivery and read-only receipt consumption precede child completion. Executed actual authorization denial **1/42 PASS in 21.65s**, report `46e12a78-4abc-442a-9c6a-751c79e25108`: unchanged maintained policy denies the exact request, terminal listener checks prove no effect/claim, provider returns without finishing and PreparedWorker refuses the incomplete queue. An unconfirmed transport response alone is not claimed as denial proof.

The shared pipeline is extracted from reviewed SC5 `7e3717a25`/`e0e4fa906` into test support; no concrete test subclass or duplicate executable pipeline. Earlier retained fixture failures: `14f6f8af` incorrect launcher keyword, `416d71d3` incorrect QueueState accessor; source integration failures `5aecb198`/`1075acae` exposed the shipped nested shell default's literal closing braces rejected by strict instruction rendering. Equivalent separate shell-default assignments remove that ambiguity without relaxing the renderer. Root-cwd loader attempts `596684e0`/`0d25ce86` are not behavior evidence; verified normal package-cwd source commands match the SC5 author's runner boundary. Initial captured-child-only evidence `eb259cdb` is superseded for actual delivery composition by the two proofs above.

Independent source review remains required before integration. This checkpoint does not resolve protected PR create/update/ready ordering, physical cleanup, installed native acceptance or whole-family closure.

Shared-pipeline extraction preserves its default maintained consumer: actual original public Lab request/status + canonical receipt consumption **1/70 PASS in 25.49s**, report `13e6fe01-0d34-4acc-9224-011e0cbf6536`, using the unchanged default hook. All owned handles are terminal; no source changes followed these final three composition runs.
