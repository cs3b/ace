# frozen_string_literal: true

require "ace/core/cli/dry_cli/base"
require_relative "status_command"

module Ace
  module Git
    module Commands
      # dry-cli command wrapper for status
      # Bridges dry-cli interface to existing StatusCommand class
      class Status < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Show repository context (branch, PR, activity)"

        option :format, type: :string, aliases: ["f"], default: "markdown",
                       desc: "Output format: markdown, json"
        option :with_diff, type: :boolean, default: false,
                          desc: "Include PR diff in output"
        option :no_pr, type: :boolean, default: false, aliases: ["n"],
                      desc: "Skip all PR lookups (faster, no network)"
        option :commits, type: :integer, aliases: ["c"],
                        desc: "Number of recent commits to show (0 to disable, default: config)"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(**options)
          StatusCommand.new.execute(options)
        end
      end
    end
  end
end
