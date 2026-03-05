# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "cli/commands/record"
require_relative "cli/commands/attach"
require_relative "cli/commands/list"
require_relative "cli/commands/show"
require_relative "cli/commands/create"
require_relative "version"

module Ace
  module Demo
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-demo"

      REGISTERED_COMMANDS = [
        ["list", "List available demo tapes"],
        ["show", "Show metadata and contents for a demo tape"],
        ["record", "Record a VHS tape to gif/mp4/webm"],
        ["attach", "Attach an existing demo GIF to a PR"],
        ["create", "Create a new demo tape from shell commands"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-demo list",
        "ace-demo show hello",
        "ace-demo record hello",
        "ace-demo record ./custom.tape --format mp4",
        "ace-demo record hello --output /tmp/demo.gif",
        "ace-demo record my-demo -- \"git status\" \"make deploy\"",
        "ace-demo record my-demo --timeout 3s --width 1200 -- \"git status\"",
        "ace-demo attach .ace-local/demo/hello.gif --pr 123",
        "ace-demo record hello --pr 123 --dry-run",
        "ace-demo create my-demo -- \"git status\" \"make deploy\"",
        "ace-demo create my-demo --desc \"Deploy flow\" --dry-run -- \"echo hello\"",
        "ace-demo create my-demo --timeout 3s --width 1200 -- \"git status\""
      ].freeze

      register "list", Commands::List
      register "show", Commands::Show
      register "record", Commands::Record
      register "attach", Commands::Attach
      register "create", Commands::Create

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-demo",
        version: Ace::Demo::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Demo::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
