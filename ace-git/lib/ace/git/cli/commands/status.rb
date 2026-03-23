# frozen_string_literal: true

require "json"
require "ace/support/cli"

module Ace
  module Git
    module CLI
      module Commands
        # ace-support-cli command for showing repository status
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

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
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            # Determine PR settings based on --no-pr flag
            skip_pr = options[:no_pr]
            commits_limit = options[:commits] || Ace::Git.commits_limit

            # Load status
            status_options = {
              include_pr: !skip_pr,
              include_pr_activity: !skip_pr,
              include_commits: commits_limit > 0,
              commits_limit: commits_limit,
              timeout: Ace::Git.network_timeout
            }

            status = Organisms::RepoStatusLoader.load(status_options)

            # Check for errors
            if status.branch.nil? && status.repository_type == :not_git
              raise Ace::Support::Cli::Error.new("Not in a git repository")
            end

            # Output based on format
            case options[:format]
            when "json"
              puts JSON.pretty_generate(status.to_h)
            else
              puts status.to_markdown
            end

            # Include diff if requested
            if options[:with_diff] && status.has_pr?
              begin
                diff_result = Molecules::PrMetadataFetcher.fetch_diff(
                  status.pr_metadata["number"].to_s
                )
                if diff_result[:success]
                  puts ""
                  puts "## PR Diff"
                  puts ""
                  puts "```diff"
                  puts diff_result[:diff]
                  puts "```"
                end
              rescue Ace::Git::Error
                # Silently skip diff if it fails
              end
            end
          rescue Ace::Git::Error => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
