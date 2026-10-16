# Test responsibility map

| Behavior | Risk | Boundary | Evidence |
|---|---|---|---|
| Context IDs/type selection, document hashes | Medium | Molecules with real temporary files | Defaults and nested scopes, invalid paths/type mismatch |
| Local vs installed defaults, source freshness | High | Store + actual files | User/default/parent edits rejected; new library alone does not invalidate local profiles |
| AI adjustment and explicit intent | High | Only AgentExecutor replaced | Init, append prompt, refresh byte preservation, parent-first results, conflicts, malformed output, no-op |
| Transaction safety | High | Real filesystem/locks, injected rename errors | Partial failure restores full old tree, interrupted transaction recovery, concurrent edit detection, symlinks |
| Runner integration | High | Existing GenerationTest model double | Frozen design copies, component contracts, resume/revise unchanged profile after adjust |
| Installed consumer | High | Existing isolated gem installation | Packaged defaults, both skills, adjust/context CLI and component dry-run |
| Actual design loop | High | Real ace-llm + browser | Personalize, refresh changed library defaults without user loss, three interactive component variants |

Run bin/ace-test ace-design all and the default suite. Keep browser smoke narrow; do not add production audits to exploration. Validate source/generated skills. Review committed changes independently with ace-review, then update the managed draft PR.
