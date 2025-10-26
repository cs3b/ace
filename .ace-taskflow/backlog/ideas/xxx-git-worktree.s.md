just some notes from recent work
git worktree add -b wt/v.0.3.0+task.19-git ../tools-meta-f-git origin/main

git submodule update --init --recursive
git-branch v.0.3.0+task.19-git (for each submodule)

do the work

git-push (to have copy)

/rebase-against origin/main

git-push origin wt/v.0.3.0+task.19-git:main
