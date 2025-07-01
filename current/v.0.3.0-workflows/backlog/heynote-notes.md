###

##### feedback aftew

###

1. use bin/console to test the code
2. how to make read it tree structure (instead of scaning directories /sub one by one
3. task context preload (on cheaper model - it just reading files ...

4. self reflection -

5. working with tasks - before last step (if bin/lint & bin/test present ensure there is clean state )

6. the order of require matter (first atoms, netx ... )

7. test should be run failure only `bin/test -f f` or only failure - next fix file by file (run file directly /bin/test &filepath)
 bin/test --next-failure

8. when creating doc / research - it should be in correct folder inside the current release (work on task / fix tests)

9. how to make sure - that coding agent will never read the tokens

10. code-review/task-1/code-review-$model-name.md

- code reviews on tasks -> auto to gemini / o3 / ..

idea: code review changes before commit ...

code review - too much coupling, overengineering

11. test default formatter should be progress (less input tokens for chat)

12. after tasks is implemented

- docs (readme / docs)
- project context (architecture / blueprint)
- adr - what important decisions we have made
- what external documenation we should keeep (after we add dependecies)

13. fixing tests is not effective ...

- group by type of error -> fix in batches each type (even smaller context model could do that)

- generaly idea of coding agent, who will instruct other coding agents to do the job (cheaper, less context per task) 1. less context in the main thread - specs run, get only errors to fix ) 2. cheaper solution, 3. tailored context

14. tasks names - we should also prefix 00x the task number - so to sort

- when creating task related we can use 7.1, 7.2, and so on

15. prompt based on the current project structure -> create all documents, including guides for coding standards

16. bin/rb - for running ruby in current context

17. Project Managent / Internall Tools - should have different file then the architecture of the solutions we are making (and be part of the env contenxt)
    so it knows when to use bin/tn and when bin/tnid

18. review the value of main readme file inside the release folder (maybe we should name it differently)

19. should i have concers for cross cuting elements in atom architecture -> or they should be atoms

20. we have some duplications in knowledge (README vs docs/*.md & docs/*.md vs docs-project/*.md) - would be nice to cross reference documents and do not duplicate information as much

21. self improvement prompt - based on diff / session / commits / on:
? explatation ( this is what we can do above  )

- tools
- guides
- workflow instructions
- task descriptions (guides)

 a) record session -> the challanges, trouble, what was smooth ( what could be better ) - in context of session ( should be run by external llm call)

? exploration ( can think about )

- watch what is going in the ecosystem ( software engineering / open source related to it / libs & pattern that can be used )
- can we simplify the rules ( guides / workflow insturctions / prompts ) and still get good as we so far results

(you can replay sessions on repo and compare)

@ the ai is not good in following complex and long alogrithm, but it can write a code that will execute this algorithm ( it write it chekc in small samoples, if you have a process, and then run on on larges scale and solve part of the big issue)

22. when context is not importantent (only summary, key facts) we should run the task in subprocess (call agent with ongoing progress, and summary / key facts )

23. How to decide when to write a test and when to

24. Have a subagent that will run and analyze the test output

- do not polute token with innecesarry stacktracke
- do the analyze of the issue
- present only actionable thoughts (group them by probably issue / solutions)

(just pass the context of the session - small one)

- have a library of previous errors and recomendations (can use for analyze current issue, or when analyzing next failint tests)

25. task definition - especial after review - should contain list of guides / files to read before working on the task ( the context of the project

(beyond the work on the task workflow insturctions

26. each workflow instructions should have high level plan (what is currently part of rules in zed)

- so the integration for the wf with coding agent should be read the wf and and follow high level plan step by step

27. task should have created_at: and updated_at: metadata

28. to verify if all test are passing you have run `bin/test | tail 10`

29. some files fron docs-project should be in docs/ (architecture | what do we build | blueprint | roadmap | decisions ) - the other part should be git module

30. work on atom architecture guide -> extract ruby part

31. build a map of ruby code (

path -> class
  -> public metthods<line:line> with parameters -> outcome

32. agent for keys / secrets ...

- if they are in env or if they are in file within the project ai will read them ...

33. conterization of software development

34. git work trees ???

35. <https://models.dev/> - list of models with pricings

36. High level overview of files ( cmd as part of blueprint )
    High level overview of tools

    => review tasks / or new workflow -> prepare context for tasks ( it should chooose tools / files / etc to give the context to work on )
       - how we can prevent from reading this files again by agent ?

47. diff with filters

   run diff and filter docs-projects  and other paths

48. tools :: batch processing

- list of prompts ( context )
- system prompt -> for each context
- progress ( paralell if tokens possible)

   !!! Batch Processing with Context Cache !!!

- we cache project context (docs / map of files / ... )
- we ran context and system prompt with the api

49. tools :: lm query -> tokens in / out -> cost

50. Preflight with Sonet or even 2.5 flash ( load the context to the thread -> use sonet or opus to to the job

- you save tool calls for the better model (and still have the whole context

- probably done as a tool could be too ... still the agent with try to not to load the whole context ... ( how to make it happen )

51. atom house rules -> create architectures/

52. directory naming -> singular or plural ... convention

52. add this to general formating rules for markdown files - maybe in documentation.g.md)

54. bin/tn --next=5 (if we want to create 5 tasks upfront) (one tool call instead of 5)

- it shoulde help with prefiling the meta ( as example current date, status )

55. task id meta:

---
id: v.0.2.0+task.40
title: Implement Cost Tracking for LLM Usage
status: pending
priority: medium
assignee: unassigned
labels:

- enhancement
- cost-tracking
- analytics
dependencies:
- v.0.2.0+task.37
- v.0.2.0+task.38
estimated_hours: 16
actual_hours: 0
created_at: 2024-01-01
updated_at: 2024-01-01

---

56. when we create commit descripion then when we update only documents - it should never be 'feat:' prefix in description

- **Use Standard Markdown Links:** When linking to other guides, workflow instructions, or project documents, always use the standard Markdown link format with proper file extensions e.g.: `[Writing Guides Guide](docs-dev/guides/.meta/writing-guides-guide.md)`, `[Commit Workflow](docs-dev/workflow-instructions/commit.wf.md)`. Avoid using just the path in backticks unless discussing the path itself.

57. lint method to do some style checks beyond standard rb (how to combine this with rubocop, or custom linting prompts)

58. it would be easier in task directory if we would see only tasks that are pending ....

- add folders as d/ - done x/ - skipped
- need to update tools to see all the tasks (in the tree)

59. Zed Top Level directory inside the path (problematic in agent when we call tools - that should work always within the primary directory (if not stated otherwise )

60. fish fuzzy search autocomplet for our tools

- adding file
- selecting model in context of the provider
- selecting provider -i

61. when code review we should be able to generate diff (with filtering) but also

- add context (list file to add additional to diff and docs )

62. token counter and token limits for certain models

63. code diff for whole project (or part) ((or part by part))

- tests / by type / folder
- lib
- docs vs lib
- docs vs tests

64. bin/lint --fix or bin/lint filepath-to-changed-files --fix

65. workflow instruction should never encourage to read other workflow insturctions

- add rule to .meta
- udpate workflow instructions that they always read the context they need explicit (similar like its already done in work on task)
- use if statement to run additional resources ( e.g.: if you are working with integrations test and vcr - you calling externa api ) - or have summary of avaialble docs
- and should have high level instructions plan -> something that we currently have in rules (so the rules should be sth like read the document and use high level plan from the workflow instruction

65. guides compression -> rewrite them as rules ? (rules for current tasks)

66. you build iron man suit -> some analogy of interface that serve you

67. The most important is, how easy you make to verify the results of this models ( generation -> goal, objective, directions )

68. tasks status closed vs done (closed - multiple reasons, the end state is the same, we don't work on this task any more, even if its not done)
