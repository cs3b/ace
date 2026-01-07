# frozen_string_literal: true

require "ace/core/cli/dry_cli/base"
require_relative "branch_command"

module Ace
  module Git
    module Commands
      # dry-cli command wrapper for branch
      # Bridges dry-cli interface to existing BranchCommand class
      class Branch < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Show current branch information"

        option :format, type: :string, aliases: ["f"], default: "text",
                       desc: "Output format: text, json"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(**options)
          BranchCommand.new.execute(options)
        end
      end
    end
  end
end
