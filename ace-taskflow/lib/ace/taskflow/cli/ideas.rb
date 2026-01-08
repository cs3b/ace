# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/ideas_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      class Ideas < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base
        extend SharedOptions

        desc "Browse and list multiple ideas"
        example [
          '            # List pending ideas (default)',
          'all         # List all ideas',
          '--limit 10  # Limit to 10 results',
          '--short     # Hide file paths'
        ]

        use_standard_options
        use_display_options
        use_release_options
        use_filter_options
        use_limit_options

        def call(**options)
          args = options[:args] || []
          SharedOptions.convert_numeric_options(options, *SharedOptions::NUMERIC_OPTIONS)
          clean_options = options.reject { |k, _| k == :args }
          Commands::IdeasCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
