# frozen_string_literal: true

require "ace/context"

module Ace
  module Prompt
    module Molecules
      # Load context via ace-context delegation
      class ContextLoader
        class ContextLoadError < Ace::Prompt::Error; end

        # Load context using ace-context Ruby API
        # @param prompt_path [String] Path to prompt file with frontmatter
        # @return [String] Complete output with context embedded
        # @raise [ContextLoadError] if ace-context fails
        def self.load(prompt_path)
          unless File.exist?(prompt_path)
            raise ContextLoadError, "Prompt file not found: #{prompt_path}"
          end

          # Use Ruby API instead of shell command (security fix)
          # ace-context handles empty context gracefully - just passes through
          begin
            result = Ace::Context.load_file(prompt_path, embed_source: true)

            if result.metadata[:error]
              raise ContextLoadError, "ace-context failed: #{result.metadata[:error]}"
            end

            result.content
          rescue LoadError => e
            # ace-context gem not available - fallback to raw content
            warn "Warning: ace-context not available: #{e.message}"
            File.read(prompt_path)
          rescue => e
            raise ContextLoadError, "Context loading failed: #{e.message}"
          end
        end

        # Check if ace-context is available
        # @return [Boolean] True if ace-context gem is loaded
        def self.available?
          defined?(Ace::Context) && Ace::Context.respond_to?(:load_file)
        end
      end
    end
  end
end
