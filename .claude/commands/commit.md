First, check the project setup to determine the appropriate commit strategy:

1. Check if `bin/gc` exists: `ls -la bin/gc`
2. Check for submodules: `git submodule status` or `ls -la .gitmodules`
3. Check git status: `git status`

Then read whole file and follow [@commit.md](@file:dev-handbook/workflow-instructions/commit.wf.md)

Execute the appropriate commit strategy:
- **If bin/gc exists**: Use `bin/gc -i "intention-of-changes"` for multi-repo commits
- **If submodules exist**: Handle submodule commits first, then main repo
- **If single repo**: Follow standard git commit workflow

The workflow handles all necessary commits - do not create additional commits afterward