# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Composes final prompt from modular components
      class PromptComposer
        attr_reader :resolver

        def initialize(resolver: nil)
          @resolver = resolver || NavPromptResolver.new
        end

        # Compose a full prompt from composition configuration
        # @param composition [Hash] prompt composition with base, format, focus, guidelines
        # @param config_dir [String] directory for relative path resolution
        # @return [String] composed prompt
        def compose(composition, config_dir: nil)
          return "" unless composition

          sections = []

          # Add base prompt (required)
          if composition["base"]
            base_content = resolver.resolve(composition["base"], config_dir: config_dir)
            sections << base_content if base_content
          end

          # Add format section
          if composition["format"]
            format_content = resolver.resolve(composition["format"], config_dir: config_dir)
            sections << wrap_section("Output Format", format_content) if format_content
          end

          # Add focus modules (can be multiple)
          if composition["focus"] && !composition["focus"].empty?
            focus_contents = composition["focus"].map do |focus_ref|
              resolver.resolve(focus_ref, config_dir: config_dir)
            end.compact

            unless focus_contents.empty?
              combined_focus = focus_contents.join("\n\n---\n\n")
              sections << wrap_section("Review Focus", combined_focus)
            end
          end

          # Add guidelines
          if composition["guidelines"] && !composition["guidelines"].empty?
            guideline_contents = composition["guidelines"].map do |guideline_ref|
              resolver.resolve(guideline_ref, config_dir: config_dir)
            end.compact

            unless guideline_contents.empty?
              combined_guidelines = guideline_contents.join("\n\n")
              sections << wrap_section("Guidelines", combined_guidelines)
            end
          end

          sections.join("\n\n")
        end

        # Build a complete review prompt with context and subject
        def build_review_prompt(composition, context, subject, config_dir: nil)
          prompt_parts = []

          # Add composed system prompt
          system_prompt = compose(composition, config_dir: config_dir)
          prompt_parts << system_prompt if system_prompt && !system_prompt.empty?

          # Add context section
          if context && !context.empty?
            prompt_parts << wrap_section("Project Context", context)
          end

          # Add subject section
          if subject && !subject.empty?
            prompt_parts << wrap_section("Code to Review", subject)
          end

          # Add review request
          prompt_parts << generate_review_request(composition)

          prompt_parts.join("\n\n")
        end

        private

        def wrap_section(title, content)
          return "" unless content && !content.strip.empty?

          <<~SECTION
            ## #{title}

            #{content}
          SECTION
        end

        def generate_review_request(composition)
          focus_areas = if composition["focus"] && !composition["focus"].empty?
                          "\n\nPay special attention to the focus areas specified above."
                        else
                          ""
                        end

          <<~REQUEST
            ## Review Request

            Please review the provided code according to the guidelines and format specified above.#{focus_areas}

            Provide actionable feedback with specific suggestions for improvement. Reference line numbers or file locations where applicable.
          REQUEST
        end
      end
    end
  end
end