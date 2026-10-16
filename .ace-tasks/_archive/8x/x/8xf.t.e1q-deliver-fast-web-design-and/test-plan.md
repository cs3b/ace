# Test responsibility map

| Behavior | Risk | Layer | Evidence |
|---|---|---|---|
| URL/surface validation, report categorization | high | fast atoms | invalid/credential URL, unsupported surface, outcome/coverage |
| Session shape and selected fixture integrity | high | fast molecules with temporary files | valid/invalid JSON, missing chosen variant, stale hash |
| Gallery partial variants and HTML escaping | medium | fast molecules | preserved prior variants, escaped untrusted titles |
| Preview server confinement | high | feat real Node HTTP | traversal, symlink escape, methods, loopback, shared fixture fetch |
| Doctor dependency reporting | medium | fast boundary stub + real CLI smoke | missing node, missing/mismatched dependencies |
| Inspection execution/evidence failure | high | fast process boundary stub | runner failure/invalid result, fresh output, no overwrite |
| Render and axe inspection | high | feat real local browser | clean fixture, broken image, overflow, accessibility defects, failed load |
| Skill discovery and projection | high | feat source + installed gem | seven bindings, explicit surface, portable resources |
| Knowledge/proposal validation | medium | fast temp catalog + shipped validation | missing fields, duplicates, invalid source/date, no empty success |
| Interactive/engineering/inspiration contracts | high | workflow E2E scenarios | shared fixtures, targeted feedback, handoff, partial research |

No network or LLM calls in deterministic tests. Use temp directories for controlled files, fake only the subprocess boundary in fast tests. Browser tests are feature-lane; missing runtime fails explicitly rather than skipping. Package all must execute browser tests after documented runtime setup. Benchmark assets are fixed source fixtures, not generated during package tests. Evaluate subjective quality separately; tests cannot prove taste.

Run bin/ace-test ace-design all and bin/ace-test-suite. Preserve report paths and actual counts. Independent review follows implementation.
