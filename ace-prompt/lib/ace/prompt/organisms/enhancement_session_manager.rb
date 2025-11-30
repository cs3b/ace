# frozen_string_literal: true

module Ace
  module Prompt
    module Organisms
      # Orchestrates system prompt context loading for enhancement
      #
      # When the system prompt has a `context:` frontmatter section,
      # it's processed via ace-context (same as user prompts).
      class EnhancementSessionManager
        # Prepare enhancement session by loading and processing system prompt
        #
        # @param system_prompt_uri [String] System prompt URI or file path
        # @return [Hash] Result with :content, :context_loaded, :error keys
        def self.prepare_session(system_prompt_uri)
          # Load raw system prompt content
          system_prompt_content = load_system_prompt(system_prompt_uri)

          unless system_prompt_content
            return {
              content: nil,
              context_loaded: false,
              error: "Failed to load system prompt"
            }
          end

          # Check for frontmatter with context
          extracted = Atoms::FrontmatterExtractor.extract(system_prompt_content)

          unless extracted[:has_frontmatter]
            return {
              content: system_prompt_content,
              context_loaded: false,
              error: nil
            }
          end

          frontmatter = extracted[:frontmatter]

          # If no context key in frontmatter, return body only
          unless frontmatter&.key?("context")
            return {
              content: extracted[:body],
              context_loaded: false,
              error: nil
            }
          end

          # Process via ace-context
          process_with_context(system_prompt_uri, system_prompt_content)
        rescue StandardError => e
          warn "Warning: EnhancementSessionManager error: #{e.message}"
          {
            content: system_prompt_content,
            context_loaded: false,
            error: e.message
          }
        end

        class << self
          private

          # Load system prompt content from URI or path
          # Delegates to PromptEnhancer's existing method
          #
          # @param uri_or_path [String] System prompt URI or path
          # @return [String, nil] Content or nil
          def load_system_prompt(uri_or_path)
            PromptEnhancer.load_system_prompt(uri_or_path)
          end

          # Process system prompt through ace-context
          #
          # @param uri_or_path [String] Original URI or path
          # @param content [String] Raw system prompt content
          # @return [Hash] Result with processed content
          def process_with_context(uri_or_path, content)
            path = resolve_to_path(uri_or_path)

            unless path && File.exist?(path)
              warn "Warning: Cannot resolve system prompt to file path for context loading"
              return {
                content: strip_frontmatter(content),
                context_loaded: false,
                error: "Cannot resolve to file path"
              }
            end

            begin
              require "ace/context"

              # Use ace-context to process the system prompt file
              # format: markdown (we want clean output, not XML-wrapped)
              # embed_source: false (we don't need the prompt file embedded)
              context_data = Ace::Context.load_file(
                path,
                format: "markdown",
                embed_source: false
              )

              if context_data&.content.is_a?(String) && !context_data.content.empty?
                {
                  content: context_data.content,
                  context_loaded: true,
                  error: nil
                }
              else
                {
                  content: strip_frontmatter(content),
                  context_loaded: false,
                  error: "Empty context result"
                }
              end
            rescue LoadError => e
              warn "Warning: ace-context not available: #{e.message}"
              {
                content: strip_frontmatter(content),
                context_loaded: false,
                error: "ace-context not available"
              }
            rescue StandardError => e
              warn "Warning: Context loading failed: #{e.message}"
              {
                content: strip_frontmatter(content),
                context_loaded: false,
                error: e.message
              }
            end
          end

          # Resolve protocol URI to file path
          #
          # @param uri_or_path [String] URI or path
          # @return [String, nil] File path or nil
          def resolve_to_path(uri_or_path)
            return uri_or_path unless uri_or_path.include?("://")

            begin
              require "ace/nav/organisms/navigation_engine"

              engine = Ace::Nav::Organisms::NavigationEngine.new
              result = engine.resolve(uri_or_path)

              # engine.resolve returns a String path directly (not a hash)
              result if result.is_a?(String)
            rescue LoadError, StandardError => e
              warn "Warning: Protocol resolution failed: #{e.message}" if ENV["DEBUG"]
              nil
            end
          end

          # Strip frontmatter from content (fallback when context loading fails)
          #
          # @param content [String] Content with potential frontmatter
          # @return [String] Content without frontmatter
          def strip_frontmatter(content)
            extracted = Atoms::FrontmatterExtractor.extract(content)
            extracted[:body] || content
          end
        end
      end
    end
  end
end
