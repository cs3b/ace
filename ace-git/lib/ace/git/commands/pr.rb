# frozen_string_literal: true

require "ace/core/cli/dry_cli/base"
require_relative "pr_command"

module Ace
  module Git
    module Commands
      # dry-cli command wrapper for pr
      # Bridges dry-cli interface to existing PrCommand class
      class Pr < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Show PR information"

        argument :number, required: false, desc: "PR number (auto-detected if not provided)"

        option :format, type: :string, aliases: ["f"], default: "markdown",
                       desc: "Output format: markdown, json"
        option :with_diff, type: :boolean, default: false,
                          desc: "Include PR diff in output"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(number: nil, **options)
          PrCommand.new.execute(number, options)
        end
      end
    end
  end
end
