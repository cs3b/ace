# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Extracts review subject (code to review) from various sources
      # Delegates to ace-context for unified content aggregation
      class SubjectExtractor
        def initialize
          @git = Ace::Context::Atoms::GitExtractor
        end

        # Extract subject from configuration
        # @param subject_config [String, Hash] subject configuration
        # @return [String] extracted subject content
        def extract(subject_config)
          return "" unless subject_config

          case subject_config
          when String
            extract_from_string(subject_config)
          when Hash
            extract_from_hash(subject_config)
          else
            ""
          end
        end

        private

        def extract_from_string(input)
          # Try to parse as YAML first
          begin
            parsed = YAML.safe_load(input)
            return extract_from_hash(parsed) if parsed.is_a?(Hash)
          rescue Psych::SyntaxError
            # Continue with string processing
          end

          # Handle special keywords
          case input.downcase
          when "staged"
            return @git.staged_diff
          when "working", "unstaged"
            return @git.working_diff
          when "pr", "pull-request"
            tracking = @git.tracking_branch
            range = tracking ? "#{tracking}...HEAD" : "origin/main...HEAD"
            return use_ace_context({ "diffs" => [range] })
          end

          # Check if it's a git range
          if looks_like_git_range?(input)
            return use_ace_context({ "diffs" => [input] })
          end

          # Check if it's a file pattern
          if input.include?("*") || input.include?("/")
            return use_ace_context({ "files" => [input] })
          end

          # Default to git diff
          use_ace_context({ "diffs" => [input] })
        end

        def extract_from_hash(config)
          # Transform config to ace-context format
          context_config = {}

          # Map 'diff' to 'diffs' for ace-context
          if config["diff"]
            context_config["diffs"] = [config["diff"]]
          end

          # Copy compatible keys
          context_config["files"] = config["files"] if config["files"]
          context_config["commands"] = config["commands"] if config["commands"]

          use_ace_context(context_config)
        end

        def use_ace_context(config)
          # Use ace-context for unified content extraction
          result = Ace::Context.load_auto(YAML.dump(config), format: 'markdown')
          result.content
        rescue StandardError => e
          warn "ace-context extraction failed: #{e.message}" if Ace::Review.debug?
          ""
        end

        def looks_like_git_range?(input)
          input.include?("..") ||
            input.include?("HEAD") ||
            input.include?("~") ||
            input.include?("^") ||
            input.match?(/^[a-f0-9]{6,40}/)
        end
      end
    end
  end
end