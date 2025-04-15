# Project Blueprint: ai-ruby-agent-sdk

This document provides a dynamic overview of the `ai-ruby-agent-sdk` project structure and key files. It should be regenerated periodically (e.g., using the `generate-blueprint` command) to reflect the current state.

## Core Project Documents
- [What We Build](what-do-we-build.md)
- [Architecture](architecture.md)

## Key Directories & Files

*(Run `tree -L 2 -I docs-dev -I tmp -I task-manager | pbcopy` or similar for a current view)*

```
.
├── CHANGELOG.md
├── Gemfile
├── Gemfile.lock
├── LICENSE
├── README.md
├── Rakefile
├── airarb.gemspec
├── bin
│   ├── console
│   ├── publish
│   ├── rspec
│   ├── setup
│   └── standardrb
├── coverage
│   ├── assets
│   │   └── 0.13.1
│   │       ├── DataTables-1.10.20
│   │       ├── application.css
│   │       ├── application.js
│   │       ├── colorbox
│   │       ├── favicon_green.png
│   │       ├── favicon_red.png
│   │       ├── favicon_yellow.png
│   │       ├── images
│   │       ├── loading.gif
│   │       └── magnify.png
│   └── index.html
├── examples
│   ├── weather_agent.rb
│   └── web_extractor.rb
├── lib
│   ├── aira
│   │   ├── agent.rb
│   │   ├── dsl.rb
│   │   ├── errors.rb
│   │   ├── file_queue.rb
│   │   ├── logger.rb
│   │   ├── prompt.rb
│   │   ├── registry.rb
│   │   ├── step.rb
│   │   ├── tool.rb
│   │   ├── tool_registry.rb
│   │   ├── tool_registry_adapter.rb
│   │   ├── tools
│   │   │   ├── file_tool.rb
│   │   │   ├── registry.rb
│   │   │   └── weather_tool.rb
│   │   ├── tools.rb
│   │   └── version.rb
│   └── aira.rb
└── spec
    ├── aira
    │   └── version_spec.rb
    ├── end_to_end
    │   └── workflows
    ├── integration
    ├── spec_helper.rb
    ├── support
    │   ├── agent_helpers.rb
    │   └── tool_helpers.rb
    └── unit
        ├── agents
        │   ├── agent_spec.rb
        │   └── step_spec.rb
        ├── core
        │   ├── dsl_spec.rb
        │   ├── registry_spec.rb
        │   ├── tool_registry_spec.rb
        │   └── tool_spec.rb
        └── tools
            ├── file_tool_spec.rb
            └── weather_tool_spec.rb

```

## Key Project-Specific Files
- **Version:** `lib/aira/version.rb`
- **Gemspec:** `ai-ruby-agent-sdk.gemspec`
- **Main Entrypoint:** `lib/aira.rb` (if applicable)
- **Core Test Helper:** `spec/spec_helper.rb`
