# frozen_string_literal: true

require "fileutils"
require "open3"
require "ace/b36ts"

module Ace
  module Task
    module Molecules
      # Assembles and persists prompt files for task plan generation.
      # System prompt = project context + task/plan workflow (composed via ace-bundle).
      # User prompt = ace-bundle <task.s.md> (task spec + bundle: frontmatter context).
      # Config files saved alongside output for debugging/introspection.
      # Files stored in .cache/ace-task/<task-id>/prompts/.
      class TaskPlanPromptBuilder
        def initialize(task:, cache_dir:)
          @task = task
          @cache_dir = cache_dir
        end

        # Returns { system_file: path, prompt_file: path }
        def build
          FileUtils.mkdir_p(prompts_dir)
          timestamp = Ace::B36ts.encode(Time.now.utc, format: :"2sec")

          {
            system_file: build_system_prompt(timestamp),
            prompt_file: build_user_prompt(timestamp)
          }
        end

        private

        def prompts_dir
          File.join(@cache_dir, "prompts")
        end

        def build_system_prompt(timestamp)
          config_path = File.join(prompts_dir, "#{timestamp}-system.config.md")
          output_path = File.join(prompts_dir, "#{timestamp}-system.md")
          write_system_config(config_path)
          run_ace_bundle(config_path, output_path)
          output_path
        end

        def build_user_prompt(timestamp)
          config_path = File.join(prompts_dir, "#{timestamp}-user.config.md")
          output_path = File.join(prompts_dir, "#{timestamp}-user.md")
          FileUtils.cp(@task.file_path, config_path)
          run_ace_bundle(@task.file_path, output_path)
          output_path
        end

        def write_system_config(path)
          File.write(path, <<~CONFIG)
            ---
            bundle:
              params:
                format: markdown-xml
              base: tmpl://agent/plan-mode
              sections:
                workflow:
                  title: Planning Workflow
                  files:
                    - wfi://task/plan
                project_context:
                  title: Project Context
                  presets:
                    - project
                repeat_instruction:
                  title: Plan Mode Reminder
                  files:
                    - tmpl://agent/plan-mode
            ---
          CONFIG
        end

        def run_ace_bundle(input, output_path)
          _stdout, status = Open3.capture2(
            "ace-bundle", input, "--format", "markdown-xml", "--output", output_path
          )
          unless status.success?
            raise Ace::Core::CLI::Error.new("ace-bundle failed for: #{input}")
          end
        rescue Errno::ENOENT
          raise Ace::Core::CLI::Error.new("ace-bundle not found (required for prompt building)")
        end
      end
    end
  end
end
