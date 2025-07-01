READ the WHOLE workflow and follow instructions in [@commit.md](@file:dev-handbook/workflow-instructions/commit.wf.md)

Use the Task feature to commit changes in all submodules concurrently, then commit the main repository.

Process submodules in parallel:
1. Launch three concurrent Task agents to handle each submodule (dev-handbook, dev-taskflow, dev-tools)
2. Each Task agent should check for changes and commit if needed following the commit workflow
3. After all submodule tasks complete, commit any submodule pointer updates in the main meta repository

Remember: The three submodules are dev-handbook, dev-taskflow, dev-tools. Process them concurrently, then handle the main repo.
