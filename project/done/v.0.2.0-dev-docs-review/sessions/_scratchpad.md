Feedback after review
docs-dev/project/current/v.0.2.0/v.0.2.0-StreamlineWorkflow.md

- goal 1. a) agree to keep the initial format simple but flexible b) lets-spec-from-pr-comments server only to fetch review comments from pull request and creating task for it. We definitly need to have similar command to transfer high level requirement document in to release (they should work similar, still they have different context so it have to be kept well). lets-spec-from-pr-comments was worked on recently and it helped a lot
- goal 2. a) Clear guidelines on which parts of the `prepare-release` (in context of previous comment - feedback from pr comments should be a specific version of patch) b) simplification yes - we don't want more content then we need, just clear straight forward and handy instructions (comprehensive documentaiton is a key)
- goal 3. a) we should use only backlog -> current -> done (no next)
- goal 4. a) we should create the proper cycle of finding the options, selecting the best one, getting feedback (from llm models firs), next from feedback from human and based on that apply the changes b) in order to allow agent work undepedent for longer period we should also have prompt / techniques to find what is missing (analyze the code / libs we can use - and ensure the everything that can be defined upfront is defined upfront)


Feedback to:
docs-dev/project/current/v.0.2.0/docs/unified-workflow-guide.md

I like ## Core Workflow Commands - stil some workflow go in the loop:

-  1,2,3,4 & 7 shouold be run for each *task cycle*
-  1,5,6,7 - and after that *pr feedback cycle*, it should be started and task cycyle for each created task
- after 6 show that everything is done then *release cycle*
- 1,6,7,8 - is a *release cycle*

Not sure i've captured everything but for sure session should always point about what cycle we are ( not sure that cycle is the best word, but maybe we can find better word )

Feedback to:
docs-dev/project/current/v.0.2.0/decisions/ADR-001-Unified-Task-Management.md

### Negative

- as part of preparing release we can have a command to analyze complexity that using llm and release documents we can also add to tasks

### Neutral

- the file based system have it's own complexity, still it works - it allow to manage tasks and releases efficiently within the repo, with proper defined commands and cycles / workflows (even with what we have now i was able to process feedback to pretty large pr with success)

The Final decision is to go with the file based system if we would need to create simple tools (we have utils folder for that), or even simple agents (or mcp servers), then lets' not limit ourself with just plain text instructions (but the effort vs value must justified)



Feedback tasks/* in general

should they have checkboxes for subtasks - then we distinc context of the tasks from the subtasks that need to be executed


Feedback to:
docs-dev/project/current/v.0.2.0/tasks/02-update-commands.md

- we need command let's spec from prd (product requirement document - the one when we start working on the project)
- we need command let's spec from frd (feature requirement document - when we add feature or features to the project)

In both above cases - it might result in creating more then one release (for prd for sure, but for frd sometimes depend on the complexity of the feature / features)

A lot of the logic should be taken from prepare-release-documentation.md that should be removed and finaly we would have 3 ways to prepare spec (pr / prd / frd)

When working with all of this 3 documents it's good to have in mind that developer might add some files for release without number as reference document that should be used in the process
