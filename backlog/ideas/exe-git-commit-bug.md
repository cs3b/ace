michalczyz  …/handbook-meta   master !⇡   v24.3.0
 ♥ 16:56 ➜ git-commit dev-tool
[main] Error: Git command failed: git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta add dev-tool
Use --debug flag for more information
[main] Error: Git command failed: git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta add dev-tool
Use --debug flag for more information

=>
- this is special case when path is a submodule
it should run git-commit inside the dev-tool repository (as we want to commit everything in this submodule)


another is:


⏺ Bash(git-commit dev-handbook dev-tools --intention "update submodule references after create-path fixes")
  ⎿  Commit failed: No staged changes to commit


and another one when deleting files:

michalczyz  …/handbook-meta   master ✘!⇡   v24.3.0
 ♥ 14:46 ➜ git-commit template-usage-analysis.md workflow-independence-plan.md
[main] Error: Git command failed: git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta add template-usage-analysis.md workflow-independence-plan.md
Use --debug flag for more information
[main] Error: Git command failed: git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta add template-usage-analysis.md workflow-independence-plan.md
Use --debug flag for more information

michalczyz  …/handbook-meta   master ✘!⇡   v24.3.0
 ♥ 14:47 ❯ git status
On branch master
Your branch is ahead of 'origin/master' by 7 commits.
  (use "git push" to publish your local commits)

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	deleted:    template-usage-analysis.md
	deleted:    workflow-independence-plan.md


and one more - adding files that are gitignored (e.g.: CLAUDE.local.md)

git-commit *.md
[main] Error: Git command failed: git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta add CHANGELOG.md CLAUDE.local.md CLAUDE.md README.md
Use --debug flag for more information
[main] Error: Git command failed: git -C /Users/michalczyz/Projects/CodingAgent/handbook-meta add CHANGELOG.md CLAUDE.local.md CLAUDE.md README.md
Use --debug flag for more information
