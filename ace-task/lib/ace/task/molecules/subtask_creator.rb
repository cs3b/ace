# frozen_string_literal: true

require "fileutils"
require_relative "../atoms/task_id_formatter"
require_relative "../atoms/task_frontmatter_defaults"
require_relative "task_loader"

module Ace
  module Task
    module Molecules
      # Creates subtasks within a parent task's folder.
      # Allocates subtask characters sequentially: 0-9 then a-z (max 36 subtasks).
      class SubtaskCreator
        # Maximum number of subtasks per parent (0-9 = 10, a-z = 26)
        MAX_SUBTASKS = 36

        # Ordered sequence of subtask characters
        SUBTASK_CHARS = (0..35).map { |i| i.to_s(36) }.freeze

        # @param config [Hash] Configuration hash
        def initialize(config: {})
          @config = config
        end

        # Create a subtask within a parent task's folder.
        #
        # @param parent_task [Models::Task] Parent task
        # @param title [String] Subtask title
        # @param status [String, nil] Initial status
        # @param priority [String, nil] Priority level
        # @param tags [Array<String>] Tags
        # @param time [Time] Creation time (default: now)
        # @return [Models::Task] Created subtask
        # @raise [RangeError] If parent already has 36 subtasks
        def create(
          parent_task,
          title,
          status: nil,
          priority: nil,
          tags: [],
          time: Time.now.utc,
          estimate: nil,
          remote_issue: nil
        )
          raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

          paths = destination_paths_for(parent_task, title)
          subtask_id = paths[:id]
          subtask_dir = paths[:dir]
          FileUtils.mkdir_p(subtask_dir)

          # Build frontmatter
          effective_status = status || @config.dig("task", "default_status") || "pending"
          frontmatter = Atoms::TaskFrontmatterDefaults.build(
            id: subtask_id,
            status: effective_status,
            priority: priority,
            tags: tags,
            created_at: time,
            parent: parent_task.id,
            estimate: estimate,
            remote_issue: remote_issue
          )

          # Write spec file
          spec_file = paths[:spec]
          content = build_spec_content(frontmatter: frontmatter, title: title)
          File.write(spec_file, content)

          # Load and return
          loader = TaskLoader.new
          loader.load(subtask_dir, id: subtask_id, load_subtasks: false)
        end

        # Non-mutating preview of the directory and spec file a subtask create
        # call would write: the next allocated subtask character and the
        # title-derived slugs, matching create exactly. Pre-write checks use it
        # to judge Git ignore rules against the real generated names.
        #
        # @param parent_task [Models::Task] Parent task
        # @param title [String] Subtask title
        # @return [Array<String>] Subtask directory and spec file path
        def destination_paths(parent_task, title)
          raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

          paths = destination_paths_for(parent_task, title)
          [paths[:dir], paths[:spec]]
        end

        private

        def destination_paths_for(parent_task, title)
          existing_chars = scan_existing_subtask_chars(parent_task.path, parent_task.id)
          next_char = allocate_next_char(existing_chars)
          subtask_id = "#{parent_task.id}.#{next_char}"
          folder_slug = generate_folder_slug(title)
          file_slug = generate_file_slug(title)
          subtask_dir = File.join(parent_task.path, "#{next_char}-#{folder_slug}")
          {id: subtask_id, dir: subtask_dir, spec: File.join(subtask_dir, "#{subtask_id}-#{file_slug}.s.md")}
        end

        # Scan parent directory for existing subtask folders and extract their chars.
        def scan_existing_subtask_chars(parent_dir, _parent_id)
          chars = []
          return chars unless Dir.exist?(parent_dir)

          Dir.entries(parent_dir).sort.each do |entry|
            next if entry.start_with?(".")

            full_path = File.join(parent_dir, entry)
            next unless File.directory?(full_path)

            # Short format: "0-slug" or "a-slug"
            if (short_match = entry.match(/^([a-z0-9])-/))
              chars << short_match[1]
            end
          end

          chars
        end

        # Allocate the next available subtask character.
        # @raise [RangeError] If all 36 chars are used
        def allocate_next_char(existing_chars)
          SUBTASK_CHARS.each do |char|
            return char unless existing_chars.include?(char)
          end

          raise RangeError, "Maximum number of subtasks (#{MAX_SUBTASKS}) exceeded"
        end

        def generate_folder_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title)
          words = sanitized.split("-")
          result = words.take(5).join("-")
          result.empty? ? "subtask" : result
        end

        def generate_file_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title)
          words = sanitized.split("-")
          result = words.take(7).join("-")
          result.empty? ? "subtask" : result
        end

        def build_spec_content(frontmatter:, title:)
          serialized = Ace::Support::Items::Atoms::FrontmatterSerializer.serialize(frontmatter)
          "#{serialized}\n\n# #{title}\n"
        end
      end
    end
  end
end
