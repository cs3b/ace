# Bounded proposal wake source checkpoint

Independent root source review APPROVE (2026-10-07), author commit faa4a221291486b395a129ca56bfb3ec97682e8f. Reviewed fixed bounded runner call, existing declared Herdr dependency, original caller-only marker release, deferred errors, controlled 8/31 evidence and safe-fork design condition. Integration cherry-pick 2d00aa929. The explicit budget is five seconds of execution plus bounded one-second cleanup, not a five-second total-wall guarantee. Retained input publication and child ownership implementation remain open.

Pending independent source review; this implements only qk0.1.1 proposal wake ownership and deferred status, not protected launch/steering/whole child.

ProposalTick now calls maintained Herdr BoundedProcess with structured fixed policy argv, execution deadline5s, stdout/stderr caps65,536 each and owned group cleanup. A process-local mutex/active tuple coalesces concurrent wakes for the same binary/socket/project; no pending mutation, outcome, grant or persistent timer is stored. Only the acquired caller clears its marker. Failure/truncated/non-array/malformed output defers visibly; subsequent explicit wake remains possible, without retrying inside the tick. Existing HITL evaluator/transport/policy owns all decisions and acknowledged-delivery semantics.

The execution deadline is5s. Existing BoundedProcess cleanup is bounded separately to1s and reports unconfirmed cleanup as PostLaunchError; no tighter whole-wall-time promise is inferred. No actual resolver/child/native process was executed in this checkpoint. If whole-wall-time5s is required rather than maintained5s execution plus owned cleanup, that needs explicit reviewed budget allocation rather than hiding cleanup.

Inspected executed selections (all external runner/collector/RepoGuard owners injected): ProposalTick4/20PASS ca373923-5bbc-4f10-bdf3-21193a1b0615 validates exact maintained owner limits, failures, coalescing and original marker release. Status recovery4/11PASS3ce56e61-4d79-4785-91f5-85e0bc3e220a validates watch/next-wake survival, visible deferred outcome and protected readonly status no proposal effect. Total8/31. No broad suites, native/installed/kernel/provider probes.

The separately root-approved fixed loaded Assign CLI fork design is retained in original-cli-child-source-contract.md with required safe single-thread/no-held-lock boundary. No spawning implementation is delivered here. Test responsibility map accompanies this source slice. Ordinary/protected steering and canonical input retention remain open.
