# frozen_string_literal: true

require "fileutils"
require "ace/support/items"

module Ace
  module Retro
    module Molecules
      # Moves retro folders to different locations within the retros root directory.
      # Delegates to SpecialFolderDetector for folder name normalization.
      # Handles Errno::EXDEV for cross-filesystem moves.
      class RetroMover
        # @param root_dir [String] Root directory for retros
        def initialize(root_dir)
          @root_dir = root_dir
        end

        # Move a retro folder to a target location
        # @param retro [Retro] Retro to move
        # @param to [String] Target folder name (short or full, e.g., "archive", "_archive")
        # @param date [Time, nil] Date used to compute archive partition (default: Time.now)
        # @return [String] New path of the retro directory
        def move(retro, to:, date: nil)
          normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(to)

          target_parent = if normalized == "_archive"
            partition = Ace::Support::Items::Atoms::DatePartitionPath.compute(date || Time.now)
            File.expand_path(File.join(@root_dir, normalized, partition))
          else
            File.expand_path(File.join(@root_dir, normalized))
          end

          root_real = File.expand_path(@root_dir)
          unless target_parent.start_with?(root_real + File::SEPARATOR)
            raise ArgumentError, "Path traversal detected in --to option"
          end
          FileUtils.mkdir_p(target_parent)

          folder_name = File.basename(retro.path)
          new_path = File.join(target_parent, folder_name)

          # Same-location no-op check
          return retro.path if File.expand_path(retro.path) == File.expand_path(new_path)

          atomic_move(retro.path, new_path)
        end

        # Move a retro to root (remove from special folder)
        # @param retro [Retro] Retro to move
        # @return [String] New path of the retro directory
        def move_to_root(retro)
          folder_name = File.basename(retro.path)
          new_path = File.join(@root_dir, folder_name)

          # Same-location no-op check
          return retro.path if File.expand_path(retro.path) == File.expand_path(new_path)

          atomic_move(retro.path, new_path)
        end

        private

        # Move src to dest, raising ArgumentError if dest already exists.
        # Handles Errno::EXDEV for cross-filesystem moves by falling back to copy+remove.
        def atomic_move(src, dest)
          raise ArgumentError, "Destination already exists: #{dest}" if File.exist?(dest)

          begin
            File.rename(src, dest)
          rescue Errno::EXDEV
            # Cross-device: fall back to copy+remove
            FileUtils.cp_r(src, dest)
            FileUtils.rm_rf(src)
          end
          dest
        end
      end
    end
  end
end
