# frozen_string_literal: true

require "ace/git"

module Ace
  module Task
    module Molecules
      # Detects whether a task path is ignored by Git.
      #
      # ace-task is a universal task tool: it does not know which folders a lab
      # or a role reserves. When behavior has to differ for a path that is not
      # committed, the decision comes from Git's own ignore rules for the actual
      # path — never from a folder-name list. The same query covers a task
      # directory or its spec file, a path that does not exist yet (a destination
      # computed before a move), any working directory, and a custom task root:
      # Git resolves the repository from the path itself.
      class GitIgnoredPath
        # @param path [String] Path to check (file or directory, may not exist)
        # @return [Boolean] true when Git ignores the path (a commit would skip it)
        def self.ignored?(path)
          absolute = File.expand_path(path.to_s)
          working_dir = File.directory?(absolute) ? absolute : File.dirname(absolute)
          working_dir = File.dirname(working_dir) until Dir.exist?(working_dir) ||
            File.dirname(working_dir) == working_dir
          return false unless Dir.exist?(working_dir)

          result = Ace::Git::Atoms::CommandExecutor.execute(
            "git", "-C", working_dir, "check-ignore", "-q", "--", absolute
          )
          result[:success] == true
        rescue StandardError
          false
        end

        # A task is uncommittable when its directory or its spec file is ignored:
        # ignore rules may target the folder, individual children, or spec names.
        #
        # @param task [Models::Task]
        # @return [Boolean]
        def self.ignored_task?(task)
          ignored?(task.path) || ignored?(task.file_path)
        end

        # A task family is uncommittable when its directory or any spec file
        # inside it is ignored (auto-archive and doctor move whole families).
        #
        # @param dir_path [String]
        # @return [Boolean]
        def self.ignored_family?(dir_path)
          ignored?(dir_path) ||
            Dir.glob(File.join(dir_path.to_s, "**", "*.s.md")).any? { |spec| ignored?(spec) }
        end

        # Relocating into an ignored destination would expose committed-looking
        # content to normal staging, so both the destination directory and the
        # destination paths of the moving specs must be checked before a move.
        #
        # @param source_dir [String] Current task/family directory
        # @param destination_dir [String] Directory the move would create
        # @return [Boolean]
        def self.ignored_after_relocation?(source_dir, destination_dir)
          return true if ignored?(destination_dir)

          source_root = File.expand_path(source_dir.to_s)
          Dir.glob(File.join(source_root, "**", "*.s.md")).any? do |spec|
            relative = spec.delete_prefix(source_root + File::SEPARATOR)
            ignored?(File.join(destination_dir.to_s, relative))
          end
        end
      end
    end
  end
end
