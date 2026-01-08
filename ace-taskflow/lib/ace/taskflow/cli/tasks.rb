# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/tasks_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      class Tasks < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Browse and list multiple tasks"
        example ['--status pending  # List pending tasks', '--all             # List all tasks']

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q]
        option :verbose, type: :boolean, aliases: %w[-v]
        option :debug, type: :boolean, aliases: %w[-d]

        # Display options
        option :json, type: :boolean
        option :markdown, type: :boolean
        option :format, type: :string
        option :output, type: :string, aliases: %w[-o]
        option :stats, type: :boolean
        option :tree, type: :boolean
        option :short, type: :boolean

        # Release selection options (from SharedOptions::use_release_options)
        option :release, type: :string, desc: "Filter by release"
        option :backlog, type: :boolean, desc: "Show backlog items"
        option :current, type: :boolean, desc: "Show current release items"
        option :all, type: :boolean, desc: "Show all items"

        # Filter options (from SharedOptions::use_filter_options)
        option :filter, type: :array, desc: "Filter by key:value (repeatable)"
        option :filter_clear, type: :boolean, desc: "Clear preset filters"
        option :status, type: :string, desc: "Filter by status"

        # Limit options
        option :limit, type: :integer
        option :days, type: :integer, desc: "Number of days for time-based filters"
        option :recently_done_limit, type: :integer
        option :up_next_limit, type: :integer

        # Subtask options
        option :include_drafts, type: :boolean
        option :include_activity, type: :boolean

        def call(**options)
          args = options[:args] || []
          clean_options = options.reject { |k, _| k == :args }
          SharedOptions.convert_numeric_options(clean_options, *SharedOptions::NUMERIC_OPTIONS)
          Commands::TasksCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
