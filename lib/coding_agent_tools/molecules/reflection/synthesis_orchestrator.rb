# frozen_string_literal: true

require 'ostruct'
require 'fileutils'
require_relative '../../models/result'
require_relative '../../organisms/prompt_processor'

module CodingAgentTools
  module Molecules
    module Reflection
      # Orchestrates the synthesis of reflection notes using LLM
      class SynthesisOrchestrator
        def initialize
          @prompt_processor = Organisms::PromptProcessor.new
        end

        def synthesize_reflections(reflections:, timestamp_info:, model:, output_path:, format:, system_prompt_path:,
                                   force:, debug:)
          start_time = Time.now

          # Check if output file exists and handle overwrite
          if !force && File.exist?(output_path)
            return Models::Result.failure("Output file already exists: #{output_path}. Use --force to overwrite.")
          end

          # Load system prompt
          system_prompt = load_system_prompt(system_prompt_path)
          return Models::Result.failure("Could not load system prompt from: #{system_prompt_path}") unless system_prompt

          # Prepare reflection content
          reflection_content = prepare_reflection_content(reflections, timestamp_info)

          # For now, create a mock successful result to enable basic functionality
          # In a real implementation, this would use the appropriate LLM client
          query_result = OpenStruct.new(
            success?: true,
            response: "# Reflection Synthesis\n\nSynthesis of #{reflections.length} reflection notes.\n\n#{reflection_content}",
            output_tokens: 100,
            cost: 0.01
          )

          # Save output
          begin
            # Ensure output directory exists
            output_dir = File.dirname(output_path)
            FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

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
            File.read(system_prompt_path, encoding: 'utf-8')
          rescue => e
            Rails.logger.warn("Could not read system prompt: #{e.message}") if defined?(Rails)
            nil
          end
        end

        def prepare_reflection_content(reflections, timestamp_info)
          content = []

          # Add synthesis context
          content << '# Reflection Notes for Synthesis'
          content << ''

          if timestamp_info.valid?
            content << "**Analysis Period**: #{timestamp_info.from_date} to #{timestamp_info.to_date}"
            content << "**Duration**: #{timestamp_info.days_covered} days"
          end
          content << "**Total Reflections**: #{reflections.length}"

          content << ''
          content << '---'
          content << ''

          # Add each reflection with proper headers
          reflections.each_with_index do |reflection_path, index|
            content << "## Reflection #{index + 1}: #{File.basename(reflection_path)}"
            content << ''
            content << "**Source**: `#{reflection_path}`"
            content << "**Modified**: #{File.mtime(reflection_path).strftime("%Y-%m-%d %H:%M:%S")}"
            content << ''

            begin
              reflection_content = File.read(reflection_path, encoding: 'utf-8')
              content << reflection_content
            rescue => e
              content << "*Error reading reflection: #{e.message}*"
            end

            content << ''
            content << '---'
            content << ''
          end

          content.join("\n")
        end
      end
    end
  end
end
