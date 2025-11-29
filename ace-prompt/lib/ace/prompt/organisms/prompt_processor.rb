# frozen_string_literal: true

require_relative "../molecules/prompt_reader"
require_relative "../molecules/prompt_archiver"
require_relative "../atoms/frontmatter_extractor"
require_relative "../molecules/context_loader"

module Ace
  module Prompt
    module Organisms
      # Orchestrates read → archive → context → output flow
      class PromptProcessor
        # Process prompt: read, archive, optionally load context, return content
        #
        # @param input_path [String, nil] Optional custom input path
        # @param context [Boolean] Whether to load context from frontmatter
        # @return [Hash] Hash with :content, :archive_path, :success, :error keys
        def self.call(input_path: nil, context: false)
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

          original_content = read_result[:content]

          # Archive ORIGINAL content (before context expansion)
          archive_result = Molecules::PromptArchiver.call(content: original_content)
          unless archive_result[:success]
            return {
              content: original_content,
              archive_path: nil,
              success: false,
              error: archive_result[:error]
            }
          end

          # Determine output content based on context flag
          output_content = if context
                             # ace-context handles entire file processing (including frontmatter)
                             context_content = Molecules::ContextLoader.call(read_result[:path])
                             if context_content.empty?
                               # Fallback: extract body ONLY if ace-context fails
                               warn "Warning: ace-context failed, extracting prompt body only"
                               extracted = Atoms::FrontmatterExtractor.extract(original_content)
                               extracted[:body]
                             else
                               # Use ace-context processed content (includes frontmatter handling)
                               context_content
                             end
                           else
                             # No context - just strip frontmatter for clean output
                             extracted = Atoms::FrontmatterExtractor.extract(original_content)
                             extracted[:body]
                           end

          # Return content and archive info
          {
            content: output_content,
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
