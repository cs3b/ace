# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/doctor_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      class Doctor < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base
        extend SharedOptions

        desc "Run health checks and auto-fix issues"
        example [
          '                   # Run all health checks',
          '--fix              # Auto-fix issues',
          '--check subtasks   # Run specific check',
          '--json             # Output as JSON'
        ]

        use_standard_options
        use_display_options
        use_release_options
        use_action_options

        # Doctor-specific options
        option :component, type: :string, aliases: %w[-c], desc: "Check specific component"
        option :check, type: :string, desc: "Run specific check"
        option :subtasks, type: :boolean, desc: "Shorthand for --check subtasks"
        option :fix, type: :boolean, aliases: %w[-f], desc: "Attempt to auto-fix issues"
        option :errors_only, type: :boolean, desc: "Show only errors, not warnings"
        option :no_color, type: :boolean, desc: "Disable colored output"

        def call(**options)
          args = options[:args] || []
          clean_options = options.reject { |k, _| k == :args }
          Commands::DoctorCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
