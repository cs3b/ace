READ the WHOLE workflow and follow instructions in [@commit.md](@file:dev-handbook/workflow-instructions/commit.wf.md)

Use the Task feature to commit changes in all submodules concurrently, then commit the main repository.

**Context Analysis**: First analyze the session history to understand the intention/purpose of the work done. This context will be passed to each Task agent for better commit messages.

Process submodules in parallel:
1. **Gather context**: Analyze session history and conversation context to understand what changes were made and why (do not use filesystem operations for context gathering)
2. **Launch concurrent Task agents**: Create three Task agents to handle each submodule (dev-handbook, dev-taskflow, dev-tools)
3. **Pass context to each agent**: Include a brief summary of the intention/purpose of changes for that specific submodule
4. **Each Task agent should**: 
   - Check for changes in their assigned submodule
   - Use the provided context to craft meaningful commit messages
   - Follow the commit workflow instructions
   - Commit if changes exist
5. **After all submodule tasks complete**: Commit any submodule pointer updates in the main meta repository

**Context format for Task agents**:
```
"Working on [brief description of the work]. In [submodule-name]: [specific changes made in this submodule]. Use this context to create an appropriate commit message following conventional commit format."
```

Remember: The three submodules are dev-handbook, dev-taskflow, dev-tools. Process them concurrently with context, then handle the main repo.
