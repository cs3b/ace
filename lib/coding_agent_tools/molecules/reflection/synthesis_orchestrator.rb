# frozen_string_literal: true

require_relative "../../../models/result"
require_relative "../../../organisms/llm/query_executor"

module CodingAgentTools
  module Molecules
    module Reflection
      # Orchestrates the synthesis of reflection notes using LLM
      class SynthesisOrchestrator
        def initialize
          @query_executor = Organisms::LLM::QueryExecutor.new
        end

        def synthesize_reflections(reflections:, timestamp_info:, model:, output_path:, format:, system_prompt_path:, force:, debug:)
          start_time = Time.now

          # Check if output file exists and handle overwrite
          unless force
            if File.exist?(output_path)
              return Models::Result.failure("Output file already exists: #{output_path}. Use --force to overwrite.")
            end
          end

          # Load system prompt
          system_prompt = load_system_prompt(system_prompt_path)
          unless system_prompt
            return Models::Result.failure("Could not load system prompt from: #{system_prompt_path}")
          end

          # Prepare reflection content
          reflection_content = prepare_reflection_content(reflections, timestamp_info)

          # Execute LLM query
          query_result = @query_executor.execute_query(
            model: model,
            system_prompt: system_prompt,
            user_prompt: reflection_content,
            format: format,
            debug: debug
          )

          unless query_result.success?
            return Models::Result.failure("LLM query failed: #{query_result.error}")
          end

          # Save output
          begin
            File.write(output_path, query_result.response)
          rescue => e
            return Models::Result.failure("Could not write output file: #{e.message}")
          end

          end_time = Time.now
          execution_time = end_time - start_time

          # Prepare metrics
          metrics = {
            reflections_count: reflections.length,
            execution_time: execution_time.round(2),
            output_tokens: query_result.output_tokens,
            cost: query_result.cost
          }

          Models::Result.success(
            output_path: output_path,
            metrics: metrics,
            synthesis_result: query_result.response
          )
        end

        private

        def load_system_prompt(system_prompt_path)
          return nil unless system_prompt_path
          return nil unless File.exist?(system_prompt_path)
          
          begin
            File.read(system_prompt_path, encoding: "utf-8")
          rescue => e
            Rails.logger.warn("Could not read system prompt: #{e.message}") if defined?(Rails)
            nil
          end
        end

        def prepare_reflection_content(reflections, timestamp_info)
          content = []
          
          # Add synthesis context
          content << "# Reflection Notes for Synthesis"
          content << ""
          
          if timestamp_info.valid?
            content << "**Analysis Period**: #{timestamp_info.from_date} to #{timestamp_info.to_date}"
            content << "**Duration**: #{timestamp_info.days_covered} days"
            content << "**Total Reflections**: #{reflections.length}"
          else
            content << "**Total Reflections**: #{reflections.length}"
          end
          
          content << ""
          content << "---"
          content << ""

          # Add each reflection with proper headers
          reflections.each_with_index do |reflection_path, index|
            content << "## Reflection #{index + 1}: #{File.basename(reflection_path)}"
            content << ""
            content << "**Source**: `#{reflection_path}`"
            content << "**Modified**: #{File.mtime(reflection_path).strftime('%Y-%m-%d %H:%M:%S')}"
            content << ""
            
            begin
              reflection_content = File.read(reflection_path, encoding: "utf-8")
              content << reflection_content
            rescue => e
              content << "*Error reading reflection: #{e.message}*"
            end
            
            content << ""
            content << "---"
            content << ""
          end

          content.join("\n")
        end
      end
    end
  end
end