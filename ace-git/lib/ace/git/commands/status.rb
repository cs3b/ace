# frozen_string_literal: true

require "json"
require "ace/core/cli/dry_cli/base"

module Ace
  module Git
    module Commands
      # dry-cli command for showing repository status
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
            warn "Error: Not in a git repository"
            return 1
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
                status.pr_metadata['number'].to_s
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

          0
        rescue Ace::Git::Error => e
          warn "Error: #{e.message}"
          1
        end
      end
    end
  end
end
