# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../commands/tasks_command"
require_relative "../shared_options"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the tasks command
        #
        # Browse and list multiple tasks.
        class Tasks < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Browse and list multiple tasks"
          example ['--status pending  # List pending tasks', '--all             # List all tasks']

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          option :json, type: :boolean, desc: "Output as JSON"
          option :markdown, type: :boolean, desc: "Output as Markdown"
          option :format, type: :string, desc: "Output format"
          option :output, type: :string, aliases: %w[-o], desc: "Output file path"
          option :stats, type: :boolean, desc: "Show statistics"
          option :tree, type: :boolean, desc: "Show tree structure"
          option :short, type: :boolean, desc: "Short output (hide paths)"

          option :release, type: :string, desc: "Filter by release"
          option :backlog, type: :boolean, desc: "Show backlog items"
          option :current, type: :boolean, desc: "Show current release items"
          option :all, type: :boolean, desc: "Show all items"

          option :filter, type: :array, desc: "Filter by key:value (repeatable)"
          option :filter_clear, type: :boolean, desc: "Clear preset filters"
          option :status, type: :string, desc: "Filter by status"

          option :limit, type: :integer, desc: "Limit number of results"
          option :days, type: :integer, desc: "Number of days for time-based filters"
          option :recently_done_limit, type: :integer, desc: "Max recently done items"
          option :up_next_limit, type: :integer, desc: "Max up next items"

          option :include_drafts, type: :boolean, desc: "Include draft tasks"
          option :include_activity, type: :boolean, desc: "Include activity section"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            SharedOptions.convert_numeric_options(clean_options, *SharedOptions::NUMERIC_OPTIONS)
            ::Ace::Taskflow::Commands::TasksCommand.new.execute(args, clean_options)
          end
        end
      end
    end
  end
end
