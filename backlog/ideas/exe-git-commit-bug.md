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
