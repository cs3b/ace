# Codex catalog provenance

Verified 2026-09-12. Native and API metadata are different evidence surfaces.

| Registry change | Evidence and decision |
| --- | --- |
| `gpt-6-astra`, `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna` IDs | [Official native model guide](https://learn.chatgpt.com/docs/models) explicitly documents `codex -m` with each ID. |
| Terra generic default, Luna mini, named aliases | Reviewed task and operator decision; these are ACE defaults. |
| New-model numeric context/output, pricing, account availability | Omitted. API model pages publish API values; the inspected native guide does not establish equivalent native limits. Existing effective limits are retained explicitly for the seven legacy IDs, with no shared default inherited by new entries. |
| Native reasoning matrix | The official guide shows Sol's low/medium/high/xhigh/max/ultra choices and describes Ultra delegation. It does not establish a complete per-model matrix for all four targets. No matrix is added to the registry. |
| ACE thinking presets | Existing low/medium/high settings are retained; `xhigh` continues sending high. This is ACE compatibility behavior, not a claim about native equivalence. |
| `last_synced`, `models_dev_id` | Preserve the existing project date and `openai` mapping; reviewing documentation does not constitute a models.dev sync. Native sync records its own observed catalog digest and selection under `sync_state`. |

The retained runtime catalog from the own Codex CLI 0.153.4 reports
Astra/Sol/Terra low/medium/high/xhigh/max/ultra, and Luna low/medium/high/xhigh/max.
This corroborates runtime behavior but is not a substitute for published metadata.
Source receipt: `.ace-local/W612/native-model-evidence.json` (source cache SHA-256
`dbbc8dfdd833e7b6f13fdbe97ffc66638820a5403f4082f90f710952bc984afa`).
No unreported output limit is inferred. The retained API research is in
`.ace-local/W612/model-evidence.md`; API numbers are not copied to the registry.

## Existing configuration decision

The answered HITL `8wbryf` and current dispatch supersede the retained plan's
first-adoption descriptor proposal. No fictional old catalog is shipped.
First apply records the actual offered catalog and actual accepted models;
missing entries remain UNKNOWN. Explicit configuration additions establish
adoption; later absence establishes removal. History retains unknown/removal
facts even if an offered model disappears and returns. Only genuinely new
additions relative to a recorded catalog are eligible for blanket apply.
Local aliases, limits and first-entry default remain authoritative.

Preview writes nothing. Unresolved offers are reported separately from applied
additions and are excluded from the synchronized-provider count. Config and
history are replaced together, with a backup, permissions preserved and a
concurrent-content check. Unrelated providers remain untouched when selecting
Codex. models.dev is not required for Codex-only synchronization.

## Executable evidence

First RED: `ace-test ace-support-models/test/fast/organisms/codex_sync_preservation_test.rb`.
Receipt `.ace-local/test/reports/support-models/8wbxov/` records actual apply
restoring missing old/new/unknown upstream entries and deleting a native-only
entry. The new tests cover preview, first observation, real recorded history,
adoption, subsequent removal, newly eligible catalog IDs, repeated sync, local
overrides and public command output. Selector tests exercise query orchestration
with captured client calls; native argv tests cover both command paths. These
deterministic doubles do not claim live account availability.

The existing SafeCapture timeout failure was reproduced unchanged in
`.ace-local/test/reports/llm-providers-cli/8wbxu5/`. Login-shell startup could
exceed the fixture's 0.2-second timeout before writing its PID. The fixture now
uses a non-login, no-startup-files shell, retaining the timeout and cleanup
assertions; focused verification passed (15 tests, 43 assertions).

Independent review, full suite, exact remote-head native checks and Forgejo PR
delivery remain parent-assignment gates. The task stays in progress.
