# Supervision record — missed existing-owner lookup (8xa.t.ho4 duplicate), 2026-10-11

## What happened

The create --in delivery defect (create.rb:122 manager.move undefined,
partial effect on 8xa.t.h8x) was adopted as a NEW tool-minted bug task
(8xa.t.ho4) after an owner lookup that checked only top-level active task
titles. The CANONICAL owner already existed:
8x9.t.qkd.0 (child/draft spec under 8x9.t.qkd, with remote_issue link to
GitHub cs3b/ace#333 and a 2026-10-10 verification baseline reproducing the
same NoMethodError at create.rb:122). Captain issued a scope correction.

## Root cause of the miss

Discovery granularity: the lookup did not include (a) child/draft task
spec directories (qkd.0 lives at depth
`.ace-tasks/8x9.t.qkd-.../0-create-tasks-in-target-folders/`), nor
(b) remote_issue links as an ownership signal.

## Standing correction (applied from now on, all gad.2/h8x supervision)

Before minting ANY bug/implementation deliverable, discovery MUST include:
1. child and draft task specs under every plausibly-related parent
   (`.ace-tasks/<parent>/*/`), not only top-level titles;
2. `remote_issue:` links in task frontmatter (issue-sync state);
3. archive search for recently archived equivalents;
4. when a remote issue is cited by the host/Captain, link via issue-link
   (or manual record if link validation is BLOCKED on missing auth).

## Disposition

- 8xa.t.ho4: closed as blocked duplicate; attributable disposition + links
  recorded in its spec (canonical owner 8x9.t.qkd.0 / #333).
- Worker preserved: same pane/worker (h8x-impl-b) redirected to the
  canonical atomic contract; prior variant commits preserved on branch
  `ho4-preserved-report-recover-contract`.
- No second implementation launch.
