# frozen_string_literal: true

require_relative '../../atoms/code/file_content_reader'
require_relative '../../atoms/yaml_reader'
require_relative '../../models/code/review_prompt'
require 'yaml'
require 'time'
require 'stringio'

module CodingAgentTools
  module Molecules
    module Code
      # Combines all elements into final prompt
      # This is a molecule - it composes atoms to build complete prompts
      class PromptCombiner
        def initialize
          @file_reader = Atoms::Code::FileContentReader.new
          @yaml_reader = Atoms::YamlReader.new
        end

        # Build complete prompt from components
        # @param session [Models::Code::ReviewSession] review session
        # @param target_content [String] extracted target content
        # @param context [Models::Code::ReviewContext] loaded context
        # @param focus [String] review focus
        # @param system_prompt_override [String] optional custom system prompt file path
        # @return [Models::Code::ReviewPrompt] complete prompt
        def build_prompt(session, target_content, context, focus, system_prompt_override = nil)
          # Select system prompt path
          system_prompt_path = select_system_prompt(focus, system_prompt_override)

          # Get focus area descriptions
          focus_areas = get_focus_areas(focus)

          # Build combined content
          combined_content = build_combined_content(
            session: session,
            target_content: target_content,
            context: context,
            focus_areas: focus_areas
          )

          # Create prompt model
          Models::Code::ReviewPrompt.new(
            session_id: session.session_id,
            focus_areas: focus_areas,
            system_prompt_path: system_prompt_path,
            combined_content: combined_content,
            metadata: {
              generated: Time.now.iso8601,
              target: session.target,
              focus: focus,
              context: context.mode
            }
          )
        end

        # Save prompt to file
        # @param prompt [Models::Code::ReviewPrompt] prompt to save
        # @param session_dir [String] session directory path
        # @return [Hash] {prompt_file: String, success: Boolean, error: String}
        def save_prompt(prompt, session_dir)
          prompt_file = File.join(session_dir, 'prompt.md')

          begin
            File.write(prompt_file, prompt.combined_content)
            {
              prompt_file: prompt_file,
              success: true,
              error: nil
            }
          rescue StandardError => e
            {
              prompt_file: nil,
              success: false,
              error: "Failed to save prompt: #{e.message}"
            }
          end
        end

        # Select system prompt based on focus
        # @param focus [String] review focus
        # @param system_prompt_override [String] optional custom system prompt file path
        # @return [String] system prompt path
        def select_system_prompt(focus, system_prompt_override = nil)
          # Use override if provided
          return system_prompt_override if system_prompt_override && !system_prompt_override.empty?

          # Handle multi-focus by using primary focus
          primary_focus = focus.split.first

          case primary_focus
          when 'code'
            'dev-handbook/templates/review-code/system.prompt.md'
          when 'tests'
            'dev-handbook/templates/review-test/system.prompt.md'
          when 'docs'
            'dev-handbook/templates/review-docs/system.prompt.md'
          else
            # Default to code review template
            'dev-handbook/templates/review-code/system.prompt.md'
          end
        end

        private

        # Get focus area descriptions
        # @param focus [String] review focus
        # @return [Array<String>] focus area descriptions
        def get_focus_areas(focus)
          areas = []

          focus.split.each do |focus_type|
            areas.concat(CodingAgentTools::Models::Code::ReviewPrompt.get_focus_descriptions(focus_type))
          end

          areas
        end

        # Build combined content
        # @param session [Models::Code::ReviewSession] review session
        # @param target_content [String] target content
        # @param context [Models::Code::ReviewContext] context
        # @param focus_areas [Array<String>] focus areas
        # @return [String] combined content
        def build_combined_content(session:, target_content:, context:, focus_areas:)
          # Determine content type
          content_type = target_content.start_with?('<?xml') ? 'file' : 'diff'

          # Build YAML frontmatter
          frontmatter = {
            'generated' => Time.now.iso8601,
            'target' => session.target,
            'focus' => session.focus,
            'context' => context.mode,
            'type' => 'review-prompt'
          }

          content = StringIO.new
          content.puts '---'
          content.puts frontmatter.to_yaml.lines[1..].join
          content.puts '---'
          content.puts
          content.puts '<review-prompt>'

          # Add project context
          if context.loaded?
            content.puts "\n  <project-context>"
            context.documents.each do |doc|
              content.puts "    <document type=\"#{doc[:type]}\">"
              content.puts '      <![CDATA['
              content.puts doc[:content]
              content.puts '      ]]>'
              content.puts '    </document>'
            end
            content.puts '  </project-context>'
          end

          # Add review target
          content.puts "\n  <review-target type=\"#{content_type}\">"
          content.puts '    <![CDATA['
          content.puts target_content
          content.puts '    ]]>'
          content.puts '  </review-target>'

          # Add focus areas
          content.puts "\n  <focus-areas type=\"#{session.focus}\">"
          focus_areas.each do |area|
            content.puts "    <area>#{area}</area>"
          end
          content.puts '  </focus-areas>'

          content.puts '</review-prompt>'

          content.string
        end
      end
    end
  end
end
