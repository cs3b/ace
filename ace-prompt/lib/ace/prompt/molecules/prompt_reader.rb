# frozen_string_literal: true

require "ace/core/molecules/project_root_finder"

module Ace
  module Prompt
    module Molecules
      # Reads prompt file from standard location
      class PromptReader
        # Default prompt file location relative to project root
        DEFAULT_PROMPT_PATH = ".cache/ace-prompt/prompts/the-prompt.md"

        # Read prompt file
        #
        # @param path [String, nil] Optional custom path (default: standard location)
        # @return [Hash] Hash with :content, :path, :success, :error keys
        def self.call(path: nil)
          project_root = Ace::Core::Molecules::ProjectRootFinder.find_or_current
          prompt_path = path || File.join(project_root, DEFAULT_PROMPT_PATH)
          prompt_path = File.expand_path(prompt_path)

          unless File.exist?(prompt_path)
            return {
              content: nil,
              path: prompt_path,
              success: false,
              error: "Prompt file not found: #{prompt_path}"
            }
          end

          # Check if it's a symlink and resolve it
          actual_path = File.realpath(prompt_path)

          content = File.read(actual_path, encoding: "utf-8")

          {
            content: content,
            path: prompt_path,
            actual_path: actual_path,
            success: true,
            error: nil
          }
        rescue StandardError => e
          {
            content: nil,
            path: prompt_path,
            success: false,
            error: "Error reading file: #{e.message}"
          }
        end
      end
    end
  end
end
