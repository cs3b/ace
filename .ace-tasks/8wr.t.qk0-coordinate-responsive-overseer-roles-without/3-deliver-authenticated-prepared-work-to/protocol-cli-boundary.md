# Prepared task context protocol CLI boundary — source proposal

The dependency chain is Assign → Review → Bundle. Bundle must not add an Assign gem dependency, activate/load Assign classes, or dynamically require its implementation. Existing NavigationEngine.resolve_cmd_to_path delegates task:// through a configured command_template and PATH; that is maintained ordinary-local behavior, not a trusted protected input path.

Protected task:// dispatch adds a source-owned closed command branch at that same protocol boundary. It executes an exact authenticated installed ace-assign entry with argv:

`[entry, "authority", "task-context", "--mapping", MAP, "--assignment", ID + "@" + SCOPE, "--attempt", ATTEMPT, "--task", REF]`

No shell, project/user command template, environment executable override, trust flag or PATH resolution. REF must be a canonical captured task ID. The executable is the same absolute worker_executable selected by the maintained installed execution-unit manifest/accepted source owner; its actual bytes, root/private ownership and original accepted entry association must be authenticated before spawn. Shared runtime/nav must expose that existing executable selection without importing Assign; how the scoped Bundle invocation obtains this installed manifest association is still being source-checked before implementation, not assumed from argv hints. Exact admission remains in Assign, so executable selection alone never grants work scope.

The source-owned Assign command authenticates the one prepared_work evidence_fetch and original peer/descendant association, validates explicit selectors and captured URI, then emits exactly one compact UTF-8 JSON record plus newline:

`{schema: "ace.assign.prepared-task-context/v1", mapping_id, assignment_id, attempt_id, scope, task_id, definition_digest, selection_sha256, text}`

All identity fields must match the requested/authenticated original selection. text is the exact captured bundle.txt string, never live spec/bundle expansion. Maximum text 1MiB (prepared context-file bound); encoded stdout is at most 6,307,840 bytes (6 × 1,048,576 maximum JSON string escape bytes + 16,384 bytes fixed-envelope allowance), including its one terminating newline; envelope has explicit bounded overhead and malformed/oversized/trailing stdout refuses. Nonzero exit/timeout is prepared_input_unavailable; invalid JSON, truncation, extra output/records, wrong fields or selector/digest mismatch is prepared_input_mismatch before any Bundle consumption. Exit0 means authenticated captured context returned; nonzero means no consumption and visible error. stderr is bounded diagnostics, never context. Bundle parses/validates once and uses the returned text directly; unlike ordinary resolve_cmd_to_path, it never reopens a stdout pathname. No local fallback on command/endpoint/ref/authentication failure. Actual worker descendant admission remains checked over the existing authority endpoint in the child.

Planning/source sequencing is authorized against qk0.0 inventory and integrated N2 contracts per captain/n0n audit; this does not mark whole xz9.2 dependency done. Source implementation and controlled verification remain qk0.3; installed executable/provider effectiveness stays gad.2. This proposal requires independent root review of selected-executable ownership before protected Bundle integration.
