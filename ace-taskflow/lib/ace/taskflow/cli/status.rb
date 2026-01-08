# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/status_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      class Status < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Show current taskflow status and activity

          SYNTAX:
            ace-taskflow status [OPTIONS]

          EXAMPLES:

            # Show status
            $ ace-taskflow status
            $ ace-taskflow context

            # JSON output
            $ ace-taskflow status --json

          CONFIGURATION:

            Global config:  ~/.ace/taskflow/config.yml
            Project config: .ace/taskflow/config.yml
            Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

          OUTPUT:

            Shows: Release info, current task, task activity
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          '                 # Show status',
          '--json           # JSON output'
        ]

        option :quiet, type: :boolean, aliases: %w[-q]
        option :verbose, type: :boolean, aliases: %w[-v]
        option :debug, type: :boolean, aliases: %w[-d]
        option :json, type: :boolean
        option :markdown, type: :boolean
        option :status, type: :string
        option :stats, type: :boolean
        option :tree, type: :boolean
        option :format, type: :string
        option :limit, type: :integer
        option :all, type: :boolean
        option :recently_done_limit, type: :integer
        option :up_next_limit, type: :integer
        option :include_drafts, type: :boolean
        option :include_activity, type: :boolean
        option :output, type: :string, aliases: %w[-o]

        def call(**options)
          args = options[:args] || []
          clean_options = options.reject { |k, _| k == :args }
          SharedOptions.convert_numeric_options(clean_options, *SharedOptions::NUMERIC_OPTIONS)
          Commands::StatusCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
