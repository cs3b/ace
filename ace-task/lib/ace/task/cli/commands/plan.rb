# frozen_string_literal: true

require "dry/cli"
require_relative "../../molecules/task_plan_cache"
require_relative "../../molecules/task_plan_generator"
require_relative "../../molecules/task_config_loader"
require_relative "../../organisms/task_manager"

module Ace
  module Task
    module CLI
      module Commands
        # dry-cli Command class for ace-task plan
        class Plan < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Resolve or generate a task implementation plan

            Reuses fresh cached plans when available, otherwise regenerates.
          DESC

          example [
            "q7w                          # Reuse fresh plan or generate new",
            "q7w --refresh                # Force regeneration",
            "q7w --content                # Print full plan content",
            "q7w --model gemini:flash-latest  # Override planning model"
          ]

          argument :ref, required: true, desc: "Task reference (full ID, short ref, or suffix)"

          option :refresh, type: :boolean, desc: "Force plan regeneration"
          option :content, type: :boolean, desc: "Print full plan content instead of path"
          option :model, type: :string, desc: "Provider:model override for plan generation"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          class << self
            attr_accessor :generator_class
          end

          def call(ref:, **options)
            task = resolve_task(ref)
            cache = Molecules::TaskPlanCache.new(task_id: task.id)

            plan_path = cache.resolve_latest_plan
            refresh = options[:refresh]

            unless refresh
              if plan_path && cache.fresh?(plan_path, task_file: task.file_path)
                output_plan(plan_path, options)
                return
              end
            end

            context_files = capture_context_files(task)
            model = options[:model] || default_model
            generator = plan_generator(model)
            content = generator.generate(
              task: task,
              context_files: context_files,
              cache_dir: cache.cache_dir
            )
            plan_path = cache.write_plan(
              content: content,
              model: model,
              task_file: task.file_path,
              context_files: context_files,
              prompt_files: generator.prompt_paths
            )

            output_plan(plan_path, options)
          end

          private

          def resolve_task(ref)
            manager = Organisms::TaskManager.new
            task = manager.show(ref)
            return task if task

            raise Ace::Core::CLI::Error.new("Task '#{ref}' not found. Run `ace-task list` to discover valid refs.")
          end

          def capture_context_files(task)
            files = Array(task.metadata.dig("bundle", "files"))
            expanded = files.map { |path| File.expand_path(path, Dir.pwd) }.uniq
            resolved = expanded.select { |path| File.file?(path) }

            missing = expanded - resolved
            missing.each { |path| $stderr.puts "Warning: context file not found: #{path}" } if missing.any?

            resolved
          end

          def output_plan(plan_path, options)
            if options[:content]
              puts File.read(plan_path)
            else
              puts plan_path
            end
          end

          def plan_generator(model)
            klass = self.class.generator_class || Molecules::TaskPlanGenerator
            klass.new(model: model)
          end

          def default_model
            config = Molecules::TaskConfigLoader.load
            config.dig("task", "plan", "model") || "gemini:flash-latest"
          end
        end
      end
    end
  end
end
