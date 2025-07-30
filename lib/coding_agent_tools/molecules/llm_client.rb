# frozen_string_literal: true

require_relative "client_factory"
require_relative "provider_model_parser"
require_relative "file_io_handler"

module CodingAgentTools
  module Molecules
    # LLMClient handles LLM integration with retry logic and fallback handling
    # This is a molecule - it provides behavior-oriented LLM interaction functionality
    class LLMClient
      # Result structure for clean API
      LLMResult = Struct.new(:success, :output, :error_message, :retry_count) do
        def success?
          success
        end
      end

      # Retry configuration
      MAX_RETRIES = 3
      RETRY_DELAYS = [1, 3, 9].freeze  # Exponential backoff

      def initialize(model: "gflash", debug: false)
        @model = model
        @debug = debug
        @file_handler = FileIoHandler.new
        @parser = ProviderModelParser.new
        
        # Parse the model to get provider and model name
        parse_result = @parser.parse(@model)
        unless parse_result.valid?
          raise ArgumentError, "Invalid model specification '#{@model}': #{parse_result.error}"
        end
        
        @provider = parse_result.provider
        @model_name = parse_result.model
      end

      # Enhance idea using LLM with retry logic
      # @param input_path [String] Path to input file with raw idea
      # @param system_path [String] Path to system prompt file
      # @param output_path [String] Path to write enhanced output  
      # @return [LLMResult] Result with success status
      def enhance_idea(input_path:, system_path:, output_path:)
        validate_paths(input_path, system_path, output_path)

        retry_count = 0
        last_error = nil

        (MAX_RETRIES + 1).times do |attempt|
          debug_log("LLM enhancement attempt #{attempt + 1}/#{MAX_RETRIES + 1}")
          
          begin
            result = execute_llm_query(input_path, system_path, output_path)
            return LLMResult.new(true, output_path, nil, retry_count) if result[:success]
            
            last_error = result[:error]
            debug_log("Attempt #{attempt + 1} failed: #{last_error}")
            
          rescue => e
            last_error = e.message
            debug_log("Attempt #{attempt + 1} raised exception: #{last_error}")
          end

          # Don't sleep after the last attempt
          if attempt < MAX_RETRIES
            retry_count += 1
            sleep_time = RETRY_DELAYS[attempt] || RETRY_DELAYS.last
            debug_log("Retrying in #{sleep_time} seconds...")
            sleep(sleep_time)
          end
        end

        # All retries failed
        LLMResult.new(false, nil, "LLM enhancement failed after #{MAX_RETRIES + 1} attempts. Last error: #{last_error}", retry_count)
      end

      private

      def validate_paths(input_path, system_path, output_path)
        raise ArgumentError, "Input file not found: #{input_path}" unless File.exist?(input_path)
        raise ArgumentError, "System prompt file not found: #{system_path}" unless File.exist?(system_path)
        raise ArgumentError, "Output directory not found: #{File.dirname(output_path)}" unless Dir.exist?(File.dirname(output_path))
      end

      def execute_llm_query(input_path, system_path, output_path)
        debug_log("Using direct library call for LLM query with model: #{@model}")
        
        begin
          # Read input files
          input_text = @file_handler.read_file(input_path)
          system_text = @file_handler.read_file(system_path)
          
          # Create LLM client using ClientFactory
          client = ClientFactory.build(@provider, {model: @model_name})
          
          debug_log("Generating content with #{@provider} client")
          
          # Generate content directly
          response = client.generate_text(input_text, system_instruction: system_text)
          
          if response && !response.strip.empty?
            # Write output to file
            @file_handler.write_file(output_path, response)
            debug_log("LLM enhancement successful, output written to: #{output_path}")
            {success: true}
          else
            {success: false, error: "LLM produced empty output"}
          end
          
        rescue => e
          error_msg = "LLM query failed: #{e.message}"
          debug_log("Error: #{error_msg}")
          {success: false, error: error_msg}
        end
      end


      def debug_log(message)
        puts "Debug: #{message}" if @debug
      end
    end
  end
end