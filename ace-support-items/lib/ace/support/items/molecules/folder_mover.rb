# frozen_string_literal: true

require "fileutils"
require_relative "../atoms/special_folder_detector"
require_relative "../atoms/date_partition_path"

module Ace
  module Support
    module Items
      module Molecules
        # Generic folder mover for item directories.
        # Handles special folder name normalization, archive date partitioning,
        # and cross-filesystem atomic moves.
        class FolderMover
          # @param root_dir [String] Root directory for items
          def initialize(root_dir)
            @root_dir = root_dir
          end

          # Move an item folder to a target location.
          #
          # @param item [#path] Item with a path attribute (directory to move)
          # @param to [String] Target folder name (short or full, e.g., "maybe", "_archive")
          # @param date [Time, nil] Date used to compute archive partition (default: Time.now)
          # @return [String] New path of the item directory
          def move(item, to:, date: nil)
            normalized = Atoms::SpecialFolderDetector.normalize(to)

            target_parent = if normalized == "_archive"
              partition = Atoms::DatePartitionPath.compute(date || Time.now)
              File.expand_path(File.join(@root_dir, normalized, partition))
            else
              File.expand_path(File.join(@root_dir, normalized))
            end

            validate_path_traversal!(target_parent)
            FileUtils.mkdir_p(target_parent)

            folder_name = File.basename(item.path)
            new_path = File.join(target_parent, folder_name)

            # Same-location no-op check
            return item.path if File.expand_path(item.path) == File.expand_path(new_path)

            atomic_move(item.path, new_path)
          end

          # Move an item back to root (remove from special folder).
          #
          # @param item [#path] Item with a path attribute
          # @return [String] New path of the item directory
          def move_to_root(item)
            folder_name = File.basename(item.path)
            new_path = File.join(@root_dir, folder_name)

            # Same-location no-op check
            return item.path if File.expand_path(item.path) == File.expand_path(new_path)

            atomic_move(item.path, new_path)
          end

          private

          def validate_path_traversal!(target_parent)
            root_real = File.expand_path(@root_dir)
            unless target_parent.start_with?(root_real + File::SEPARATOR)
              raise ArgumentError, "Path traversal detected in target folder"
            end
          end

          # Move src to dest atomically, handling cross-device moves.
          def atomic_move(src, dest)
            raise ArgumentError, "Destination already exists: #{dest}" if File.exist?(dest)

            begin
              File.rename(src, dest)
            rescue Errno::EXDEV
              FileUtils.cp_r(src, dest)
              FileUtils.rm_rf(src)
            end
            dest
          end
        end
      end
    end
  end
end
