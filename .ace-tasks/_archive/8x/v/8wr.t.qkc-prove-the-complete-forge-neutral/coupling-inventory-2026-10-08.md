# Bounded source coupling inventory

Inspected ACE `9e198ce34` plus the accompanying shipped-default cleanup. This is preparation for qkc, not its completed matrix or installed acceptance.

## Inspected surfaces and classifications

Search: case-insensitive `gh`, `fj`, `github`, `labd` in the Ruby libraries and gemspecs of ace-git-worktree, ace-review, ace-task and ace-assign; the four packages' hidden `.ace-defaults`; active handbook trees for Assign, Review, Worktree, Git and Overseer (explicit CLI operation patterns, labd and github.com).

- No direct gh/fj/labd command execution was found in those library matches. This bounded search does not prove absence from all active execution routes.
- Worktree TaskFetcher help URLs and gem homepage/source URLs: non-operational metadata.
- Task's `github_issue`/`github_sync_pending` references: explicit rejection of obsolete metadata, not a fallback or active provider path.
- Task/Review provider requires and gem dependencies: adapter registration; Review PrProvider delegates to neutral PullRequestLifecycle. They are not direct CLI execution.
- Review comment author filtering recognizes `github-actions`: provider-specific actor metadata, not repository selection.
- Review goals-brief and Task issue-link URL construction branch on resolved provider: operational presentation coupling; existing GitHub/Forgejo routes are explicit. This is not a discovered effect/authorization bypass; further providers would need their own route contract.
- Review CampaignContract normalizes and cross-checks GitHub URL subjects specially. Independent inspection found additional CampaignManager repository validation, configured-server matching and repeated session/revision binding. No operational Forgejo repository-mismatch bypass was verified. Retain as normalization debt for R2/matrix review, not a proved security failure.
- Review SubjectExtractor validates generic `pr:` inputs through the GitHub identifier parser. Qualified `owner/repo#25` works; a Forgejo URL is rejected before provider resolution. Independent follow-up found no promise of generic Forgejo URL support: the neutral documented forms are numbers and owner/repo#number. Classify as provider-coupled convenience parsing, not a verified acceptance failure or security defect; do not add an invented URL-support requirement.
- Hidden Worktree defaults still described `gh pr create --draft` and required gh. Corrected to the configured forge provider/authentication.
- Hidden Review defaults still shipped `gh_simple_timeout`; a hidden-file search found no consumer in ace-review, only these defaults and historical CHANGELOG. Removed the unused setting and its description; retain `provider_timeout` and history.
- `.github/CONTRIBUTING.md` in project_docs is a conventional documentation discovery path, not a provider requirement.
- Handbook lab/labd matches prohibit legacy forwarding. Git handbook GitHub URLs are generic clone/upstream/SSH examples and reference links; they do not select the delivery provider.

The initial search of `PACKAGE/config` failed because those directories do not exist. The subsequent `rg --files --hidden` discovery located the shipped configuration under `.ace-defaults`, which was then inspected. The failed search is not absence evidence.

## Verification and outstanding work

Both changed YAML files parse as mappings; `git diff --check` passes. No execution code changed in this cleanup and no installed/native probes were run. Independent reviewer `audit_runtime_delivery_status` approved the four-path configuration/CHANGELOG cleanup and distinguished the subject normalization issue from a verified authorization defect.

Remaining qkc scope: inventory remaining commands and active skill projections, supply every executable positive/negative/uncertainty matrix scenario, verify the delivered R2/R3 and protected producer/consumer combination, execute deterministic integration checks, and obtain final exact-revision review. All qkc completion checkboxes remain open. Installed runs remain solely in lab-config:gad.2.

## Subsequent owner correction — not installed acceptance

The original classification above remains the history of that inspection. The
CampaignContract atom did admit a mismatched owner/repository for a non-GitHub
URL, although CampaignManager separately checks the selected live repository;
this is an inconsistent input contract, not proof of a protected merge bypass.
The owner now validates every PR repository URL through the same neutral URL
normalizer, retains its server/port/base path, checks the qualified repository,
and rejects credential-bearing or query/fragment-bearing subject URLs.
Local-candidate subjects keep their existing explicit identity contract.

Executed atom plus actual CampaignManager tests: **31 tests / 256 assertions
PASS**, report `2ca30e4c-dcd0-4f0f-b2a6-f3504e41ae53`. Tests cover Forgejo
normalization, a conflicting repository, credential-bearing URLs and distinct
server/port identities. This source correction still needs the final integrated
independent review; it does not close the qkc matrix.

Provider-specific release-publish workflows are explicitly GitHub release
capabilities, not a common PR delivery provider default. The generic gem
publication owner is the scoped vs3 publisher. GitHub example URLs, contributor
document paths and workflow statements prohibiting gh/fj/labd fallback are
non-operational references. They are not instructions to invoke a fallback.
