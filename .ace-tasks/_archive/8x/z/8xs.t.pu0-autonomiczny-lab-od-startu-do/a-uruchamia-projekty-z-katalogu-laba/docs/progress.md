# Postęp 8xs.t.pu0.a — start całego laba (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Start na żywym herdr z prawdziwymi
space'ami — odbiór na labie odroczony na koniec programu.

## Zrealizowane w źródłach

1. **`ace-lab Molecules::ProjectLocations`** — wewnętrzny odczyt lokalizacji
   projektów z istniejącej konfiguracji topologii (`topology.projects`
   id/path, raw cascade — normalizacja/publiczna projekcja celowo ścieżek
   nie niosą); brak path = błąd TEGO projektu; publiczne CLI zachowuje
   sanityzowaną projekcję; żadnej drugiej listy w overseerze.
2. **Scope lab w `ace-overseer start`** (`StartOrchestrator#lab_start`):
   - lista projektów z topologii; root laba = katalog koordynacji z własnym
     _overseer; ten sam katalog jako lab i projekt = odmowa bez zgadywania;
   - lab tworzy/reużywa swój space herdr (`overseer-lab`, po tytule);
   - każdy projekt startuje przez TĘ SAMĄ operację co start samodzielny
     (własna kaskada przez `Ace::Overseer.config_at` z ominięciem
     test-mode mocków, własny kanoniczny root i tożsamość sesji);
   - statusy: ready (wszystkie started/reused; pusta lista = ważny idle),
     partial (niesprawny projekt raportowany z konkretną przyczyną,
     zdrowe kontynuują), blocked (nieczytelna topologia/konflikt ról);
   - powtórzenie naprawia tylko braki (reuse żywych, bez restartów i bez
     zamykania ręcznych pane); dry-run bez space/sesji; table/json/quiet wg
     kontraktu .1; exit 0 tylko ready.
3. **Guide labowy** (`wfi://overseer/lab-start`): koordynacja między
   projektami, delegacja do nadzorców projektów, eskalacje między-projektowe,
   bez przejmowania zadań/prywatnego stanu projektów.
4. `StartContract` dopuszcza scope lab (lab guide jako instructions);
   dokumentacja usage + CHANGELOG.

## Dowody

- `bin/ace-test ace-overseer` — 399 testów, 0 fail; nowe
  `lab_start_test` (6): lab z dwoma projektami (oba started, jeden space,
   tab per projekt z cwd projektu), powtórny start = reuse bez duplikatów
  (space 1, wszystkie reused), niezdrowy projekt = partial z przyczyną przy
  działającym zdrowym, pusta lista = ready/idle 0, konflikt ról = blocked,
  dry-run bez side-efektów.
- `bin/ace-test ace-lab` — 621 testów, 0 fail (ProjectLocations w tree).
- Naprawiony przy okazji: `config_at` omija test-mode mocki (thread-local
  test mode zafałszowywał odczyt kaskady w pełnym suite).

## Granice / odroczone

- Odbiór na labie: prawdziwe space'y Herdr, ≥2 skonfigurowane projekty,
  dołączenie już działającego projektu, praca na prawdziwej topologii z
  ace-lab install; publikacja gemów.

## 2026-10-31 — real native Herdr startup regression (reopened)

Host Lab startup failed before creating any overseer. Native `workspace list` returns `{id: "cli:workspace:list", result: {type: "workspace_list", workspaces: [...]}}`; StartOrchestrator treated the result Hash as an Array of rows and raised `TypeError: no implicit conversion of String into Integer` at find_workspace. Pane listing used the same incorrect envelope assumption. Existing test fakes emitted invented flat arrays and concealed the defect.

Regression reproduced with the live workspace schema: `bin/ace-test ace-overseer test/fast/organisms/lab_start_test.rb:250` -> 1 test, 0 assertions, 1 error, exact TypeError at line 269. Baseline lab tests before regression: 17 tests, 90 assertions, 0 failures/errors.

Fix uses existing ace-herdr ControlSurface list normalization for workspaces and panes; fakes now emit native collection envelopes and native row field names. Independent review, publication, and deployed verification remain required. Bootstrap without manual config and workspace naming are separate Captain-requested behavior gaps; this parser fix does not claim them delivered.


## 2026-10-31 — first-run bootstrap correction (Captain-directed)

The published start contract required handwritten start YAML before the agent
that should configure it could run. It also created a separate lab pane and
used the Lab process's gem graph for child projects. The correction in this
commit treats absent start configuration as first-run setup with the approved
Pi/ZAI flash/high profile, execs the Lab agent in the existing calling Herdr
pane, reserves workspace `overseer`, and names child workspaces by topology id.
Explicit malformed configuration still refuses without model fallback.

Child startup runs the project's own binstub/bundle in a separate process with
its own Gemfile and lock. Parent Bundler/Ruby injection is cleared and each
new project pane is bound to its own Gemfile/bin. There is no global GEM_HOME
switch and no import of child gems into the Lab process.

Executed verification before review: `bin/ace-test ace-overseer all` — 444 tests,
1990 assertions, 0 failures, 0 errors, 1 existing skip. New real-process tests
prove foreground exec keeps the CLI PID and two locally installed fixture-gem
versions load independently through two project-local lockfiles. The new
bootstrap atom tests executed on baseline fc72f8fea fail with 2 errors
(missing bootstrap method and explicit-start refusal), then pass on the fix.
Lint auto-fix completed with exit 0; 95 style warnings remain in the touched
files (including existing code); they are not a correctness verdict.

Status remains in-progress: independent review, publication and the real
Herdr foreground/self-configuration/project-start exercise are required before
acceptance. Generic code belongs to ace-overseer; host domain configuration
and root deployment stay with the lab-config operator.

Additional final focused check: project_bundle_test — 3 tests, 13 assertions,
0 failures/errors, including real shell setup with a path containing spaces.
`ace-task doctor` reports 529 archive warnings on both baseline fc72f8fea and
this candidate (879 tasks / 34 folders); no task metadata was changed here.


Real deployment preflight correction: native shell exposes HERDR_PANE_ID and
HERDR_TAB_ID, not HERDR_PANE/HERDR_TAB. The first bootstrap candidate used the
wrong pane environment name, so it would miss the foreground path. Recorded
before continuing: bind foreground to the actual HERDR_PANE_ID, clear native
parent pane/tab IDs for child CLI processes, and preserve the actual child
pane IDs when applying its own bundle shell setup. Release candidate 0.28.0.pre.1 for installed acceptance before stable publication.

Independent review rejected fce6d7db3 with three executed PoCs: native pane id
not read; native parent pane/tab ids not cleared; and a target Herdr shell
can hold BUNDLE_PATH absent from the requesting CLI, so derived-only cleanup
leaves a foreign bundle selector. First two are corrected in the candidate;
third will use an explicit complete known Bundler/Ruby cleanup set independent
of the requesting process environment, with a real target-shell regression.
All reviewer PoCs must rerun before approval.

Revised candidate verification: all three reviewer PoCs rerun exactly —
8 tests, 27 assertions, 0 failures/errors. Full `bin/ace-test ace-overseer all`
after the native-id and target-shell corrections: 447 tests, 2002 assertions,
0 failures, 0 errors, 1 existing skip. A permanent regression now seeds foreign
BUNDLE_PATH, BUNDLE_APP_CONFIG, BUNDLER_ORIG_BUNDLE_PATH and BUNDLE_FROZEN in
the target server shell while the CLI has none, and verifies all are cleared.

The packaged Lab guide now explicitly gives the latest Captain order priority
over stored tasks/plans and establishes startup plus commissioned project
overseers before unrelated old auth/publication/full-acceptance backlog. The
generic project first-turn prompt is unchanged. This is instruction content,
not a new scheduler or configuration mechanism.

Captain correction: the first bootstrap interpretation still queried native
layout/agent/cwd before exec. Bare start must only establish coordinator role
and launch the harness in the current terminal/cwd, without Herdr preflight
or mandatory skill projection. Reconciliation becomes an explicit agent tool
(`start --reconcile`); its child operations must not re-bootstrap the Lab.
This supersedes the earlier pane-environment gating in candidate pre.1.

Pre.2 targeted verification: 28 tests, 134 assertions, 0 failures/errors.
The actual bare CLI subprocess execs a fake Pi in the same PID/cwd with the
approved profile and packaged guide, while all HERDR environment is removed
and a fake herdr command records zero invocations. No skill sync/init or layout
preflight occurs. Explicit reconcile tests prove only project children are
started and no Lab pane/agent is probed or restarted. Full regression follows
on this exact release candidate; installed acceptance is still a host gate.
