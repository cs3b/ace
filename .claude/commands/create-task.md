1. READ the [@breakdown-notes-into-tasks.md](@file:docs-dev/workflow-instructions/breakdown-notes-into-tasks.wf.md)

2. READ all the docs listed in Project Context (linked in document from step 1.)

2. Identify the release folder to add task in (information from step 1. could be usefull)

3. use the workflow instructions from step 2. and create task based on user input

* use bin/tnid for getting next task id - one at the time (if you have to create multiple tasks, ask for next id after your created the previous one)

4. ensure that all task are created

5. prepare command `bin/gc -i "$write short intention for changes that have been made"` in the chat but do not run it
