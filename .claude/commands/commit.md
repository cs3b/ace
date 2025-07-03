Try the multi-repo commit command first:

1. **Primary approach**: Run `bin/gc -i "intention-of-changes"` (e.g., `bin/gc -i "chore: taskflow / tools"`)
2. **If bin/gc fails or doesn't exist**: Fall back to detailed investigation:
   - Check if `bin/gc` exists: `ls -la bin/gc`
   - Check for submodules: `git submodule status` or `ls -la .gitmodules`
   - Check git status: `git status`
   - Then read whole file and follow @dev-handbook/workflow-instructions/commit.wf.md

Execute the appropriate commit strategy:
- **If bin/gc works**: The command handles all repositories automatically
- **If submodules exist**: Handle submodule commits first, then main repo
- **If single repo**: Follow standard git commit workflow

The workflow handles all necessary commits - do not create additional commits afterward
