# frozen_string_literal: true

require "fileutils"
require "time"
require_relative "../atoms/task_id_formatter"
require_relative "../atoms/task_frontmatter_defaults"
require_relative "task_loader"

module Ace
  module Task
    module Molecules
      # Creates new tasks with B36TS-based type-marked IDs.
      # Generates folder structure and spec file with full frontmatter.
      # Optionally uses LLM for slug generation with deterministic fallback.
      class TaskCreator
        # @param root_dir [String] Root directory for tasks
        # @param config [Hash] Configuration hash
        def initialize(root_dir:, config: {})
          @root_dir = root_dir
          @config = config
        end

        # Create a new task
        # @param title [String] Task title
        # @param status [String] Initial status (default: from config or "pending")
        # @param priority [String, nil] Priority level
        # @param tags [Array<String>] Tags
        # @param dependencies [Array<String>] Dependency task IDs
        # @param time [Time] Creation time (default: now)
        # @param use_llm_slug [Boolean] Whether to attempt LLM slug generation
        # @return [Models::Task] Created task
        def create(title, status: nil, priority: nil, tags: [], dependencies: [], time: Time.now.utc, use_llm_slug: false)
          raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

          # Generate task ID
          item_id = Atoms::TaskIdFormatter.generate(time)
          formatted_id = item_id.formatted_id

          # Generate slugs
          slugs = if use_llm_slug
            generate_llm_slugs(title) || generate_slugs(title)
          else
            generate_slugs(title)
          end
          folder_slug = slugs[:folder]
          file_slug = slugs[:file]

          # Create folder with folder_slug
          folder_name = Atoms::TaskIdFormatter.folder_name(formatted_id, folder_slug)
          task_dir = File.join(@root_dir, folder_name)
          FileUtils.mkdir_p(task_dir)

          # Build frontmatter with all fields
          effective_status = status || @config.dig("task", "default_status") || "pending"
          frontmatter = Atoms::TaskFrontmatterDefaults.build(
            id: formatted_id,
            status: effective_status,
            priority: priority,
            tags: tags,
            dependencies: dependencies,
            created_at: time
          )

          # Write spec file with file_slug
          spec_filename = Atoms::TaskIdFormatter.spec_filename(formatted_id, file_slug)
          spec_file = File.join(task_dir, spec_filename)
          content = build_spec_content(frontmatter: frontmatter, title: title)
          File.write(spec_file, content)

          # Load and return the created task
          loader = TaskLoader.new
          loader.load(task_dir, id: formatted_id)
        end

        private

        def generate_folder_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title)
          words = sanitized.split("-")
          result = words.take(5).join("-")
          result.empty? ? "task" : result
        end

        def generate_file_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title)
          words = sanitized.split("-")
          result = words.take(7).join("-")
          result.empty? ? "task" : result
        end

        def generate_slugs(title)
          { folder: generate_folder_slug(title), file: generate_file_slug(title) }
        end

        def generate_llm_slugs(title)
          generator = Ace::Support::Items::Molecules::LlmSlugGenerator.new
          result = generator.generate_task_slugs(title)
          return nil unless result[:success]

          folder_slug = result[:folder_slug] || generate_folder_slug(title)
          file_slug = result[:file_slug] || generate_file_slug(title)
          { folder: folder_slug, file: file_slug }
        rescue StandardError
          nil
        end

        def build_spec_content(frontmatter:, title:)
          serialized = Ace::Support::Items::Atoms::FrontmatterSerializer.serialize(frontmatter)
          "#{serialized}\n\n# #{title}\n"
        end
      end
    end
  end
end
