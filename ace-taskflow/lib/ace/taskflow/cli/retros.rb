# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/retros_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      class Retros < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base
        extend SharedOptions

        desc "Browse and list multiple retrospective notes"
        example [
          '            # List active retros (default)',
          '--all       # List all retros including done',
          '--done      # List only done retros',
          '--limit 5   # Limit results'
        ]

        use_standard_options
        use_release_options
        use_limit_options
        option :done, type: :boolean, desc: "Show only done retros"

        def call(**options)
          args = options[:args] || []
          SharedOptions.convert_numeric_options(options, *SharedOptions::NUMERIC_OPTIONS)
          clean_options = options.reject { |k, _| k == :args }
          Commands::RetrosCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
