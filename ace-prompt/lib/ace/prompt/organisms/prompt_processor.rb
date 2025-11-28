# frozen_string_literal: true

require_relative "../molecules/prompt_reader"
require_relative "../molecules/prompt_archiver"

module Ace
  module Prompt
    module Organisms
      # Orchestrates read → archive → output flow
      class PromptProcessor
        # Process prompt: read, archive, return content
        #
        # @param input_path [String, nil] Optional custom input path
        # @return [Hash] Hash with :content, :archive_path, :success, :error keys
        def self.call(input_path: nil)
          # Read prompt
          read_result = Molecules::PromptReader.call(path: input_path)
          unless read_result[:success]
            return {
              content: nil,
              archive_path: nil,
              success: false,
              error: read_result[:error]
            }
          end

          content = read_result[:content]

          # Archive prompt
          archive_result = Molecules::PromptArchiver.call(content: content)
          unless archive_result[:success]
            return {
              content: content,
              archive_path: nil,
              success: false,
              error: archive_result[:error]
            }
          end

          # Return content and archive info
          {
            content: content,
            archive_path: archive_result[:archive_path],
            symlink_path: archive_result[:symlink_path],
            symlink_updated: archive_result[:symlink_updated],
            success: true,
            error: nil
          }
        end
      end
    end
  end
end
