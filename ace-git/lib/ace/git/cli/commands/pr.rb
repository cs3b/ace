# frozen_string_literal: true

require "json"
require "ace/support/cli"

module Ace
  module Git
    module CLI
      module Commands
      # ace-support-cli command for showing PR information
      class Pr < Ace::Support::Cli::Command
        include Ace::Support::Cli::Base

        desc "Show PR information"

        argument :number, required: false, desc: "PR number (auto-detected if not provided)"

        option :format, type: :string, aliases: ["f"], default: "markdown",
                       desc: "Output format: markdown, json"
        option :with_diff, type: :boolean, default: false,
                          desc: "Include PR diff in output"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

        def call(number: nil, **options)
          # Check if gh is installed
          unless Molecules::PrMetadataFetcher.gh_installed?
            raise Ace::Support::Cli::Error.new("GitHub CLI (gh) not installed. Install with: brew install gh")
          end

          # Determine PR identifier
          identifier = if number
                         number.to_s
                       else
                         # Try to find PR for current branch
                         found = Molecules::PrMetadataFetcher.find_pr_for_branch
                         unless found
                           raise Ace::Support::Cli::Error.new("No PR found for current branch. Specify a PR number.")
                         end
                         found
                       end

          # Fetch PR data
          result = if options[:with_diff]
                     Molecules::PrMetadataFetcher.fetch_pr(identifier)
                   else
                     Molecules::PrMetadataFetcher.fetch_metadata(identifier)
                   end

          unless result[:success]
            raise Ace::Support::Cli::Error.new(result[:error])
          end

          # Output based on format
          case options[:format]
          when "json"
            output_data = { metadata: result[:metadata] }
            output_data[:diff] = result[:diff] if options[:with_diff]
            puts JSON.pretty_generate(output_data)
          else
            output_markdown(result[:metadata], result[:diff], options)
          end

        rescue Ace::Git::Error => e
          raise Ace::Support::Cli::Error.new(e.message)
        rescue ArgumentError => e
          raise Ace::Support::Cli::Error.new(e.message)
        end

        private

        def output_markdown(metadata, diff, options)
          lines = []

          # Header line: # PR #82: Title... [OPEN]
          header = "# PR ##{metadata['number']}"
          header += ": #{metadata['title']}" if metadata['title']
          header += " [#{metadata['state']}]" if metadata['state']
          lines << header

          # Branch line: Branch: source → target | Draft: No
          branch_parts = []
          if metadata['headRefName'] && metadata['baseRefName']
            branch_parts << "Branch: #{metadata['headRefName']} → #{metadata['baseRefName']}"
          elsif metadata['headRefName']
            branch_parts << "Branch: #{metadata['headRefName']}"
          elsif metadata['baseRefName']
            branch_parts << "Target: #{metadata['baseRefName']}"
          end
          branch_parts << "Draft: #{metadata['isDraft'] ? 'Yes' : 'No'}" if metadata.key?('isDraft')
          lines << branch_parts.join(" | ") unless branch_parts.empty?

          # Author line
          if metadata['author']
            author = metadata['author'].is_a?(Hash) ? metadata['author']['login'] : metadata['author']
            lines << "Author: #{author}"
          end

          # URL line
          lines << "URL: #{metadata['url']}" if metadata['url']

          if options[:with_diff] && diff
            lines << ""
            lines << "## Diff"
            lines << ""
            lines << "```diff"
            lines << diff
            lines << "```"
          end

          puts lines.join("\n")
        end
      end
    end
  end
end
end
