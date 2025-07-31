create list where it knowst that

  - task.5
    > run subtask with commands all together
      - [ ] expand the content of the /work-on-task
      - [ ] after work with task is completed - expand the command /create-reflection-notes
      - [ ] after all  - expanded command /commit
  - task.7
    > run insturction more less should look like:
  ```
  - [ ] work on task v.0.4.0+task.7 - Add Draft Status Support to Existing Tools

    read whole file and follow @dev-handbook/workflow-instructions/work-on-task.wf.md

    task to work on: dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.007-add-draft-status-support.md

  - [ ] commit all the changes you have made

    (instruction how to use git-commit in files you have made using git-commit ...)

  - [ ] create reflection note for current session

    read whole file and follow @dev-handbook/workflow-instructions/create-reflection-note.wf.md

    run shell cmd: git-commmit $path-to-created-reflection-file

    (and so on for everything that should be done for each task)

   ```


  - [ ] at the end when all tasks are completed run the full suite, and ensure all test pass `bin/test spec/`

  - and everything that should be done after all task are completed
