# Named consumer source inventory

Read-only inventory at accepted source `f29c72e3a45a7f3715ac93a8ab9fc7a806b2ed6b`,
relative to base `a33ccd92ce45dc84e06985254873405981dc4220`. This checks the bounded
neutral vocabulary slice. It does not certify the remaining qk0/xz9 role/service
adoption, installed resolution, authorization scenarios or SC7 acceptance.

| Owner/consumer | Inspected canonical assets and result | Payload change in this cap |
| --- | --- | --- |
| ace-git | `handbook/skills/as-git-pr-{create,update}/SKILL.md`, `handbook/workflow-instructions/git/pr/{create,update}.wf.md`; old GitHub PR skill/WFI sources removed. README, docs/handbook and Git collaboration guide use neutral managed entrypoints. | Yes: removed old shipped sources, clarified update merge arguments and changed shipped guide/catalog documentation. |
| ace-assign | `.ace-defaults/assign/presets/{work-on-task,work-on-task-auto-merge,work-on-task-ace-development,fix-bug}.yml` and catalog `steps/{create-pr,update-pr-desc}.step.yml` already name neutral sources. Create catalog example now uses actual delivery defaults/options. `handbook/workflow-instructions/assign/{prepare,drive}.wf.md` obsolete references removed; canonical skill demo tape paths updated. | Yes: catalog/workflow/documentation. |
| ace-git-worktree | `handbook/workflow-instructions/git/worktree-create.wf.md` task setup contains no obsolete PR source. `git/worktree-cleanup.wf.md` now says selected forge for its provider-neutral CLI. | Yes: shipped cleanup workflow. |
| ace-review | `handbook/workflow-instructions/review/pr.wf.md` uses neutral PR show with retained server/default/remote selection and exact candidate evidence. Review rounds, independent verdict and advisory CI gates retained. | Yes: shipped PR review workflow. |
| ace-task | Entire handbook/defaults inspected, including `task/{draft,review,work}.wf.md` and its WFI/skill source registrations. No obsolete PR names. Draft's GitHub issue URL is an explicit issue-input example, not a canonical PR operation or mandatory host. | No vocabulary payload change needed. |
| ace-overseer | Entire handbook/defaults inspected, including `overseer.wf.md`, `as-overseer/SKILL.md` and source registrations. No obsolete PR names or provider-specific PR directive. Existing overseer/proposal boundaries remain producer-owned. | No vocabulary payload change needed. |
| ace-handbook and integrations | Generic `handbook/perform-delivery.wf.md` now selects explicit standalone vs managed routes, neutral public primitives, exact-head tests/review/authorization and preparation ordering. Canonical inventory/projector regression exercises real sources, pruning old generated names. Integration packages contain no obsolete PR source references. | Yes: generic shipped workflow; test fixtures/regression are source verification only. No integration-gem payload change. |
| ace-support-nav (`ace-nav`) | Entire package/defaults inspected. WFI and skill protocol registrations scan directories; `ace-git/.ace-defaults/nav/protocols/{wfi-sources,skill-sources}/ace-git.yml` register package roots, not individual old names. Removed files therefore require no legacy registry or alias. | No nav implementation or registration change needed. |
| Normal `.agents` projection and root docs | Normal `bundle exec ace-handbook sync --provider agents` installed new neutral projections and pruned old projections. `docs/tools.md` names the new skill. | Repository projection/docs only, not a separate gem. |

Executed `rg --hidden` inventory across all eight named package roots, normal
`.agents/skills` and `docs/tools.md` for old `github/pr/create`,
`github/pr/update`, `as-github-pr-create`, `as-github-pr-update` and their former
`ace-`/frontmatter spellings found only these intentional residuals:

- Historical ace-git CHANGELOG entries at lines 145, 232, 307–309, 319 and
  369–373; historical ace-handbook CHANGELOG line 487; historical ace-assign
  CHANGELOG line 1143. They record old released behavior, not current directions.
- `ace-handbook/test/feat/neutral_pr_vocabulary_test.rb` lines 10 and 17 name old
  sources to prove absence/pruning. They do not register or execute old sources.

Provider-specific `github/release-publish.wf.md` remains an explicitly GitHub
release workflow outside neutral PR vocabulary. General Git provider examples,
task issue-input URLs, guide CI examples and review scope-analysis examples are
not canonical PR instructions. The generic delivery workflow's mention of gh/fj
forbids translating a managed blocker into those commands. This inventory is
not a blanket deletion of provider documentation or a whole protected-workflow
acceptance claim.

## Coordinated release ownership

For this cap's installed vocabulary to reach users, **ace-git, ace-assign,
ace-handbook, ace-review and ace-git-worktree** need coordinated package releases:
their gemspec payloads include the changed handbook assets/defaults. No version
was changed, built or published here. ace-task, ace-overseer, ace-support-nav and
handbook integration gems require no release solely for this cap; separately
changed producer/dependency payloads remain root's release-plan responsibility.
The accepted qkb.0 producer and this qkb.1 vocabulary slice must ship coherently,
with the complete planned dependency closure and no mixed old/new workflows.
Normal projection refresh follows installing that package set.

Source CLI resolution/bundling reaches all four new names in this worktree.
Old skills are unknown, but old WFI names still resolve through priority 20 USER
registration `@ace-git-user`, pointing at installed ace-git 0.24.0. This explicit
user precedence is retained, not overwritten or hidden by an alias. Fresh
outside-checkout installed resolution and old-name rejection remain open gates.
