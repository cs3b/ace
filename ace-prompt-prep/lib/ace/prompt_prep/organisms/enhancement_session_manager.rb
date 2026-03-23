# frozen_string_literal: true

module Ace
  module PromptPrep
    module Organisms
      # Orchestrates system prompt context loading for enhancement
      #
      # When the system prompt has a `context:` frontmatter section,
      # it's processed via ace-bundle (same as user prompts).
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

          # Process via ace-bundle
          process_with_context(system_prompt_uri, system_prompt_content)
        rescue => e
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

          # Process system prompt through ace-bundle
          # Loads presets from frontmatter and combines with instructions
          #
          # @param uri_or_path [String] Original URI or path
          # @param content [String] Raw system prompt content
          # @return [Hash] Result with processed content
          def process_with_context(uri_or_path, content)
            extracted = Atoms::FrontmatterExtractor.extract(content)
            frontmatter = extracted[:frontmatter] || {}
            instructions = extracted[:body] || content

            # Get presets from frontmatter
            presets = frontmatter.dig("context", "presets") || []

            if presets.empty?
              return {
                content: instructions,
                context_loaded: false,
                error: nil
              }
            end

            begin
              # Load each preset and combine
              context_parts = []

              presets.each do |preset|
                # Use ace-bundle API to load preset (Ruby API first, CLI fallback)
                preset_content = load_preset_via_api(preset)
                context_parts << preset_content if preset_content && !preset_content.empty?
              end

              if context_parts.empty?
                return {
                  content: instructions,
                  context_loaded: false,
                  error: "No preset content loaded"
                }
              end

              # Combine: context section + instructions section
              combined = build_combined_prompt(context_parts.join("\n\n"), instructions)

              {
                content: combined,
                context_loaded: true,
                error: nil
              }
            rescue => e
              warn "Warning: Context loading failed: #{e.message}"
              {
                content: instructions,
                context_loaded: false,
                error: e.message
              }
            end
          end

          # Load preset content via ace-bundle
          # Tries Ruby API first (faster, in-process), falls back to CLI
          #
          # @param preset [String] Preset name
          # @return [String, nil] Preset content or nil
          def load_preset_via_api(preset)
            # Try Ruby API first (faster, in-process, testable)

            require "ace/bundle"
            context_data = Ace::Bundle.load_preset(preset)
            content = context_data&.content
            return content if content && !content.strip.empty?

            warn "Warning: ace-bundle returned empty content for preset '#{preset}'" unless ENV["ACE_QUIET"]
            nil
          rescue LoadError
            # ace-bundle gem not available, try CLI fallback
            load_preset_via_cli(preset)
          rescue => e
            warn "Warning: ace-bundle API failed for '#{preset}': #{e.message}" unless ENV["ACE_QUIET"]
            # Try CLI as fallback
            load_preset_via_cli(preset)
          end

          # Load preset content via ace-bundle CLI (fallback)
          #
          # @param preset [String] Preset name
          # @return [String, nil] Preset content or nil
          def load_preset_via_cli(preset)
            require "open3"

            stdout, stderr, status = Open3.capture3("ace-bundle", preset, "--output", "stdio")

            if status.success? && !stdout.strip.empty?
              stdout
            else
              warn "Warning: ace-bundle CLI failed for preset '#{preset}': #{stderr}" unless ENV["ACE_QUIET"]
              nil
            end
          rescue Errno::ENOENT
            warn "Warning: ace-bundle CLI not found on PATH. Install ace-bundle or ensure it's in your PATH." unless ENV["ACE_QUIET"]
            nil
          rescue => e
            warn "Warning: ace-bundle CLI error: #{e.message}" unless ENV["ACE_QUIET"]
            nil
          end

          # Build combined prompt with clear sections
          #
          # @param context [String] Project context content
          # @param instructions [String] Enhancement instructions
          # @return [String] Combined prompt
          def build_combined_prompt(context, instructions)
            <<~PROMPT
              # Project Context (Reference)

              The following is project context to help you understand the codebase.
              Use this knowledge when enhancing prompts, but focus on the instructions below.

              #{context}

              ---

              # Enhancement Instructions

              #{instructions}
            PROMPT
          end

          # Resolve protocol URI to file path
          #
          # @param uri_or_path [String] URI or path
          # @return [String, nil] File path or nil
          def resolve_to_path(uri_or_path)
            return uri_or_path unless uri_or_path.include?("://")

            begin
              require "ace/support/nav/organisms/navigation_engine"

              engine = Ace::Support::Nav::Organisms::NavigationEngine.new
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
