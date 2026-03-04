# frozen_string_literal: true

require "yaml"
require "fileutils"
require "time"
require "ace/support/items"
require "ace/b36ts"
require_relative "path_utils"

module Ace
  module Task
    module Molecules
      # Manages task plan cache lookup, freshness checks, and artifact writes.
      class TaskPlanCache
        LATEST_POINTER = "latest-plan.md"

        def initialize(task_id:, cache_root: ".cache/ace-task")
          @task_id = task_id
          @cache_root = cache_root
        end

        def cache_dir
          File.join(Dir.pwd, @cache_root, @task_id)
        end

        def prompts_dir
          File.join(cache_dir, "prompts")
        end

        def latest_pointer_path
          File.join(cache_dir, LATEST_POINTER)
        end

        def resolve_latest_plan
          from_pointer = resolve_from_pointer
          return from_pointer if from_pointer

          plan_files.max_by { |path| File.mtime(path) }
        end

        def fresh?(plan_path, task_file:)
          return false unless File.file?(plan_path)

          metadata = read_metadata(plan_path)
          return false unless metadata

          fresh_task_file?(metadata, task_file) && fresh_context_files?(metadata)
        end

        def write_plan(content:, model:, task_file:, context_files:, prompt_files: nil)
          FileUtils.mkdir_p(cache_dir)

          plan_path = build_unique_plan_path

          metadata = {
            "task_id" => @task_id,
            "generated_at" => Time.now.utc.iso8601,
            "model" => model,
            "task_file" => {
              "path" => relative_path(task_file),
              "mtime" => File.mtime(task_file).to_i
            },
            "context_files" => context_files.map { |path|
              {
                "path" => relative_path(path),
                "mtime" => File.mtime(path).to_i
              }
            }
          }

          if prompt_files
            metadata["prompt_files"] = prompt_files.transform_values { |path|
              relative_path(path)
            }
          end

          body = +"#{YAML.dump(metadata)}---\n\n"
          body << content.to_s.rstrip
          body << "\n"
          File.write(plan_path, body)

          File.write(latest_pointer_path, "#{File.basename(plan_path)}\n")
          File.write(
            File.join(cache_dir, "latest-plan.meta.yml"),
            YAML.dump(metadata)
          )
          plan_path
        end

        private

        def resolve_from_pointer
          pointer = latest_pointer_path
          return nil unless File.exist?(pointer)

          if File.symlink?(pointer)
            target = File.expand_path(File.readlink(pointer), cache_dir)
            return target if valid_plan_file?(target)
            return nil
          end

          target_ref = File.read(pointer).strip
          return nil if target_ref.empty?

          target = if target_ref.start_with?("/")
            target_ref
          else
            File.expand_path(target_ref, cache_dir)
          end
          return target if valid_plan_file?(target)

          nil
        rescue Errno::ENOENT
          nil
        end

        def plan_files
          return [] unless Dir.exist?(cache_dir)

          Dir.glob(File.join(cache_dir, "*-plan.md"))
             .select { |path| valid_plan_file?(path) }
        end

        def valid_plan_file?(path)
          File.file?(path) && path.end_with?("-plan.md")
        end

        def read_metadata(plan_path)
          content = File.read(plan_path)
          frontmatter, = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          frontmatter.is_a?(Hash) ? frontmatter : nil
        rescue StandardError
          nil
        end

        def fresh_task_file?(metadata, task_file)
          task_meta = metadata["task_file"]
          return false unless task_meta.is_a?(Hash)

          tracked_path = resolve_tracked_path(task_meta["path"])
          tracked_mtime = task_meta["mtime"].to_i
          return false unless tracked_path == File.expand_path(task_file)
          return false unless File.exist?(tracked_path)

          File.mtime(tracked_path).to_i == tracked_mtime
        end

        def fresh_context_files?(metadata)
          context_files = Array(metadata["context_files"])
          return true if context_files.empty?

          context_files.all? do |ctx|
            next false unless ctx.is_a?(Hash)

            tracked_path = resolve_tracked_path(ctx["path"])
            tracked_mtime = ctx["mtime"].to_i
            File.exist?(tracked_path) && File.mtime(tracked_path).to_i == tracked_mtime
          end
        end

        def resolve_tracked_path(path)
          return "" if path.nil? || path.to_s.empty?
          return path if path.start_with?("/")

          File.expand_path(path, Dir.pwd)
        end

        def relative_path(path)
          Ace::Task::Molecules::PathUtils.relative_path(path)
        end

        MAX_UNIQUE_ATTEMPTS = 10

        def build_unique_plan_path
          base_id = Ace::B36ts.encode(Time.now.utc, format: :"2sec")
          MAX_UNIQUE_ATTEMPTS.times do |attempt|
            suffix = attempt.zero? ? "" : "-#{attempt}"
            path = File.join(cache_dir, "#{base_id}#{suffix}-plan.md")
            return path unless File.exist?(path)
          end

          raise Ace::Core::CLI::Error.new(
            "Failed to generate unique plan path after #{MAX_UNIQUE_ATTEMPTS} attempts. " \
            "Clear .cache/ace-task/#{@task_id}/ and retry."
          )
        end
      end
    end
  end
end
