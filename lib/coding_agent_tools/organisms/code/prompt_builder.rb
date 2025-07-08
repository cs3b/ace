# frozen_string_literal: true

require_relative "../../molecules/code/prompt_combiner"
require_relative "../../atoms/code/file_content_reader"

module CodingAgentTools
  module Organisms
    module Code
      # Builds complete review prompts
      # This is an organism - it orchestrates molecules for prompt building
      class PromptBuilder
        def initialize
          @prompt_combiner = Molecules::Code::PromptCombiner.new
          @file_reader = Atoms::Code::FileContentReader.new
        end

        # Build review prompt from session components
        # @param session [Models::Code::ReviewSession] review session
        # @param target [Models::Code::ReviewTarget] review target
        # @param context [Models::Code::ReviewContext] review context
        # @param system_prompt_override [String] optional custom system prompt file path
        # @return [Models::Code::ReviewPrompt] complete prompt
        def build_review_prompt(session, target, context, system_prompt_override = nil)
          # Load target content from session files
          target_content = load_target_content(session, target)

          # Build prompt using combiner
          prompt = @prompt_combiner.build_prompt(
            session,
            target_content,
            context,
            session.focus,
            system_prompt_override
          )

          # Save prompt to session
          save_result = @prompt_combiner.save_prompt(prompt, session.directory_path)

          unless save_result[:success]
            raise "Failed to save prompt: #{save_result[:error]}"
          end

          prompt
        end

        # Select system prompt based on focus
        # @param focus [String] review focus
        # @param system_prompt_override [String] optional custom system prompt file path
        # @return [String] system prompt path
        def select_system_prompt(focus, system_prompt_override = nil)
          @prompt_combiner.select_system_prompt(focus, system_prompt_override)
        end

        # Build prompt for immediate use (without saving)
        # @param focus [String] review focus
        # @param target_content [String] target content
        # @param context [Models::Code::ReviewContext] context
        # @return [String] prompt content
        def build_immediate_prompt(focus, target_content, context)
          # Create temporary session for prompt building
          temp_session = Models::Code::ReviewSession.new(
            session_id: "temp-#{Time.now.to_i}",
            session_name: "temp",
            timestamp: Time.now.iso8601,
            directory_path: Dir.tmpdir,
            focus: focus,
            target: "immediate",
            context_mode: context.mode,
            metadata: {}
          )

          prompt = @prompt_combiner.build_prompt(
            temp_session,
            target_content,
            context,
            focus
          )

          prompt.combined_content
        end

        # Get prompt statistics
        # @param prompt [Models::Code::ReviewPrompt] prompt
        # @return [Hash] prompt statistics
        def get_prompt_stats(prompt)
          {
            size_bytes: prompt.content_size,
            word_count: prompt.word_count,
            multi_focus: prompt.multi_focus?,
            primary_focus: prompt.primary_focus,
            focus_count: prompt.focus_areas.size,
            has_frontmatter: !prompt.frontmatter.empty?,
            session_id: prompt.session_id
          }
        end

        private

        # Load target content from session files
        # @param session [Models::Code::ReviewSession] session
        # @param target [Models::Code::ReviewTarget] target
        # @return [String] target content
        def load_target_content(session, target)
          case target.content_type
          when "diff"
            content_file = File.join(session.directory_path, "input.diff")
          when "xml"
            content_file = File.join(session.directory_path, "input.xml")
          else
            raise "Unknown content type: #{target.content_type}"
          end

          result = @file_reader.read(content_file)

          unless result[:success]
            raise "Failed to read target content: #{result[:error]}"
          end

          result[:content]
        end
      end
    end
  end
end
