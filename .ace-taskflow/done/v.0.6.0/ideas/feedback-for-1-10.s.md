Feedback for the recent work in context of release .ace/taskflow/current/v.0.6.0-unified-claude/v.0.6.0-unified-claude.md

0. we don't need prepare or update commands.json - nor we neither claude code needs it

   a) remove handbook claude update-registry tool implementation / tests
   b) update the documents that mention it (commands.json and update-registry) (in whole project)
   c) remove .claude/commands/commands.json

1. improve templates
    a) .ace/handbook/.integrations/claude/command.template.md should be moved to .ace/handbook/.integrations/claude/templates/command.md.tmpl

    b) .ace/handbook/.integrations/claude/templates/command.md.tmpl looks like duplication with .ace/handbook/.integrations/claude/templates/workflow-command.md.tmpl
       - find the usage
       - propose how we can have only one tmpl
       - or maybe this is not a duplication - investigate it (one is used by tool and other by coding agent, still it would be nice to figure out how to keep only one)

    c) should we use tmpl es extension for all templates we use ? what is the implications ? - just share you opinion

2. we don't need claude-integrate migration (as we developed it the same day we see it's something bigger, and we remake it, nobody use it before)

   a) remove .ace/handbook/.integrations/claude/MIGRATION.md
   b) update .ace/handbook/.integrations/claude/README.md

3. meta workflows and guides / templates / integrations - are different spicies

  a) .ace/handbook/workflow-instructions/README.md (remove mention of the meta workflows)

4. enhance readability for `handbook claude list`

  a) use table appproach to list them in 3 columns (it will be shorte and easier to read)
     - is in .claude (only checkmark)
     - command type (custom / generated
     - checkmark in dev-handbok (everything ok)
     - command name

  b) be aware of feedack 5. (that we have to fix location of .claude/commands)

5. commands in claude code are not flatten

.claude/commands
├── _custom
│   ├── commit.md
│   ├── draft-tasks.md
│   ├── load-project-context.md
│   ├── plan-tasks.md
│   ├── review-tasks.md
│   └── work-on-tasks.md
├── _generated
│   ├── capture-idea.md
│   ├── create-adr.md
│   ├── create-api-docs.md

   a) they should all be in .claude/commands (without subfolder _custom / _generated - this structure is only used in .ace/handbook)

6. coding agent is not a gem, it just a lib (you mount it as git submodule directly from github)

   a) .ace/handbook/.integrations/claude/README.md - remove info about installation -> its not responsibility of this file

   b) each handbook claude tool should be described in details in .ace/tools/docs/user/handbook-claude-{subcommand}.md as general documenation of tools - do it

   c) .ace/handbook/.integrations/claude/README.md should be the quickstart guide (shorter focus on do it first time and maintenence workflow)

7. this file have been created in wrong path:

   a) move .ace/taskflow/releases/v.0.6.0-unified-claude/docs/MIGRATION_REPORT.md .ace/taskflow/current/v.0.6.0-unified-claude/docs/MIGRATION_REPORT.md

   b) investigate why it happend

8. we should refactor the .ace/tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb (i've gave bad feedback for the task, my bad)

   a) claude integration should be also implemented according to ATOM architecture - redesign its responsibility, and how to fit it within current structure

   b) do it also with tests

   c) after refactoring the implemeation and tests, just remove .ace/tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb and correspondin tests .ace/tools/spec/integrations/claude_commands_installer_spec.rb

   c) ensure to update docs .ace/tools/docs/development/claude-integration.md

9. check the whole implementation of handbook claude <tool> and check if anything should be refactored at lower level of the ATOM architecture, is there anything that can be reused between commands
