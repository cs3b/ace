# frozen_string_literal: true

module Ace
  module Task
    module Molecules
      # Classifies where a task lives relative to the task root.
      #
      # The private `_overseer` folder is a self-contained, untracked scope:
      # management tasks and their archive stay inside it. Project tasks use
      # the tracked task tree. Archive relocation therefore takes its root
      # from the task's own scope, so an automatic or explicit archive never
      # moves a private family into the tracked `.ace-tasks/_archive/` tree.
      class TaskScope
        # Private management scope under the task root.
        PRIVATE_FOLDER = "_overseer"

        # Terminal bucket for archived tasks.
        ARCHIVE_FOLDER = "_archive"

        # @param path [String] Task directory or spec file path
        # @param root_dir [String] Task root directory
        # @return [Boolean] true when the path belongs to the private scope
        def self.private?(path, root_dir:)
          within?(path, private_root(root_dir))
        end

        # @param path [String] Task directory or spec file path
        # @param root_dir [String] Task root directory
        # @return [Boolean] true when the path is in an archive bucket
        #   (project `_archive` or the private `_overseer/_archive`)
        def self.archived?(path, root_dir:)
          within?(path, File.join(root_dir.to_s, ARCHIVE_FOLDER)) ||
            within?(path, File.join(private_root(root_dir), ARCHIVE_FOLDER))
        end

        # FolderMover root for an archive relocation: private families archive
        # inside the private scope, project tasks in the project archive.
        #
        # @param path [String] Current task directory path
        # @param root_dir [String] Task root directory
        # @return [String] Root whose `_archive/<partition>/` receives the task
        def self.archive_root(path, root_dir:)
          private?(path, root_dir: root_dir) ? private_root(root_dir) : root_dir
        end

        # @param root_dir [String] Task root directory
        # @return [String] Absolute private scope directory
        def self.private_root(root_dir)
          File.join(root_dir.to_s, PRIVATE_FOLDER)
        end

        def self.within?(path, base)
          expanded = File.expand_path(path.to_s)
          resolved = File.expand_path(base.to_s)
          expanded == resolved || expanded.start_with?(resolved + File::SEPARATOR)
        end
        private_class_method :within?
      end
    end
  end
end
