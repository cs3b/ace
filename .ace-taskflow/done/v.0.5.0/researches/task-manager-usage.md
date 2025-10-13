# Historical Usage Log
# Note: Contains legacy command syntax. Current syntax: context <file>

context --from-agent /Users/michalczyz/Projects/CodingAgent/handbook-meta/.claude/agents/task-manager-agent.md  # [Legacy - now: context /path/to/agent.md]
task-manager next --limit 10
capture-it --commit "task-manager next should return one task by default, but when we pass --limit 0 it shoould return all the pending tasks ready to be work on"
task-manager next --limit 7
task-manager next --limit 5
task-manager next --limit 2
task-manager next --limit -1
task-manager next --limit 0
task-manager list --filter status:draft
task-manager next --limit 9
task-manager next
task-manager all --filter needs_review:true
task-manager all --filter needs_review
task-manager next --limit 4
task-manager create --release v.0.5.0 --title "hi you"
task-manager create --release v.0.5.0 --tiltle "hi you"
task-manager list --release v.0.5.0
task-manager list --filter status:pending
task-manager create --title "setup-firebase-configuration-directory"
which task-manager
task-manager create --title "one one"
task-manager next --limit 6
task-manager next --limit 8 | pbcopy
task-manager create --title "Task Title" --status draft --priority high --estimate "TBD"
task-manager all --filter status:pending
task-manager next  --debug
task-manager list
task-manager
task-manager recent --limit 3
task-manager recent --limit 2
task-manager list --filter needs_review:true
task-manager list --filter need_review:true
task-manager list --filter need-review:true
task-manager list --status draft
task-manager next --limit 3
task-manager recent
ideas-manager capture "in context of task-manager list, in code we are using the old name 'all' -> we should renamed any referenced to old nomenclature to list, and make it aligned with task-manager list"
ideas-manager capture "in context of task-manager - lets print a status on top (when doing any listing how many tasks are in certain state - in one line: draft: 2, panding: 5, done: 20, total: 27"
ideas-manager capture "in context of task-manager we should add subcommand task-create - and migrate it from create-path task-new - as it make more sense"
ideas-manager capture "in context of task-manager add option list - should work exacly the same as all (it should be just an alias)"
task-manager next --limit 12
task-manager next --limit 29
task-manager next --limit 32
task-manager next --limit 16
current/v.0.3.0-workflows/tasks/v.0.3.0+task.119119-implement-compact-output-format-for-task-manager.md
current/v.0.3.0-workflows/tasks/v.0.3.0+task.127127-add-multi-release-support-to-task-manager-commands.md
current/v.0.3.0-workflows/tasks/v.0.3.0+task.119119-implement-compact-output-format-for-task-manager.md
current/v.0.3.0-workflows/tasks/v.0.3.0+task.127127-add-multi-release-support-to-task-manager-commands.md
task-manager recent --limit 3 --release v.0.2.0-synapse
task-manager all --release v.0.2.0-synapse
task-manager all --release v.0.2.0
task-manager all --version v.0.2.0
task-manager all --version v.0.2.0-synapse
task-manager recent --limit 5 --version v.0.2.0-synapse
task-manager recent --limit 5 --version /Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/taskflow/done/v.0.2.0-synapse
task-manager recent --limit 5 --help
task-manager all --last 1.year --release v.0.2.0-synapse-tools
task-manager recent --help
task-manager recent --release v.0.2.0-synapse-tools
task-manager next --release v.0.2.0-synapse-tools
task-manager all --release v.0.2.0-synapse-tools
task-manager all --limit 3 --release v.0.2.0-synapse-tools
task-manager recent --limit 3 --release v.0.2.0-synapse-tools
task-manager recent --limit 3 --release v.0.2.0
task-manager all
task-manager all --limit 3
task-manager reschedule --help
task-manager --version
task-manager generate-id --release backlog
task-manager generate-id
task-manager latest
task-manager all --help
task-manager --help | pbcopy
task-manager recent --limit 5 --filter status:done
task-manager next --filter status:done
task-manager next --sort status:in-progress
task-manager next --sort status:done
task-manager recent --limit 5
task-manager generate-id --format json
task-manager generate-id --help
task-manager next --help
task-manager recent --limit 1
task-manager all --filter status:pending | pbcopy
task-manager all next
.ace/tools/exe/task-manager generate-id
.ace/tools/exe/task-manager next
.ace/tools/exe/task-manager next --limit 3
.ace/tools/exe/task-manager
.ace/tools/exe/task-manager all
.ace/tools/exe/task-manager all]
.ace/tools/exe/task-manager recent --limit 3
.ace/tools/exe/task-manager recent
.ace/tools/exe/task-manager next --help
.ace/tools/exe/task-manager recent --limit 5
.ace/tools/exe/task-manager --help
.ace/tools/exe/task-manager generate-id --limit 3
.ace/tools/exe/task-manager generete-id --limit 3
tree -L 3 -I docs-dev -I tmp -I task-manager | pbcopy
tree -L 3 -I docs-dev -I tmp -I task-manager | pbcopy`
cd task-manager/
git rm -r --cached task-manager tmp
git rm --cached task-manager tmp
tree -L 4 -I docs-dev -I tmp -I task-manager | pbcopy
tree -L 2 -I docs-dev -I tmp -I task-manager | pbcopy
tree -L 2 -I docs-dev -I tmp -I task-manager - pbcopy
tree -L 2 -I docs-dev -I tmp -I task-manager
gcm task-manager/*
git add task-manager
rm -rf  task-manager/.git
git add task-manager/
