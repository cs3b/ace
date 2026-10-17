# Independent native Pi session review

Verdict: APPROVE.

Reviewed commit `31c386ecdbf656f827f8d49dcdce244991ab4806` against `2e9005f39` in `/Users/mc/Ps/ace/.ace-wt/ei9-native-session`. I did not author or modify the implementation. No actionable correctness or security findings were identified.

The change belongs in ace-herdr: its native observation is converted into a shared UUID identity by a dependency-free atom, required explicitly by both consumers. The existing Inbox suffix extraction is removed rather than copied or retained as a fallback. Gem packaging includes `lib/**/*`, so the new atom is shipped.

At `ace-herdr/lib/ace/herdr/atoms/native_agent_session.rb:12`, normalization requires a supported, matching agent and a string value; rejects names, malformed UUIDs, NUL and invalid encoding; permits paths only for Pi; and requires absolute, bounded Pi paths with a UUID JSONL suffix. It constructs a new hash without mutating the native observation. The path is a native protocol identity selector, not a filesystem authorization or a file to be opened. Existing Pi ID and Codex ID shapes remain supported; Codex paths remain refused.

At `ace-herdr/lib/ace/herdr/organisms/runtime_adapter.rb:122`, the existing OS ancestry/birth observation and exact native foreground PID match still precede session normalization. The pane, workspace and terminal checks remain in place. At `ace-herdr/lib/ace/herdr/organisms/inbox.rb:648`, Inbox still independently compares the normalized UUID with live `pi_identity`. Identity drift and queue refusal behavior remain covered. Ordinary admission still rechecks live peer identity and derives role from installed native pane placement, including the actual child-PID fixture exercised below.

Independently executed checks, both exit 0:

- Working directory `ace-herdr`: `../bin/ace-test test/fast/organisms/runtime_adapter_test.rb test/fast/organisms/inbox_test.rb` — **76 tests, 408 assertions, 0 failures, 0 errors**. Report: `.ace-local/test/reports/herdr/d86f22f8-f0b0-4233-9cc8-481cd3d1826a/`.
- Working directory `ace-lab`: `../bin/ace-test test/molecules/ordinary_owner_admission_test.rb test/molecules/ordinary_native_read_test.rb` — **14 tests, 62 assertions, 0 failures, 0 errors**. Report: `.ace-local/test/reports/lab/e5b80b62-2b89-4e93-bdd7-65c5811828a0/`.

Coverage includes the native timestamp/UUID Pi path, detached normalization, name/agent/path rejection, foreground owner refusal, existing Codex binding, Inbox live Pi identity drift, and native observation/admission composition. Dedicated atom boundary cases and Inbox path-specific cases would be useful future coverage, but the shared call is direct and the reviewed extraction preserves the existing algorithm; this is not a blocking finding.

Skills applied: loaded `.agents/skills/as-review-run/SKILL.md` and executed `bin/ace-bundle wfi://review/run`. The automated author/fix cycle was not executed because this assignment explicitly requires an independent read-only review and no implementation edits. The verdict is based on direct source inspection and the independently executed package tests above.

This approves the source change only. Publication, installed version verification and genuine live native admission remain separate acceptance work.
