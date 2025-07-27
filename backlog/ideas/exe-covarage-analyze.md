take into account

read and run dev-handbook/.meta/wfi/manage-workflow-instructions.wf.md against following plan:
title: improve-code-coverage.wf.md
itshould                                                                                                                                                      1. run tests using the default method (bin/test)
  2. run coverage-analyz coverage/.resultset.json                                                                                                                    │
  3. then it should read file one by one by one and analyze the source and recommend the test cases that should be done
  4. next it have use create one task that will capture all the test that needs to be writteen
  5. and save it as a task using instruction from: dev-handbook/workflow-instructions/create-task.wf.md
