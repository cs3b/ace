# Project design contexts

`adjust` personalizes design assumptions and incorporates newer installed library guidance. Generation reads the effective document once; it never merges project preferences in the variant loop.

## Three files per context

Project assets live in `.ace-config/design/`. The root is the shared project context. Children are `site` and `app`, each with `view` and `component` children. Named descendants such as `app/component/data-table` inherit from their directory parent. Every context contains:

- `defaults.md`: a local copy of library rules, including the package version and source digest. Named descendants start with no additional library rules.
- `user.md`: user-authored decisions. Explicit `--prompt` requests append the exact requested text to a dated decision history, without rewriting previous text. Later explicit decisions supersede earlier decisions; local decisions refine inherited ones. Edit this file directly for deliberate consolidation or clarification.
- `design.md`: effective synthesis plus the complete authoritative user decisions from its context chain. YAML metadata binds it to defaults, user bytes, parent output and its generated body.

For example, `.ace-config/design/app/component/data-table/` has its own three files and inherits project → app → component. Models, concurrency and execution presets remain in `.ace/design/`; this is not a migration of ACE configuration.

Project preferences override library stylistic suggestions, not provider execution permissions or artifact/shared-data requirements. The verbatim decision section prevents a summarizing model from silently deleting the source intent. Semantic synthesis still requires reading the report; hashes prove provenance and detect changes, not semantic correctness.

## Adjust and refresh

```sh
bin/ace-design profile adjust --surface app --prompt "Keep routine actions visible"
bin/ace-design profile adjust --surface app --kind component \
  --profile app/component/data-table \
  --prompt "Prefer compact rows with inline actions"
bin/ace-design profile refresh --surface app
bin/ace-design profile show --surface app --kind component \
  --profile app/component/data-table
```

Inside ACE use the source `bin/` commands; installed consumers use `ace-design`. `as-design-site-adjust` and `as-design-app-adjust` wrap the shared adjustment workflow.

Without `--profile`, adjustment initializes/recomposes the shared root and the complete selected surface branch, including existing named descendants. Its prompt applies to the surface node. With an explicit context it checks that context and its ancestors; its prompt applies only to the named target. Fresh ancestors are reused byte-for-byte. Only changed/stale contexts and affected descendants are recomposed, so a local preference cannot accidentally rewrite unrelated branches. `--kind` must match an explicit context and defaults to `view`. Both standard kinds are initialized by a branch-wide adjustment.

`profile refresh` copies defaults from the currently installed package, preserving every existing user.md byte. It cannot be combined with `--prompt`; do preference changes and library refresh as separate explicit operations. It does not download or install packages. Unchanged inputs and fresh outputs return `unchanged` without model calls.

`--propose` invokes the composer and saves a candidate/diff without publishing. This differs from generation's dry-run, which makes no model calls. Adjustment defaults to the existing configured design model and timeout; `--model` overrides it for this operation. The composer receives one ordered context tree and produces parents before descendants using their newly composed assumptions. Provider execution policies remain in force; a separate working directory is not an OS sandbox.

Reports live under `.ace-local/design/adjust/<base36-token>/`: request.json, exact worker prompts/results, report.json/report.md, changes.diff and a retained candidate tree when composition succeeds, including after publication. Previous published files are retained in `previous/`. In report.json, `contexts` lists inspected targets and `changed_contexts` lists only recomposed targets; `stale_contexts` identifies dependent results that still need adjustment. An interrupted publication can leave an inert `publishing/` staging copy in its report directory. A clear user override wins; ambiguous user decisions produce `conflict` and publish nothing. Use the reported question to obtain clarification and rerun explicitly.

Exit 0 means published, unchanged or proposed or planned; 2 means unresolved composition conflicts; 1 means invalid input or another error; Ctrl-C returns 130. `profile show` prints the effective Markdown without a model call and returns 0, or an actionable error with exit 1.

## Freshness, manual edits and transactions

A changed user/default file or parent output makes dependent generated documents stale. `context` and `generate` reject stale assumptions before invoking a model. Adjustment reports stale contexts outside its selected branch; recompose them explicitly. A newer library alone does not invalidate project defaults: refresh is intentional.

Manual edits to a generated body are detected and never silently overwritten. Preserve intended edits in user.md, then restore the previous generated design.md from version control or adjustment evidence before recomposing. Do not modify metadata hashes to bypass this check. Track the three files in project version control; `.ace-local` is disposable execution evidence.

Composition and candidate validation occur outside the publication lock. Existing profiles remain usable while a proposal is generated. Publication compares the complete original tree, so concurrent edits are not overwritten. Under the lock, a journal and directory swap replace the complete context tree; failed publication restores the previous tree. The next context operation recovers an interrupted swap. Symlinks in the context tree or its managed paths are rejected.

## Generation and handoff

```sh
bin/ace-design explore --surface app --kind component \
  --profile app/component/data-table \
  --prompt "Customer table with selectable rows and an empty state" \
  --variant-prompt 'a=Prioritize fast scanning' \
  --variant-prompt 'b=Make row actions explicit' \
  --variant-prompt 'c=Explore calmer spacing'
```

Default contexts are `SURFACE/view` and `SURFACE/component`. If there are no project profiles, packaged assumptions work without creating `.ace-config`. Once project profiles exist, initialize missing branches with adjust; never silently bypass shared project decisions. Named contexts require initialization.

New sessions save an immutable design.md plus context identity/digest in resolved.json and kind in session.json. Preparation, every variant and targeted revision receive the same snapshot. Resume/revise verify it and never replace it with a later adjusted profile. A new set of assumptions requires a new session.

Component exploration generates one component in a minimal host, with brief-appropriate states and a working local interaction. View exploration retains the representative page/screen scope. Both use three variants by default, one language, shared mock data and lightweight artifact checks. Production implementation uses the selected session's assumptions; an audit of an existing project reads the appropriate current effective context. Adjustment itself performs no browser audit, regeneration, design selection, Git commit or production integration.

`--dry-run` only resolves the affected profiles and model; it does not call a model, write reports or publish. `--propose` calls the composer and saves a reviewable unpublished proposal.
