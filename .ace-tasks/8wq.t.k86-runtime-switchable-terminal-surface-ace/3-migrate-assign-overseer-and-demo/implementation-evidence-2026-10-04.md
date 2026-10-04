# k86.3 closure implementation and evidence

Task remains **in-progress** pending independent exact-head acceptance. Code/test head: `40d57c16436e450509a8df5e7a4245ed494c8c5a`; preceding product commits `5a36261574fee59214a449dbe51bb8a9d3e549f4` and `888f8c10e`.

## Delivered boundary and reproduction

Public fork invocations previously replaced the prepared interactive shell with `exec`; native Herdr reproduction wrote the first marker then failed with `pane_not_found` on reuse (assign receipt `8x3w3u`, 1 test/3 assertions). Invocations now run as shell children. No completed runtime migration was reimplemented.

Standalone consumers now depend on both existing adapter wrappers. Shared Ref, result structures and provider errors moved once to dependency-free `ace-hitl-contract`, preserving `Ace::Hitl::Providers`. Registry, Lab integration, lifecycle and locked AssignmentBinding remain in HITL, including its ace-assign dependency. Every require site uses the new entrypoint, and a disjoint-path test rejects duplicate definitions.

Architecture was independently approved by source-inspecting ACE review `review-8x3w73` and wave3_otp_services_lane. All five implementation conditions were verified valid and resolved: require-site completeness, disjoint require paths, direct CLI require, executable isolated dependency/install checks, release choreography. See dependency-architecture-proposal.md. Coordinator owns versioning/publication, contract first, after exact-head acceptance.

## Final source-built installed/native checks

Built source gems at the code head into a local archive pool, resolved each consumer into a distinct empty GEM_HOME with local-only RubyGems installation, then launched Ruby without Bundler or repository load paths. Full HITL activation is rejected for every consumer; standalone Herdr also must not activate assign. Consumers activate both real adapters. Mechanically traverse runtime dependencies to reject cycles. The optional CLI provider plugin is added only after the consumer-only proof, solely for native fixture launch.

- Contract full suite with clean-install matrix: `8x3wzs`, **13 tests, 704 assertions, no failures/errors**. Pool `/tmp/ace-k86-final-proof/packages`, separate GEM_HOME directories beneath `/tmp/ace-k86-final-proof/`.
- Installed Herdr workflow: `.ace-local/runtime-acceptance/reports/installed-workflows/8x3x0a`, **1 test, 69 assertions, no failures/errors**. Native Herdr **0.9.3**, dedicated named server, short owned socket and disposable Git repo. Actual installed `ace-assign fork-run --callback` launches a local credential-free codex fixture that invokes installed `ace-runtime send`; the actual caller shell appends exactly once. Actual installed `ace-overseer work-on` provisions a real Git worktree, with native tab/pane cwd verified by realpath. Public prune refuses unmerged work and preserves it; after merge it removes the worktree and exact native task tab, while surviving repository content proves preservation. Installed fresh Ruby processes verify foreign pointer-only replacement, record shape, restarted reuse, native-root adoption and conflicting-root refusal. Installed ace-herdr failure occurs after actual native tab creation, emits nonzero ordinary error/no success payload/backtrace, retains the failed tab and every preexisting tab. Installed demo executes native pane-exists wait and send. Installed git-worktree CLI opens an additional native tab at its real worktree root.
- Installed Herdr retention: `.ace-local/runtime-acceptance/reports/herdr-final/8x3x07`, **1 test, 16 assertions, no failures/errors**. Each operation starts a fresh installed Ruby process; two submitted commands write separate markers on the same prepared target and the native shell PID remains live.
- Installed tmux retention: `.ace-local/runtime-acceptance/reports/tmux-final/8x3x07`, **1 test, 8 assertions, no failures/errors**, native tmux **3.7c**, test-owned socket/session, native pane_dead=0 and second write on the same target.

No runtime adapters or native executors were mocked. The only fixture substitutes for an external model process; no model service or operator session is contacted. All disposable native servers are stopped after each check. Source-built artifacts deliberately retain released baseline version numbers; these are source acceptance and do not claim publication evidence.

## Executed regression checks

- ace-assign all after retained-shell fix: `8x3wdc`, 783 tests/2946 assertions, 1 explicit native-opt-in skip, no failures/errors. After boundary extraction, assign fast `8x3wte`: 770 tests/2822 assertions, no failures/errors.
- ace-herdr all: `8x3wfr`, 451 tests/1449 assertions, no failures/errors; updated CLI isolated load fixture `8x3wyr`: 5/19 pass.
- ace-hitl all: `8x3wj5`, 206 tests/1066 assertions, no failures/errors, existing root-required multi-UID skip. Moved Ref tests are included in contract coverage; locked assignment binding integration remains green.
- ace-overseer all: `8x3wlq`, 255 tests/1013 assertions, no failures/errors.
- ace-demo all: `8x3wnn`, 222 tests/900 assertions, no failures/errors.
- ace-git-worktree all: `8x3wnu`, 546 tests/1550 assertions, no failures/errors, 18 existing fixture/platform skips.
- ace-test-runner-e2e all: `8x3wqa`, 651 tests/2170 assertions, no failures/errors.
- git diff --check passed.

The native acceptance is executable deterministic end-to-end consumer CLI coverage. No claim is made that the separate model-driven Markdown E2E scenario campaign was run. The full monorepo aggregate remains coordinator verification to avoid concurrent resource-heavy suites; all modified package gates above executed.

## Replay

Use source bin/ace-test and a test configuration whose `environment.overrides` sets ACE_INSTALL_GRAPH="1" and ACE_INSTALL_RETAIN to a fresh short /tmp directory. Run ace-hitl-contract all with that config. The retained directories must start empty. Then set ACE_INSTALLED_HOME to its ace-overseer directory and run ace-assign test/edge/installed_herdr_workflows_test.rb. For retention, also set ACE_NATIVE_RUNTIME to herdr or tmux and run ace-assign test/edge/runtime_retained_shell_test.rb. Use --config-path with each explicit override config. The committed tests own all fixtures and use no host credentials. Native binaries herdr and tmux must be available on PATH.

Credential exposure during initial exploration is separately recorded without values in environment-incident-2026-10-04.md. Parent was informed of credential types; all subsequent fixtures use hermetic environments.
