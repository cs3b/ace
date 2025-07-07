# frozen_string_literal: true

require_relative "session_manager"
require_relative "content_extractor"
require_relative "context_loader"
require_relative "prompt_builder"
require "fileutils"

module CodingAgentTools
  module Organisms
    module Code
      # Main orchestrator for code review workflow
      # This is an organism - it coordinates all other organisms for complete review workflow
      class ReviewManager
        attr_reader :session_manager, :content_extractor, :context_loader, :prompt_builder

        def initialize
          @session_manager = SessionManager.new
          @content_extractor = ContentExtractor.new
          @context_loader = ContextLoader.new
          @prompt_builder = PromptBuilder.new
        end

        # Create a complete review session
        # @param focus [String] review focus
        # @param target [String] review target
        # @param context [String] context mode
        # @param base_path [String] base path for sessions
        # @param system_prompt_override [String] optional custom system prompt file path
        # @return [Hash] {session: ReviewSession, success: Boolean, error: String}
        def create_review_session(focus, target, context = "auto", base_path = nil, system_prompt_override = nil)
          begin
            # Create session
            session = @session_manager.create_session(
              focus: focus,
              target: target,
              context_mode: context,
              base_path: base_path
            )
            
            # Extract and save content
            target_model = @content_extractor.extract_and_save(target, session.directory_path)
            
            if target_model.type == "error"
              raise "Failed to extract target content: #{target_model.size_info[:error]}"
            end
            
            # Load and save context
            context_model = @context_loader.load_context(context, session)
            @context_loader.save_context(context_model, session.directory_path)
            
            # Build and save prompt
            prompt = @prompt_builder.build_review_prompt(session, target_model, context_model, system_prompt_override)
            
            # Write session summary
            write_session_summary(session, target_model, context_model, prompt)
            
            {
              session: session,
              target: target_model,
              context: context_model,
              prompt: prompt,
              success: true,
              error: nil
            }
          rescue => e
            {
              session: nil,
              success: false,
              error: e.message
            }
          end
        end

        # Execute review using LLM
        # @param session [Models::Code::ReviewSession] review session
        # @return [Hash] {reports: Array, success: Boolean, error: String}
        def execute_review(session)
          # This method would integrate with existing LLM clients
          # For now, return placeholder
          {
            reports: [],
            success: false,
            error: "LLM integration not yet implemented"
          }
        end

        # Finalize session after review
        # @param session [Models::Code::ReviewSession] review session
        # @param reports [Array<Hash>] review reports
        # @return [Hash] {success: Boolean, error: String}
        def finalize_session(session, reports = [])
          begin
            # Update session index
            update_session_index(session, reports)
            
            # Write execution summary
            write_execution_summary(session, reports)
            
            { success: true, error: nil }
          rescue => e
            { success: false, error: e.message }
          end
        end

        # Prepare review components without creating session
        # @param focus [String] review focus
        # @param target [String] review target
        # @param context [String] context mode
        # @param system_prompt_override [String] optional custom system prompt file path
        # @return [Hash] preparation results
        def prepare_review(focus, target, context = "auto", system_prompt_override = nil)
          {
            target_info: analyze_target(target),
            context_info: @context_loader.check_availability,
            system_prompt: @prompt_builder.select_system_prompt(focus, system_prompt_override),
            focus_areas: focus.split.flat_map { |f| CodingAgentTools::Models::Code::ReviewPrompt.get_focus_descriptions(f) }
          }
        end

        private

        # Analyze target without extracting
        # @param target [String] target specification
        # @return [Hash] target analysis
        def analyze_target(target)
          if @content_extractor.instance_variable_get(:@diff_extractor).git_diff_target?(target)
            { type: "git_diff", format: "diff" }
          elsif File.exist?(target) && !File.directory?(target)
            { type: "single_file", format: "xml", path: target }
          else
            { type: "file_pattern", format: "xml", pattern: target }
          end
        end

        # Write session summary
        # @param session [Models::Code::ReviewSession] session
        # @param target [Models::Code::ReviewTarget] target
        # @param context [Models::Code::ReviewContext] context
        # @param prompt [Models::Code::ReviewPrompt] prompt
        def write_session_summary(session, target, context, prompt)
          summary_path = File.join(session.directory_path, "session-summary.md")
          
          summary = <<~SUMMARY
            # Code Review Session Summary
            
            ## Session Information
            - **ID**: #{session.session_id}
            - **Name**: #{session.session_name}
            - **Created**: #{session.timestamp}
            - **Directory**: #{session.directory_path}
            
            ## Review Configuration
            - **Focus**: #{session.focus}
            - **Target**: #{session.target}
            - **Context Mode**: #{session.context_mode_with_default}
            
            ## Target Analysis
            - **Type**: #{target.type}
            - **Content Format**: #{target.content_type}
            - **Files**: #{target.file_count}
            - **Lines**: #{target.line_count}
            
            ## Context Summary
            #{@context_loader.get_context_summary(context)}
            
            ## Prompt Statistics
            - **Size**: #{prompt.word_count} words
            - **Focus Areas**: #{prompt.focus_areas.size}
            - **System Prompt**: #{prompt.system_prompt_path}
            
            ## Files Generated
            - `session.meta` - Session metadata
            - `input.#{target.content_type}` - Target content
            - `input.meta` - Target metadata
            - `prompt.md` - Combined review prompt
            - `context.yaml` - Context metadata
            
            ## Next Steps
            Execute the review using:
            ```
            code-review --session #{session.session_id}
            ```
          SUMMARY
          
          File.write(summary_path, summary)
        end

        # Update session index
        # @param session [Models::Code::ReviewSession] session
        # @param reports [Array<Hash>] review reports
        def update_session_index(session, reports)
          index_path = File.join(session.directory_path, "README.md")
          
          # Read existing content
          existing = File.exist?(index_path) ? File.read(index_path) : ""
          
          # Add reports section
          reports_section = <<~REPORTS
            
            ## Review Reports
            
          REPORTS
          
          reports.each do |report|
            reports_section += "- [`#{report[:name]}`](./#{report[:file]}) - #{report[:model]}\n"
          end
          
          # Update content
          if existing.include?("## Review Reports")
            # Replace existing section
            updated = existing.sub(/## Review Reports.*?(?=##|\z)/m, reports_section)
          else
            # Append new section
            updated = existing + "\n" + reports_section
          end
          
          File.write(index_path, updated)
        end

        # Write execution summary
        # @param session [Models::Code::ReviewSession] session
        # @param reports [Array<Hash>] review reports
        def write_execution_summary(session, reports)
          summary_path = File.join(session.directory_path, "execution.summary")
          
          summary = <<~SUMMARY
            Session: #{session.session_name}
            Timestamp: #{Time.now.iso8601}
            Target: #{session.target}
            Focus: #{session.focus}
            
            Execution Results:
          SUMMARY
          
          reports.each do |report|
            summary += "- #{report[:model]}: #{report[:status]}\n"
          end
          
          summary += <<~SUMMARY
            
            Files Generated:
            #{Dir.glob(File.join(session.directory_path, "*")).map { |f| File.basename(f) }.join("\n")}
          SUMMARY
          
          File.write(summary_path, summary)
        end
      end
    end
  end
end