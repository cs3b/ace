# Original server network readiness — source candidate

Base: `924188ecb`. This candidate implements the already required private report field in network-installation-evidence-amendment.md, canonical stage/readiness joins. Independent source review and integration remain pending; no task or installed criterion is closed.

The previous collector pinned mount and IPC objects but omitted `/proc/<original server>/ns/net`. Assign copied the parent selection into the native event without comparing an actual server observation. Runtime now holds that original network namespace descriptor, requires the nsfs NS_GET_NSTYPE response CLONE_NEWNET and rechecks its device/inode at the end of collection. Existing server birth/credential checks bound that collection. The private hook already forwards the complete collected report; Assign now requires its exact new field and compares it to BOTH canonical parent selection and installation admission before retaining it in the native event. No old-schema fallback.

Executed from package directories with `../bin/ace-test`, outer timeout 120:

- Runtime `test/molecules/server_resource_observation_test.rb`: 3 tests / 19 assertions, zero failures/errors/skips; receipt `9c10b518-10d9-4089-8652-4f3e34fe8c93`.
- Assign `test/fast/authority/execution_scope_observation_test.rb`: 22 / 106, zero failures/errors/skips; receipt `6ba35b35-1820-4b2c-82c6-6403047c170a`.
- Assign `test/feat/authority/launch_scope_admission_test.rb test/feat/authority/terminal_scope_receipt_test.rb`: 17 / 225, zero failures/errors/skips, 1m42s; receipt `40209f7e-0909-401d-9452-5075837d3b36`. Same live process was polled until terminal success.

Initial runtime receipt `79fd6f02-6176-4421-8d98-e60a4ce64b51` failed with `undeclared observation /proc/81/ns/net`: the fixture edit had failed because its command ran from the package directory with a repository-relative path. Corrected the fixture path and added actual net object replacement/wrong type cases before rerunning. No product timeout or behavior weakened.

These are controlled source tests. The existing lifecycle feature fixture still substitutes its scope observer; its green result is regression evidence, not proof of full production-observer lifecycle composition. That full composition remains required, along with installed namespace/OS containment acceptance in gad.2.
