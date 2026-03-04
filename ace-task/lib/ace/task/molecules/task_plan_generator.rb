# frozen_string_literal: true

require "ace/core"
require_relative "path_utils"
require_relative "task_plan_prompt_builder"

module Ace
  module Task
    module Molecules
      # Generates implementation plans from task specs using ace-llm backend.
      class TaskPlanGenerator
        DEFAULT_TIMEOUT = 600

        # After generate(), contains { system_file:, prompt_file: } if file-based prompts were used
        attr_reader :prompt_paths

        def initialize(model:, timeout: DEFAULT_TIMEOUT, client: nil, cli_args: nil)
          @model = model
          @timeout = timeout
          @client = client
          @cli_args = cli_args
          @prompt_paths = nil
        end

        def generate(task:, context_files:, cache_dir: nil)
          if cache_dir
            generate_with_file_prompts(task, cache_dir)
          else
            generate_with_inline_prompt(task, context_files)
          end
        rescue LoadError => e
          raise Ace::Core::CLI::Error.new(
            "Plan generation backend unavailable: #{e.message}. " \
            "Ensure ace-llm is installed/configured, or provide --model."
          )
        rescue Ace::Core::CLI::Error
          raise
        rescue RuntimeError, IOError, Errno::ENOENT, Errno::ECONNREFUSED, Timeout::Error => e
          raise Ace::Core::CLI::Error.new(
            "Plan generation failed: #{e.message}. Retry with --refresh or choose a working --model."
          )
        end

        private

        def generate_with_file_prompts(task, cache_dir)
          builder = TaskPlanPromptBuilder.new(
            task: task,
            cache_dir: cache_dir
          )
          paths = builder.build
          @prompt_paths = paths

          response = llm_client.query(
            @model,
            File.read(paths[:prompt_file]),
            system: File.read(paths[:system_file]),
            timeout: @timeout,
            fallback: false,
            cli_args: @cli_args
          )

          extract_text(response)
        end

        def generate_with_inline_prompt(task, context_files)
          prompt = build_prompt(task, context_files)
          response = llm_client.query(
            @model,
            prompt,
            system: nil,
            timeout: @timeout,
            fallback: false,
            cli_args: @cli_args
          )

          extract_text(response)
        end

        def extract_text(response)
          text = response[:text].to_s.strip
          if text.empty?
            raise Ace::Core::CLI::Error.new(
              "Plan generation failed: backend returned empty output. Retry with --refresh or --model."
            )
          end

          text
        end

        def build_prompt(task, context_files)
          task_content = File.read(task.file_path)
          context_section = if context_files.empty?
            "No additional context files were captured for this task."
          else
            context_files.map { |path| "- #{relative_path(path)}" }.join("\n")
          end

          <<~PROMPT
            Create a concrete implementation plan for task #{task.id}.

            Requirements:
            - Plan against the behavioral spec structure.
            - Explicitly cover: Interface Contract, Error Handling, Edge Cases, Success Criteria.
            - Cover operating modes when relevant: dry-run, force/refresh, verbose, quiet.
            - If details are missing, include a "Behavioral Gaps" section (do not invent hidden assumptions).
            - Include concrete acceptance checks and validation commands.
            - Keep output as markdown only.

            Output format — anchored checklist:
            - Each step must have a stable ID (e.g., S01, S02).
            - Include `path:line` anchors for file locations where changes apply.
            - List dependencies between steps explicitly.
            - Include per-step verification commands.
            - End with a freshness summary listing input files and their expected state.

            Task spec path:
            #{relative_path(task.file_path)}

            Captured context files:
            #{context_section}

            Task spec content:
            #{task_content}
          PROMPT
        end

        def relative_path(path)
          Ace::Task::Molecules::PathUtils.relative_path(path)
        end

        def llm_client
          return @client if @client

          require "ace/llm"
          Ace::LLM::QueryInterface
        end
      end
    end
  end
end
