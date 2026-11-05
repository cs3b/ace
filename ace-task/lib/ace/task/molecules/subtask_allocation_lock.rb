# frozen_string_literal: true

module Ace
  module Task
    module Molecules
      # The parent directory inode is shared across processes and path aliases.
      # Lock it across allocation and publication without adding task-store files.
      module SubtaskAllocationLock
        def self.synchronize(parent_path)
          File.open(parent_path, File::RDONLY) do |directory|
            directory.flock(File::LOCK_EX)
            held = directory.stat
            current = File.stat(parent_path)
            unless current.directory? && [held.dev, held.ino] == [current.dev, current.ino]
              raise ArgumentError, "Parent task moved while waiting for subtask allocation; retry"
            end
            yield
          end
        end
      end
    end
  end
end
