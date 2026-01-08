# frozen_string_literal: true

module Ace
  module Taskflow
    module CLI
      # Shared option definitions for dry-cli command classes
      #
      # This module provides composable option sets that mirror the CommandOptionParser
      # sets used by underlying command classes. Commands can include these to ensure
      # the dry-cli wrapper accepts all options the command implementation expects.
      #
      # Usage:
      #   class MyCommand < Dry::CLI::Command
      #     include Ace::Core::CLI::DryCli::Base
      #     extend SharedOptions
      #
      #     use_standard_options         # quiet, verbose, debug
      #     use_display_options          # json, markdown, format, output, etc.
      #     use_limit_options            # limit, recently_done_limit, up_next_limit
      #
      #     def call(**options)
      #       # options will include all defined options
      #     end
      #   end
      #
      module SharedOptions
        # Standard options available in all CLI commands
        # Maps to: quiet, verbose, debug (from Base)
        def use_standard_options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"
        end

        # Display/formatting options
        # Maps to CommandOptionParser :display set
        def use_display_options
          option :json, type: :boolean, desc: "Output as JSON"
          option :markdown, type: :boolean, desc: "Output as Markdown"
          option :format, type: :string, desc: "Output format"
          option :output, type: :string, aliases: %w[-o], desc: "Output file path"
          option :stats, type: :boolean, desc: "Show statistics"
          option :tree, type: :boolean, desc: "Show tree structure"
          option :short, type: :boolean, desc: "Short output (hide paths)"
        end

        # Release selection options
        # Maps to CommandOptionParser :release set
        def use_release_options
          option :release, type: :string, desc: "Filter by release"
          option :backlog, type: :boolean, desc: "Show backlog items"
          option :current, type: :boolean, desc: "Show current release items"
          option :all, type: :boolean, desc: "Show all items"
        end

        # Filtering options
        # Maps to CommandOptionParser :filter set
        def use_filter_options
          option :filter, type: :array, desc: "Filter by key:value (repeatable)"
          option :filter_clear, type: :boolean, desc: "Clear preset filters"
          option :status, type: :string, desc: "Filter by status"
        end

        # Numeric limit options
        # Maps to CommandOptionParser :limits set
        def use_limit_options
          option :limit, type: :integer, desc: "Limit number of results"
          option :days, type: :integer, desc: "Number of days for time-based filters"
          option :recently_done_limit, type: :integer, desc: "Max recently done items"
          option :up_next_limit, type: :integer, desc: "Max up next items"
        end

        # Subtask display options
        # Maps to CommandOptionParser :subtasks set
        def use_subtask_options
          option :include_drafts, type: :boolean, desc: "Include draft tasks"
          option :include_activity, type: :boolean, desc: "Include activity section"
        end

        # Action options
        # Maps to CommandOptionParser :actions set
        def use_action_options
          option :dry_run, type: :boolean, desc: "Show what would be done"
        end

        # Helper to convert numeric options from strings to integers
        # dry-cli returns all options as strings
        #
        # @param options [Hash] Options hash to process (modified in place)
        # @param keys [Array<Symbol>] Keys to convert
        # @return [Hash] The same options hash with converted values
        # @raise [ArgumentError] if a value cannot be parsed as an integer
        # @note This method modifies the options hash in place for efficiency
        def self.convert_numeric_options(options, *keys)
          keys.each do |key|
            next unless options[key]

            begin
              options[key] = Integer(options[key])
            rescue ArgumentError, TypeError
              raise ArgumentError, "Invalid value for --#{key.to_s.tr('_', '-')}: " \
                                   "'#{options[key]}' is not a valid integer"
            end
          end
          options
        end

        # Standard numeric options that need conversion
        NUMERIC_OPTIONS = %i[limit days recently_done_limit up_next_limit].freeze
      end
    end
  end
end
