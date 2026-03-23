# frozen_string_literal: true

require "ace/support/fs"

module Ace
  module PromptPrep
    module Molecules
      # Reads prompt file from standard location
      class PromptReader
        # Default prompt file location relative to project root (fallback if config unavailable)
        DEFAULT_CACHE_DIR = Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR
        DEFAULT_PROMPT_FILE = "prompts/the-prompt.md"

        # Get prompt path from config or use fallback
        # @return [String] Prompt path relative to project root
        def self.prompt_path_from_config
          config = Ace::PromptPrep.config
          cache_dir = config.dig("paths", "cache_dir") || DEFAULT_CACHE_DIR
          prompt_file = config.dig("paths", "prompt_file") || DEFAULT_PROMPT_FILE
          File.join(cache_dir, prompt_file)
        end

        # Read prompt file
        #
        # @param path [String, nil] Optional custom path (default: standard location)
        # @return [Hash] Hash with :content, :path, :success, :error keys
        def self.call(path: nil)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          prompt_path = path || File.join(project_root, prompt_path_from_config)
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
        rescue => e
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
