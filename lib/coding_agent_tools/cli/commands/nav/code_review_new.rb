# frozen_string_literal: true

require_relative "../../molecules/path_resolver"

module CodingAgentTools
  module CLI
    module Commands
      module Nav
        # CLI command for generating new code review session paths
        class CodeReviewNew
          def initialize(path_resolver = nil)
            @path_resolver = path_resolver || Molecules::PathResolver.new
          end

          def call(session_name: nil, **options)
            unless session_name
              puts "Error: Session name is required"
              puts "Usage: nav-path code-review-new \"session name\""
              puts "Example: nav-path code-review-new \"docs-handbook-workflows\""
              return false
            end

            result = @path_resolver.resolve_path(session_name, type: :code_review_new)

            if result[:success]
              puts result[:path]
              true
            else
              puts "Error: #{result[:error]}"
              false
            end
          rescue => e
            puts "Error generating code review session path: #{e.message}"
            false
          end
        end
      end
    end
  end
end
