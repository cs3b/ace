# frozen_string_literal: true

require_relative "task_scanner"
require_relative "../atoms/task_validation_rules"

module Ace
  module Task
    module Molecules
      # Task-aware traversal excludes evidence folders and the parent's own status.
      class TaskFamilyCompletion
        def initialize(root_dir)
          @scanner = TaskScanner.new(root_dir)
        end

        def descendants_terminal?(path, id:)
          @scanner.scan_subtasks(path, parent_id: id).all? do |child|
            content = File.read(child.file_path)
            frontmatter, = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
            Atoms::TaskValidationRules.terminal_status?(frontmatter["status"].to_s.downcase) &&
              descendants_terminal?(child.dir_path, id: child.id)
          end
        end

        def complete?(path, id:)
          @scanner.scan_subtasks(path, parent_id: id).any? && descendants_terminal?(path, id: id)
        end
      end
    end
  end
end
