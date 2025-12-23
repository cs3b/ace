# frozen_string_literal: true

require "json"

module Ace
  module Git
    module Commands
      # Command for showing PR information
      class PrCommand
        def execute(number, options)
          # Check if gh is installed
          unless Molecules::PrMetadataFetcher.gh_installed?
            warn "Error: GitHub CLI (gh) not installed. Install with: brew install gh"
            return 1
          end

          # Determine PR identifier
          identifier = if number
                         number.to_s
                       else
                         # Try to find PR for current branch
                         found = Molecules::PrMetadataFetcher.find_pr_for_branch
                         unless found
                           warn "Error: No PR found for current branch. Specify a PR number."
                           return 1
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
            warn "Error: #{result[:error]}"
            return 1
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

          0
        rescue Ace::Git::Error => e
          # Handle all ace-git errors (GhNotInstalledError, GhAuthenticationError,
          # PrNotFoundError, TimeoutError, etc.) with consistent error output
          warn "Error: #{e.message}"
          1
        rescue ArgumentError => e
          warn "Error: #{e.message}"
          1
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
