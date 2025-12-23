# frozen_string_literal: true

require "json"

module Ace
  module Git
    module Commands
      # Command for showing repository context
      class ContextCommand
        def execute(options)
          # Load context
          context_options = {
            include_pr: true,
            timeout: 30
          }

          context = Organisms::RepoContextLoader.load(context_options)

          # Check for errors
          if context.branch.nil? && context.repository_type == :not_git
            warn "Error: Not in a git repository"
            return 1
          end

          # Output based on format
          case options[:format]
          when "json"
            puts JSON.pretty_generate(context.to_h)
          else
            puts context.to_markdown
          end

          # Include diff if requested
          if options[:with_diff] && context.has_pr?
            begin
              diff_result = Molecules::PrMetadataFetcher.fetch_diff(
                context.pr_metadata['number'].to_s
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
