# frozen_string_literal: true

module Ace
  module Prompt
    module Molecules
      # Load context via ace-context delegation
      class ContextLoader
        class ContextLoadError < Ace::Prompt::Error; end

        # Load context using ace-context --embed-source
        # @param prompt_path [String] Path to prompt file with frontmatter
        # @return [String] Complete output with context embedded
        # @raise [ContextLoadError] if ace-context fails
        def self.load(prompt_path)
          unless File.exist?(prompt_path)
            raise ContextLoadError, "Prompt file not found: #{prompt_path}"
          end

          # Delegate to ace-context with --embed-source flag
          # ace-context handles empty context gracefully - just passes through
          cmd = "ace-context '#{prompt_path}' --embed-source 2>&1"
          output = `#{cmd}`

          if $?.success?
            output
          else
            raise ContextLoadError, "ace-context failed: #{output}"
          end
        rescue => e
          warn "Warning: Context loading failed: #{e.message}"
          # Fall back to reading file without context
          File.read(prompt_path)
        end

        # Check if ace-context is available
        # @return [Boolean] True if ace-context command exists
        def self.available?
          system("which ace-context > /dev/null 2>&1")
        end
      end
    end
  end
end
