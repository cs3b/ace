# frozen_string_literal: true

require "open3"
require "json"
require "tempfile"
require_relative "../prompts/compact_diff_prompt"
require_relative "../atoms/diff_filterer"

module Ace
  module Docs
    module Molecules
      # Analyzes diffs using LLM for intelligent compaction
      class DiffAnalyzer
        def initialize(config = {})
          @config = Ace::Docs.config.merge(config)
          @llm_command = @config["ace_llm_path"] || "ace-llm-query"
        end

        # Analyze a diff using LLM compaction
        # @param diff [String] The diff to analyze
        # @param documents [Array] Documents being analyzed
        # @param options [Hash] Analysis options
        # @return [Hash] Analysis results
        def analyze(diff, documents = [], options = {})
          return empty_result if diff.nil? || diff.empty?

          # Check diff size and warn if too large
          if Atoms::DiffFilterer.exceeds_limit?(diff, @config["max_diff_lines_warning"])
            warn_about_large_diff(diff)
          end

          # Build prompt for LLM
          prompt = Prompts::CompactDiffPrompt.build(diff, documents)

          # Call LLM via subprocess
          response = call_llm(prompt, options)

          # Parse and return result
          {
            success: true,
            analysis: response,
            documents_analyzed: documents.size,
            timestamp: Time.now.utc.iso8601
          }
        rescue StandardError => e
          {
            success: false,
            error: e.message,
            analysis: nil,
            documents_analyzed: documents.size,
            timestamp: Time.now.utc.iso8601
          }
        end

        private

        def call_llm(prompt, options = {})
          # Build command arguments
          cmd_args = build_llm_command(options)

          # Use tempfile for prompt to avoid shell escaping issues
          Tempfile.create(["ace-docs-prompt", ".txt"]) do |prompt_file|
            prompt_file.write(prompt)
            prompt_file.flush

            # Execute LLM command
            stdout, stderr, status = Open3.capture3(*cmd_args, stdin_data: prompt)

            unless status.success?
              handle_llm_error(stderr, status)
            end

            stdout.strip
          end
        end

        def build_llm_command(options)
          cmd = [@llm_command]

          # Add model if specified
          if @config["llm_model"]
            cmd += ["--model", @config["llm_model"]]
          end

          # Add temperature
          temp = options[:temperature] || @config["llm_temperature"] || 0.3
          cmd += ["--temperature", temp.to_s]

          # Add system prompt indicator if supported
          cmd += ["--system"] if options[:system_prompt]

          cmd
        end

        def handle_llm_error(stderr, status)
          error_msg = stderr.strip

          if error_msg.include?("command not found") || error_msg.include?("No such file")
            raise "ace-llm-query not found. Please install the ace-llm gem: gem install ace-llm"
          elsif error_msg.include?("rate limit")
            raise "LLM API rate limit reached. Please try again in a few minutes."
          elsif error_msg.include?("timeout")
            raise "LLM request timed out. The diff may be too large."
          elsif error_msg.include?("API key")
            raise "LLM API key not configured. Please set up ace-llm-query with valid credentials."
          else
            raise "LLM analysis failed (exit code #{status.exitstatus}): #{error_msg}"
          end
        end

        def warn_about_large_diff(diff)
          lines = Atoms::DiffFilterer.estimate_size(diff)
          warn "WARNING: Diff contains #{lines} lines, which may exceed LLM context limits."
          warn "Consider using --exclude-renames, --exclude-moves, or --since options to reduce size."
        end

        def empty_result
          {
            success: true,
            analysis: "No changes to analyze",
            documents_analyzed: 0,
            timestamp: Time.now.utc.iso8601
          }
        end

        def warn(message)
          $stderr.puts message
        end
      end
    end
  end
end