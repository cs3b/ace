# CLI selection and steering retries — readiness amendment

This proposed amendment resolves the target and prompt/stop identity findings in `readiness-review.md`; independent review is required before promotion. It reuses current Assign operation owners and introduces no execution ledger.

## Mode and exact target

For `work-on` and `status`, explicit `--project PROJECT` selects protected mode. Omitting project preserves ordinary local mode; `--agent` without project refuses. Failure resolving a protected project or mapping never falls back to local execution. Status inventory is runtime-independent. For launching, an explicit `--runtime` overrides existing `overseer.config.runtime` (default `auto`); protected auto selects the delivered protected Herdr capability and refuses if unavailable. Explicit protected tmux refuses before allocation. Ordinary local auto retains the existing runtime resolver. Runtime names never select execution authority.

Protected `prompt`, `stop` and `review` require explicit `--project`, `--agent`, `--assignment` and `--attempt`. Agent is the literal mapping ID. Validate the entire tuple through the current authorized inventory and original binding; never choose the newest attempt or first matching assignment. Wrong project/mapping association, missing selection and ambiguity refuse before mutation. The former `--work`/lab forwarding interface is removed. `review` additionally retains its exact provider/PR and candidate-head contract; this amendment does not create another review owner.

## Stable prompt and stop identity

Mutating `prompt` and `stop` require caller-supplied `--mutation ID` and `--expected-generation INTEGER`, using the existing authority token and generation validators without coercion. The caller obtains generation from the exact inventory attempt row and retains all invocation inputs before dispatch. A stale generation refuses rather than silently refreshing it. A repeated invocation must use the same original tuple, mutation, generation and (for prompt) exact text bytes; the authority owns replay and changed-input refusal. CLI code never creates a replacement mutation after a timeout or loops to resend.

Retry and prompt-status access also require the original authenticated UID/GID/groups and server-derived role. Current authorization for the target tuple alone does not permit another principal to reuse or inspect the original mutation. No caller flag supplies credentials or selects the authority role. A restarted process with the same stable principal may use the delivered replay/status boundary; it does not acquire the original Driver's private kernel-birth identity.

Prompt reads bounded UTF-8 input from `--file` or redirected stdin, preserving exact bytes and applying the delivered 16,384-byte/non-whitespace contract. File and stdin are not combined. No prompt bytes are included in operational logs or status output.

`prompt --status` is a read-only variant requiring the exact target tuple and original `--mutation`; it rejects `--file`, prompt stdin and `--expected-generation`. It calls the existing `prompt_status` with null outer mutation ID. It reports the authenticated current outcome and evidence references; missing, unauthorized and unavailable are distinct from `submitted`. It never sends input. Following a lost response, use this lookup; a missing record is not an instruction to invent a new ID or automatically resend.

Stop's same-ID replay returns its original immutable reply, even after subsequent settlement. A reply requiring settlement remains attributable to that original operation. After separately observing completed prerequisites, the caller may explicitly issue a new stop mutation at a fresh generation; the CLI never does this implicitly. Canonical terminal/release status is obtained from inventory, without requiring the restarted caller to impersonate the original foreground driver.

## Required usage and source verification

Example first prompt: `ace-overseer prompt --project ace --agent builder --assignment A --attempt T --mutation steer-001 --expected-generation 12 --file instruction.txt`.

After lost reply: `ace-overseer prompt --status --project ace --agent builder --assignment A --attempt T --mutation steer-001`. A later explicit identical replay retains generation `12`; substituting a refreshed generation or changed text must refuse.

Example stop: `ace-overseer stop --project ace --agent builder --assignment A --attempt T --mutation stop-001 --expected-generation 14`. If that reply remains uncertain, inspect canonical progress; do not treat an identical replay as a new settlement check.

SC2 must exercise CLI loss after accepted mutation, same-input retry, changed-generation/text refusal, read-only lookup with zero native writes, exact selection among multiple attempts, explicit mode selection, and protected resolution failure without local fallback. Launcher `work-on` invocation/assignment identity must likewise be concrete before whole qk0.1 readiness; this steering amendment alone does not claim that additional contract has been reviewed.

Also verify that an otherwise authorized different principal cannot replay prompt/stop or read another principal's prompt status. Independent scoped review by wave_5h5 approved the direction on 2026-10-07 and identified this original-principal precision from the actual steering/stop owners; it is incorporated above. Whole qk0.1 remains draft.
