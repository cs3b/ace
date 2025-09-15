1. we have to install dotfiles in the project as part of initialization
   maybe coding_agent_tools install (could be run multiple times but ensure we have everything that we need)

   - dotfiles
   - install claude commands
   - create taskflow structure
   - ... (everything that is always the same should be done by tool)
   - ensure the tools are linked in docs (so the initiliaze already have the tools to use them)

2. there are no more binstub tools (bin/tn, bin/gc, etc.) - use dev-tools commands instead (task-manager next, git-commit, etc.)

3. architecture is outdated -> we should not have there info about tools as they are in tools.md (and we should not duplicate with blueprint and what do we do)

4. it still create decisions directory in the dev-taskflow -> docs/decisions
