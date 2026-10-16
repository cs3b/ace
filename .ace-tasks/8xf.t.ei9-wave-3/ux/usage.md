# Wave 3 operating scenarios

Semantic agent/API contracts below are requirements, not invented executable CLI.
Bind to current public ACE tools after effective resolution; document final syntax
in owning package usage. No local machine path or external repository is required.

## Cold start and scoped delegation

```text
configure_project(profile) -> KEPT|CREATED|UPDATED|BLOCKED + effective paths/digests
discover(project, workflow)
 -> inputs, outputs, completion, operations(entrypoint, scope, executor, readiness,
                                          result/status/recovery)
resume(project, objective) -> adopted Assign refs + actual snapshot + next action
```

Project owner selects purpose and authorized executor separately. Specwriter does
draft→self-check→independent review→integration in its own worktree; reviewer
formal APPROVED readback is actor/state/SHA, not merely local report. Worker and
reviewer launch receipts match configured Pi defaults or explicit exception.
Missing capability blocks that operation while independent eligible work proceeds.

## Queue and real execution

```text
queue(project) -> objective, criteria, dependencies, next_action, blocker, Assign refs
submit_integrate(repo, pr, expected_head, expected_base, review, authority, input_digest)
 -> request_id, canonical_attempt, admission
status(request_id) -> ready-not-dispatched|accepted-not-started|running|uncertain|terminal
```

Public ace-task selector must create/list/update exactly `.ace-tasks/overseer/`;
unsupported selector refuses, never default-list fallback. Runtime queue ignored,
durable program/decisions/results versioned. Start proof includes fresh pane/session,
actual executor/cwd and attempt. Prompt transport is not start. Deadline escalates
actual owner once; restart adopts same request. Observe/reconcile/choose/act/record
then idle; native loop/watch, ten-minute progress audit and hourly hygiene.

## Serial merge and wrong-head recovery

First reviewed PR merges via exact accepted-head server guard and actual forge
readback. Only then prepare/rebase second and admit its NEW scoped decision while
receiver stays running. No per-PR host chat/policy edit. Lost response/nil404 stays
uncertain until readback; no repeat. Initial independent review plus documented
risk-based delta assessment, not automatic full review for each SHA. Intended and
returned PR identity must match; no accidental AGit adoption/force.

## Release and all-consumer installation

```text
prepare_release(selected_cut, project_policy) -> reviewed manifest(source, versions, graph, digests)
publish(manifest, exact_authority, bound_executor_env) -> per-artifact receipts + uncertain set
install(release, consumer_inventory) -> actual versions/CLI/require/route smoke + preservation
```

Each execution has own pane/worktree; canonical branch remains main. Existing
publisher script prepares/queues/skips matching published versions, no parallel
push. OTP project Reply binds fresh challenge/attempt/expiry; value never retained.
Environment-file presence, built artifacts or empty script queue do not prove publish.
Service identity and actual spawn must work under runtime protections, not sudo
assumptions. Install user/service/coordinator/project bundles and persistent locks;
verify old runtime pin separation. Preserve results before pane/tab/worktree cleanup.

## Selected code sync

```text
sync(source_repo, source_ref, target_repo, target_ref, selected_sha, expected_old,
     task_or_release_scope, authority, explicit_tag_policy)
 -> request/start/result + observed_source_sha + old/new_target_sha
```

Safe FF only; inspect symmetric divergence, preserve remote unique work through
reviewed reconciliation. No force/mirror/deletes or automatic tags. Lost response
reads same refs before retry; code sync does not alter issues or create releases.
Missing legacy Work is a binding gap, never fake metadata or infinite queue hold.

## Project conversation and delegated decision

```text
ask(project_channel, context, options, chosen, why, delegated_scope, deadline16h)
 -> correlated proposal/request
reply(request) -> Captain override | delegated decision after deadline | refused/uncertain
```

One shared Hermes retains all groups. Deadline is not new authority. Record sanitized
what/why feedback, no OTP. Restart preserves deadline and once-only effect. Shortening
window is future explicit policy. Wrong-group/expired reply refuses; actual runtime
route is tested separately from source interface.

## Accepted cleanup and second project

Readable workspace/tab labels identify project/task/role-attempt; control uses fresh
stable IDs. Max4 panes; accepted preserved result closes pane and last tab. Worktree
requires separate preservation/no-writer proof, including untracked valuable data.
Cold-onboard second project with same generic assets, config-only differences and
an explicitly authorized demo release if appropriate. One project's denial/restart
cannot mutate or freeze the other's queue. Parent closes only on installed outcomes.
