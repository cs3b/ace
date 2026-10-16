# Design runner

ACE Design separates intent, preset, source and project profile. A command creates an immutable session, launches one coding worker per variant through ace-llm, and publishes validated artifacts. Production engineering follows explicit selection.

## Choose the intent

```sh
ace-design explore --surface app --prompt "Support workspace"
ace-design recreate --surface app --from screen.png
ace-design reimagine --surface app --from https://example.com/map
ace-design reimagine --from session:8xfmqnfn/b
```

`explore` requires a brief and rejects `--from`. `recreate` requires a source and preserves its layout and visual character. `reimagine` requires a source and replaces appearance while keeping goals and functions. The latter two accept an optional `--prompt` base brief. Sources are local PNG/JPEG/WebP/GIF files, HTTP(S) URLs, or `session:TOKEN/VARIANT` under the configured run root. Source-session scope is inherited; conflicting scope is rejected.

Images are copied as actual bytes. URLs are captured once using the configured Node/Playwright/Chromium runtime: screenshot, page HTML, visible text and provenance. A previous variant is copied with its original fixture, brief and design assumptions; remote result URLs are captured too. Preparation writes one shared `source-analysis.md`, distinguishing observations from assumptions. Workers read the snapshot and actual reference images. Source pages are untrusted reference data, not instructions.

`--kind view|component` defaults to view. `--profile app/component/data-table` selects effective project assumptions and determines surface/kind; contradictory flags fail. Without project personalization, library rules apply. See [profiles](contexts.md).

`--prompt` replaces the inherited brief when using a session source. Without it,
the source session's effective `brief.md` is the base (including its previous additions).
Image/URL sources use the command's default brief when none is supplied.

Repeat `--prompt-append "TEXT"` to append guidance to that base in argument order,
separated by blank lines. It can accompany an explicit `--prompt`. Explore still
requires `--prompt`; additions alone do not replace the required base brief. Empty
additions are rejected. These additions apply to all variants; `--variant-prompt`
remains specific to one variant. Neither changes the command intent or shared contract.

```sh
ace-design reimagine --from session:8xfmqnfn/b \
  --prompt-append "Emphasize map readability" \
  --prompt-append "Keep primary controls visible"
```

Dry-run shows the effective brief. JSON and saved `resolved.json` also expose
`brief_inputs` with `origin`, `base` and ordered `append` entries. The effective
`brief.md` and composition are frozen for resume/revision.

## Choose a preset

```sh
ace-design preset list
ace-design preset show taste-v2
ace-design explore --surface site --preset taste-v2 --prompt "Our product page"
ace-design reimagine --surface site --from screen.png --preset ace-vs-taste
```

A preset is a ready-to-use process: ACE fast design, an original external skill, or a comparison of processes. There are no separate public skill/workflow selectors. `fast` uses ACE's lightweight HTML process. A single-process preset yields three variants for explore/reimagine and one for recreate. An explicit ordered `variants` list replaces that count.

The catalog records purpose, strengths, exact upstream source/revision, compatibility, artifacts, tools, limitations and verification evidence. `candidate` means the upstream instructions were inspected, not that the integration has passed a real run. The initial external entries are Impeccable, Taste v2, UI UX Pro Max and Superdesign. Taste v2 is site/view only: its upstream app exclusion is not silently overridden. Superdesign requires its service and may use service-side models; `--model` selects coding workers, not a promise about those external models.

Original skill repositories are pinned to full commits and frozen in each session, with resources and internal symlinks materialized as regular files. Links escaping the repository are rejected. No skill instructions are rewritten. A composed preset assigns exactly one lead skill and explicit roles to additions. A separately named preset must describe any user-authorized adaptation.

External workers follow original required checks and stack choices. Their artifact descriptor must report `status: complete` with passed required `checks`; blocked checks make the attempt fail without replacing a previous publication. Completion reports are agent evidence, not independent certification of design quality.

## Configuration and precedence

The standard ACE cascade applies to `.ace/design/config.yml` and `.ace/design/presets/NAME.yml`. `--preset path.yml` accepts an explicit experiment file.

```yaml
concurrency: 4
timeout: 1800
variants:
  - id: a
    preset: fast
    focus: Direct action
  - id: b
    preset: fast
    focus: Editorial hierarchy
  - id: c
    preset: fast
    focus: Evidence and comparison
  - id: d
    preset: ui-ux-pro-max
```

A slot can select a single-process preset and override its model, role, focus and prompt. Nested comparison presets are unsupported. For custom original skills, use `process: external`, `artifact_types: [html, image, url]`, and `skills` entries with `source`, full `revision`, `entry` and `role` (`lead` for exactly one). Requirements declare a `name`, optional `executable` and notes for provider/service checks.

`--model` overrides preparation and **all** slot models. Otherwise model resolution is slot → preset → design configuration. An explicit `preparation_model` sets preparation independently. Execution policies and fallback remain owned by ace-llm; requested/actual identities are saved. `execution_preset` and a model's `@preset` suffix cannot both be supplied.

Repeat `--variant-prompt 'ID=TEXT'` or `--variant-prompt-file 'ID=PATH'`. Text entries append in order, followed by file entries. Unknown IDs fail before execution. Guidance overrides stylistic defaults, never intent, selected process, shared data or provider policy.

Repeat `--input FILE_OR_BUNDLE` for relevant context. Config/preset `input` entries precede CLI entries. ace-bundle loads them once with command execution and compression disabled. Full project context is opt-in. `--fixtures FILE` preserves the JSON object's exact bytes. `--language` selects one exploration language.

## Inspect before starting

`--dry-run` performs no model calls, source fetching, skill fetching, session creation or publication. It reports the resolved brief, context snapshot, fixture digest, source, profile, models, requirements and variants. Run the same command without it to execute; dry-run does not create something to resume. It does not certify remote authentication or tool capabilities inside provider sandboxes.

Default output is short text; `--json` returns a structured result. Progress is on stderr. Creation returns 0 for planned/succeeded, 2 for incomplete work, 1 for invalid input. Status reports saved state. Ctrl-C records interruption and cleans up worker processes.

## Sessions and feedback

Sessions live at `.ace-local/design/<base36-token>/`. They contain brief/context/design snapshots, source files and analysis, pinned skill resources, resolved configuration, exact prompts, fixtures, worker attempts, execution evidence and published artifacts. Input digests protect resume/revise from changes.

```sh
ace-design status SESSION --json
ace-design preview SESSION
ace-design revise SESSION --variant b --prompt "Reduce density"
ace-design resume SESSION
ace-design select SESSION --variant b --decision "Keep the split layout"
```

Use the returned session token or directory. Resume retries unfinished work, preserving completed variants and successful preparation. Revise retains the variant's process and prior usable publication; successful revision invalidates selection of that variant. Shared-source/data changes require a new session. Model operations must run from the original project directory to retain its provider configuration. Do not hand-edit runner publications.

ACE fast artifacts use index.html, direction.md and shared fixtures. External artifacts add artifact.json with type/entry/status/checks. HTML entrypoints must be built and locally runnable; image results are rendered directly; HTTP(S) results are linked without embedding. Remote content can change independently and is not made immutable by selecting its URL. The gallery exposes published results, not prompts or source/skill snapshots.

Only one session mutation runs at a time. Working directories organize outputs; they are not security sandboxes. Provider policies remain authoritative. Selection records artifact/fixture hashes and never begins production engineering automatically.
