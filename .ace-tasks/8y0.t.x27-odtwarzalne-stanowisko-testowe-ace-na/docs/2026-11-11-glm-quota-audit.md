# GLM quota audit — 2026-11-11

## Question and evidence boundary

The Captain reports that a little over 2 billion tokens exhausted the weekly
allowance, whereas earlier weeks reached 8–14 billion tokens with only a
five-hour limit. These are user-reported account totals, not totals independently
reconstructed in this audit. Current plan generation, the earlier comparison
week and whether both figures came from the same dashboard are pending.

No model inference, VM boot or paid test was performed for this audit. Account
credentials were not read. Existing local reports, source and host Pi session
usage fields were inspected; message content was not exported.

## Confirmed provider changes

- Z.AI's [21 April migration notice](https://docs.z.ai/devpack/transition)
  explicitly phases out legacy plans **without weekly limits**, preserving the
  paid period and then supplying two months of the corresponding current plan.
- Its [30 July plan update](https://docs.z.ai/devpack/notice/usage-revision)
  introduces credit metering for new plans. Active legacy subscriptions retain
  their calculation method for the current billing period. Therefore current
  credit rates cannot automatically be applied to this account's historical use.
- The [current overview](https://docs.z.ai/devpack/overview) lists Max at 28,000
  credits per five hours and 140,000 per week. The weekly allowance equals only
  five full short-window allowances, while a week contains 33.6 five-hour periods.
  This is an illustration of the additional ceiling, not a reconstruction of
  the Captain's old allowance or plan tier.
- Current input/cache/output multipliers are 6.9/1.7/24 for GLM-5.3 and
  2.3/0.56/8 for Flash, per 10,000 tokens. Off-peak model use costs half the peak
  rate. Peak is weekdays 06:00–10:00 UTC. Legacy V2 instead documents relative
  quota rates of 1/3 for GLM-5.3 and 0.4/1.2 for Flash (off-peak/peak).
- The current Max estimate at 95% cache hits is 0.676–1.352 billion tokens per
  week for GLM-5.3, versus 2.047–4.095 billion for Flash. These are vendor
  estimates under stated assumptions, not a fixed token allowance.

Thus a new weekly ceiling is a supported explanation; a confirmed migration
date for this account is still needed. Do not claim a recent silent account
change or a cache regression from these documents alone.

## Confirmed project findings

1. `utm131` received HTTP 429 / code 1310 on several guest agents from 16:22Z
   on 10 November. A host probe confirmed it; a second configured access returned
   the same reset time. This proves provider quota rejection, not a local idle
   observer failure. Code 1310 alone does not identify the plan generation.
2. The incident register already records repeated no-progress task reads
   (UTM-02), unnecessary bundle installation (UTM-05/22), synthesis recovery
   and repeated review (UTM-15/16), and runner observation beyond its deadline
   (UTM-19). They are real extra work; their token shares have not been measured.
   VM provisioning time itself must not be counted as model consumption.
3. The fixture defaults to `zai/glm-5.3-flash`. A small surviving host sample
   from September contains 526 Flash assistant responses: 1,456,565 fresh input,
   76,069,248 cache-read and 193,984 output tokens (about 98.1% input cache hits).
   The sample is incomplete, spans projects and is not the account's weekly
   total. There is no basis here to claim that all current work switched to the
   flagship model, or that cache effectiveness fell.
4. `PiClient#parse_ndjson` overwrites `usage` at each assistant `message_end`;
   `build_metadata` labels the selected message's usage as measured. This is
   **last-message usage**, not aggregate run usage. Treating it as a run total
   would undercount earlier tool/model rounds. This does not alter Z.AI billing
   or explain a total taken from Z.AI's own dashboard.
5. The inspected E2E report metadata records elapsed time and verdicts but does
   not provide an account-reconciled breakdown covering host runner, verifier,
   guest coordinators and all nested workers/review calls. Recent guest raw
   traces are not available as standalone JSONL in the inspected directories;
   VM exports were neither booted nor unpacked for this audit.

## Engineering follow-up for the supervised test

- Before each live stage, record plan generation, model, quota window and
  remaining provider quota. Afterward record the change and elapsed time.
  Provider account deltas may include concurrent activity outside this test;
  label that uncertainty rather than assigning all consumption to the VM.
- Record per-request fresh input, cache reads, output, model and timestamp from
  existing session evidence. Include host orchestration and nested model calls.
  Deduplicate by actual request/event identity; do not count both `message_end`
  and an `agent_end` copy, or exported copies of the same session. Missing usage
  remains unknown. Never add cache twice to provider input already including it.
- Fix the adapter's run-level accounting separately with deterministic tests:
  multiple assistant/tool rounds, repeated terminal summaries, retry, partial
  failure and absent usage. Preserve last-message statistics separately if
  needed; do not silently relabel them as whole-run totals.
- Report consumption per accepted stage/merge and distinguish productive work,
  failed attempts, recovery, review and idle wakeups. Keep the existing stop on
  five minutes without substantive progress; read-only polling need not invoke
  an LLM. Quota errors stop model retries until recovery is established.
- Reuse the prepared VM. Rerun the affected stage after a fix; mark results from
  changed artifacts as diagnostic. Do not weaken independent review merely to
  reduce accounting totals.

The historical 2B-versus-8–14B comparison remains open until account plan and
matching usage windows are supplied. No product code changed in this audit.
