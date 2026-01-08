# frozen_string_literal: true

require "ace/core/cli/dry_cli/base"
require_relative "diff_command"

module Ace
  module Git
    module Commands
      # dry-cli command wrapper for diff
      # Bridges dry-cli interface to existing DiffCommand class
      class Diff < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Generate git diff with filtering (default command)"

        option :format, type: :string, aliases: ["f"], default: "diff",
                       desc: "Output format: diff, summary"
        option :since, type: :string, aliases: ["s"],
                      desc: "Changes since date/duration (e.g., '7d', '1 week ago')"
        option :paths, type: :array, aliases: ["p"],
                      desc: "Include only these glob patterns"
        option :exclude, type: :array, aliases: ["e"],
                        desc: "Exclude these glob patterns"
        option :output, type: :string, aliases: ["o"],
                        desc: "Write diff to file instead of stdout"
        option :config, type: :string, aliases: ["c"],
                        desc: "Load config from specific file"
        option :raw, type: :boolean, default: false,
                     desc: "Raw unfiltered output (no exclusions)"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(range: nil, **options)
          DiffCommand.new.execute(range, options)
        end
      end
    end
  end
end
