# frozen_string_literal: true

require "fileutils"
require "ace/support/items"

module Ace
  module Idea
    module Molecules
      # Moves idea folders to different locations within the ideas root directory.
      # Delegates to SpecialFolderDetector for folder name normalization.
      class IdeaMover
        # @param root_dir [String] Root directory for ideas
        def initialize(root_dir)
          @root_dir = root_dir
        end

        # Move an idea folder to a target location
        # @param idea [Idea] Idea to move
        # @param to [String] Target folder name (short or full, e.g., "maybe", "_archive")
        # @return [String] New path of the idea directory
        def move(idea, to:)
          normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(to)
          candidate = File.expand_path(File.join(@root_dir, normalized))
          root_real = File.expand_path(@root_dir)
          unless candidate.start_with?(root_real + File::SEPARATOR) || candidate == root_real
            raise ArgumentError, "Path traversal detected in --to option"
          end
          target_parent = candidate
          FileUtils.mkdir_p(target_parent)

          folder_name = File.basename(idea.path)
          new_path = File.join(target_parent, folder_name)

          # Same-location no-op check
          return idea.path if File.expand_path(idea.path) == File.expand_path(new_path)

          atomic_move(idea.path, new_path)
        end

        # Move an idea to root (remove from special folder)
        # @param idea [Idea] Idea to move
        # @return [String] New path of the idea directory
        def move_to_root(idea)
          folder_name = File.basename(idea.path)
          new_path = File.join(@root_dir, folder_name)

          # Same-location no-op check
          return idea.path if File.expand_path(idea.path) == File.expand_path(new_path)

          atomic_move(idea.path, new_path)
        end

        private

        # Move src to dest, raising ArgumentError if dest already exists.
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
