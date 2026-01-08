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
          Commands::TasksCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
