# frozen_string_literal: true

require_relative "../molecules/context_loader"
require_relative "../molecules/idea_enhancer"
require_relative "../molecules/path_resolver"
require_relative "../molecules/llm_client"
require "fileutils"

module CodingAgentTools
  module Organisms
    # IdeaCapture orchestrates the process of capturing raw ideas and enhancing them
    # This is an organism - it combines multiple molecules to provide complete idea capture workflow
    class IdeaCapture
      # Result structure for clean API
      CaptureResult = Struct.new(:success, :output_path, :error_message, :debug_info) do
        def success?
          success
        end
      end

      # Maximum input size (1000 words ~ 7000 characters)
      DEFAULT_MAX_INPUT_SIZE = 7000
      
      # Big input threshold for --big-user-input-allowed flag
      BIG_INPUT_THRESHOLD = 1000 * 7  # ~1000 words

      # Initialize IdeaCapture
      # @param model [String] LLM model to use
      # @param debug [Boolean] Enable debug output
      # @param big_user_input_allowed [Boolean] Allow large inputs
      def initialize(model: "google:gemini-2.5-flash-lite", debug: false, big_user_input_allowed: false)
        @model = model
        @debug = debug
        @big_user_input_allowed = big_user_input_allowed
        @max_input_size = big_user_input_allowed ? Float::INFINITY : BIG_INPUT_THRESHOLD
        
        # Initialize molecules
        @context_loader = Molecules::ContextLoader.new
        @idea_enhancer = Molecules::IdeaEnhancer.new
        @path_resolver = Molecules::PathResolver.new
        @llm_client = Molecules::LLMClient.new(model: model, debug: debug)
      end

      # Capture and enhance an idea
      # @param idea_text [String] Raw idea text
      # @return [CaptureResult] Result with success status and output path
      def capture_idea(idea_text)
        debug_log("Starting idea capture process")
        
        # Validate input
        validation_result = validate_input(idea_text)
        return validation_result unless validation_result.success?

        # Generate paths using nav-path functionality
        paths_result = generate_paths(idea_text)
        return error_result("Path generation failed: #{paths_result[:error]}") unless paths_result[:success]

        debug_log("Generated paths: input=#{paths_result[:input_path]}, system=#{paths_result[:system_path]}, output=#{paths_result[:output_path]}")

        # Save raw idea to input file
        save_result = save_raw_idea(idea_text, paths_result[:input_path])
        return save_result unless save_result.success?

        # Load project context
        context_result = load_project_context
        debug_log("Context loading result: #{context_result[:success] ? 'success' : context_result[:error]}")

        # Generate system prompt
        system_prompt_result = generate_system_prompt(context_result, paths_result[:system_path])
        return system_prompt_result unless system_prompt_result.success?

        # Enhance idea using LLM
        enhancement_result = enhance_idea_with_llm(paths_result)
        
        if enhancement_result.success?
          debug_log("Idea enhancement completed successfully")
          CaptureResult.new(true, paths_result[:output_path], nil, @debug ? "Enhancement completed" : nil)
        else
          # Fallback: save raw idea with error note
          debug_log("Enhancement failed, saving raw idea as fallback")
          fallback_result = save_fallback_idea(idea_text, paths_result[:output_path], enhancement_result.error_message)
          fallback_result
        end
      rescue => e
        debug_details = @debug ? e.backtrace.join("\n") : nil
        error_result("Unexpected error during idea capture: #{e.message}", debug_details)
      end

      private

      def validate_input(idea_text)
        return error_result("Idea text cannot be nil") if idea_text.nil?
        
        cleaned_text = idea_text.strip
        return error_result("Idea text cannot be empty") if cleaned_text.empty?
        return error_result("Idea text must be at least 5 characters") if cleaned_text.length < 5

        # Check size limits
        word_count = cleaned_text.split.length
        char_count = cleaned_text.length

        if char_count > @max_input_size
          size_kb = (char_count / 1024.0).round(1)
          return error_result("Input too large: #{size_kb} KB, #{word_count} words. Use --big-user-input-allowed to proceed")
        end

        CaptureResult.new(true, nil, nil, nil)
      end

      def generate_paths(idea_text)
        @path_resolver.generate_capture_idea_paths(idea_text)
      end

      def save_raw_idea(idea_text, input_path)
        begin
          File.write(input_path, idea_text.strip)
          debug_log("Saved raw idea to: #{input_path}")
          CaptureResult.new(true, nil, nil, nil)
        rescue => e
          error_result("Failed to save raw idea: #{e.message}")
        end
      end

      def load_project_context
        @context_loader.load_docs_context
      end

      def generate_system_prompt(context_result, system_path)
        begin
          # Load system prompt template
          # Get project root by going up from dev-tools/lib/coding_agent_tools/organisms/
          project_root = File.expand_path("../../../../../", __FILE__)
          template_path = File.join(project_root, "dev-handbook/templates/idea-manager/system.prompt.md")
          
          unless File.exist?(template_path)
            return error_result("System prompt template not found: #{template_path}")
          end

          system_prompt = File.read(template_path)
          
          # Embed project context if available
          if context_result[:success] && context_result[:context]
            system_prompt += "\n\n## Project Context\n\n"
            system_prompt += context_result[:context]
          end

          # Embed idea template
          idea_template_path = File.join(project_root, "dev-handbook/templates/idea-manager/idea.template.md")
          if File.exist?(idea_template_path)
            idea_template = File.read(idea_template_path)
            system_prompt += "\n\n## Template Format\n\nUse this exact template format:\n\n```markdown\n"
            system_prompt += idea_template
            system_prompt += "\n```"
          end

          # Save system prompt
          File.write(system_path, system_prompt)
          debug_log("Generated system prompt: #{system_path}")
          
          CaptureResult.new(true, nil, nil, nil)
        rescue => e
          error_result("Failed to generate system prompt: #{e.message}")
        end
      end

      def enhance_idea_with_llm(paths_result)
        @llm_client.enhance_idea(
          input_path: paths_result[:input_path],
          system_path: paths_result[:system_path],
          output_path: paths_result[:output_path]
        )
      end

      def save_fallback_idea(idea_text, output_path, error_message)
        begin
          fallback_content = "# Raw Idea (Enhanced Version Failed)\n\n"
          fallback_content += "**Enhancement Error:** #{error_message}\n\n"
          fallback_content += "## Original Idea\n\n#{idea_text.strip}"
          
          File.write(output_path, fallback_content)
          debug_log("Saved fallback idea to: #{output_path}")
          
          CaptureResult.new(true, output_path, nil, "Saved raw idea due to enhancement failure")
        rescue => e
          error_result("Failed to save fallback idea: #{e.message}")
        end
      end

      def error_result(message, debug_details = nil)
        CaptureResult.new(false, nil, message, debug_details)
      end

      def debug_log(message)
        puts "Debug: #{message}" if @debug
      end
    end
  end
end