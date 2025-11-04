# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Task metadata writer molecule
        #
        # Directly updates task files with worktree metadata using regex patterns
        # similar to ace-taskflow's internal approach. This provides an alternative
        # to using the ace-taskflow update command when more control is needed.
        #
        # @example Add worktree metadata to a task file
        #   writer = TaskMetadataWriter.new
        #   metadata = WorktreeMetadata.new(branch: "081-fix", path: ".ace-wt/task.081")
        #   success = writer.add_metadata_to_task_file("/path/to/task.081.md", metadata)
        #
        # @example Remove worktree metadata from a task file
        #   success = writer.remove_metadata_from_task_file("/path/to/task.081.md")
        class TaskMetadataWriter
          # Backup file suffix
          BACKUP_SUFFIX = ".backup"

          # Initialize a new TaskMetadataWriter
          #
          # @param create_backups [Boolean] Whether to create backup files
          def initialize(create_backups: true)
            @create_backups = create_backups
          end

          # Add worktree metadata to a task file
          #
          # @param task_file_path [String] Path to the task file
          # @param worktree_metadata [WorktreeMetadata] Worktree metadata to add
          # @return [Boolean] true if metadata was added successfully
          #
          # @example
          #   writer = TaskMetadataWriter.new
          #   metadata = WorktreeMetadata.new(branch: "081-fix", path: ".ace-wt/task.081")
          #   success = writer.add_metadata_to_task_file("task.081.md", metadata)
          def add_metadata_to_task_file(task_file_path, worktree_metadata)
            return false unless File.exist?(task_file_path)
            return false unless worktree_metadata.is_a?(Models::WorktreeMetadata)

            begin
              # Read the current file content
              content = File.read(task_file_path)

              # Create backup if requested
              create_backup(task_file_path) if @create_backups

              # Check if worktree metadata already exists
              if worktree_metadata_present?(content)
                # Update existing metadata
                updated_content = update_existing_worktree_metadata(content, worktree_metadata)
              else
                # Add new metadata section
                updated_content = add_new_worktree_metadata(content, worktree_metadata)
              end

              # Write the updated content
              File.write(task_file_path, updated_content)
              true
            rescue StandardError => e
              warn "Error updating task file #{task_file_path}: #{e.message}"
              false
            end
          end

          # Remove worktree metadata from a task file
          #
          # @param task_file_path [String] Path to the task file
          # @return [Boolean] true if metadata was removed successfully
          #
          # @example
          #   success = writer.remove_metadata_from_task_file("task.081.md")
          def remove_metadata_from_task_file(task_file_path)
            return false unless File.exist?(task_file_path)

            begin
              content = File.read(task_file_path)

              # Create backup if requested
              create_backup(task_file_path) if @create_backups

              # Remove worktree metadata section
              updated_content = remove_worktree_metadata_section(content)

              # Write the updated content
              File.write(task_file_path, updated_content)
              true
            rescue StandardError => e
              warn "Error updating task file #{task_file_path}: #{e.message}"
              false
            end
          end

          # Update task status in a task file
          #
          # @param task_file_path [String] Path to the task file
          # @param new_status [String] New status value
          # @return [Boolean] true if status was updated successfully
          #
          # @example
          #   success = writer.update_task_status("task.081.md", "in-progress")
          def update_task_status(task_file_path, new_status)
            return false unless File.exist?(task_file_path)
            return false unless new_status

            begin
              content = File.read(task_file_path)

              # Create backup if requested
              create_backup(task_file_path) if @create_backups

              # Update status using regex pattern (similar to ace-taskflow)
              updated_content = content.sub(/^status:\s*.+$/m, "status: #{new_status}")

              # Check if the status was actually updated
              if updated_content == content
                warn "Status field not found in task file #{task_file_path}"
                return false
              end

              # Write the updated content
              File.write(task_file_path, updated_content)
              true
            rescue StandardError => e
              warn "Error updating task file #{task_file_path}: #{e.message}"
              false
            end
          end

          # Get worktree metadata from a task file
          #
          # @param task_file_path [String] Path to the task file
          # @return [WorktreeMetadata, nil] Worktree metadata or nil if not found
          #
          # @example
          #   metadata = writer.get_worktree_metadata("task.081.md")
          def get_worktree_metadata(task_file_path)
            return nil unless File.exist?(task_file_path)

            begin
              content = File.read(task_file_path)

              # Parse YAML frontmatter
              yaml_match = content.match(/\A---\s*\n(.*?)\n---/m)
              return nil unless yaml_match

              yaml_content = yaml_match[1]
              require "yaml"
              frontmatter = YAML.safe_load(yaml_content)

              Models::WorktreeMetadata.from_task_data(frontmatter)
            rescue StandardError
              nil
            end
          end

          # Check if worktree metadata is present in a task file
          #
          # @param task_file_path [String] Path to the task file
          # @return [Boolean] true if worktree metadata is present
          #
          # @example
          #   has_metadata = writer.worktree_metadata_present?("task.081.md")
          def worktree_metadata_present?(task_file_path)
            return false unless File.exist?(task_file_path)

            content = File.read(task_file_path)
            worktree_metadata_present?(content)
          end

          # Clean up backup files
          #
          # @param task_file_path [String] Path to the task file
          # @return [Boolean] true if backup was removed
          def cleanup_backup(task_file_path)
            backup_path = task_file_path + BACKUP_SUFFIX
            return false unless File.exist?(backup_path)

            File.delete(backup_path)
            true
          rescue StandardError
            false
          end

          private

          # Check if worktree metadata is present in content
          #
          # @param content [String] File content
          # @return [Boolean] true if worktree metadata is present
          def worktree_metadata_present?(content)
            content.include?("worktree:")
          end

          # Add new worktree metadata section
          #
          # @param content [String] Current file content
          # @param worktree_metadata [WorktreeMetadata] Metadata to add
          # @return [String] Updated content
          def add_new_worktree_metadata(content, worktree_metadata)
            # Find the end of the frontmatter
            frontmatter_end = content.index("---\n", 3)
            return content unless frontmatter_end

            # Build worktree metadata YAML
            metadata_yaml = worktree_metadata.to_h.map { |k, v| "  #{k}: #{v.inspect}" }.join("\n")

            # Insert the metadata before the end of frontmatter
            insertion_point = frontmatter_end
            updated_content = content.dup
            updated_content.insert(insertion_point, "worktree:\n#{metadata_yaml}\n")

            updated_content
          end

          # Update existing worktree metadata
          #
          # @param content [String] Current file content
          # @param worktree_metadata [WorktreeMetadata] New metadata
          # @return [String] Updated content
          def update_existing_worktree_metadata(content, worktree_metadata)
            # Parse the YAML and update it
            yaml_match = content.match(/\A---\s*\n(.*?)\n---/m)
            return content unless yaml_match

            yaml_content = yaml_match[1]
            require "yaml"
            frontmatter = YAML.safe_load(yaml_content)

            # Update worktree metadata
            frontmatter["worktree"] = worktree_metadata.to_h

            # Rebuild the content with updated frontmatter
            updated_yaml = frontmatter.to_yaml.gsub(/^---\n/, "")
            content.sub(/\A---\s*\n.*?\n---/m, "---\n#{updated_yaml}---")
          end

          # Remove worktree metadata section
          #
          # @param content [String] Current file content
          # @return [String] Updated content
          def remove_worktree_metadata_section(content)
            # Parse YAML frontmatter
            yaml_match = content.match(/\A---\s*\n(.*?)\n---/m)
            return content unless yaml_match

            yaml_content = yaml_match[1]
            require "yaml"
            frontmatter = YAML.safe_load(yaml_content)

            # Remove worktree metadata
            frontmatter.delete("worktree")

            # Rebuild the content without worktree metadata
            updated_yaml = frontmatter.to_yaml.gsub(/^---\n/, "")
            content.sub(/\A---\s*\n.*?\n---/m, "---\n#{updated_yaml}---")
          end

          # Create a backup of the file
          #
          # @param file_path [String] Path to the file
          def create_backup(file_path)
            backup_path = file_path + BACKUP_SUFFIX
            FileUtils.cp(file_path, backup_path)
          rescue StandardError => e
            warn "Warning: Failed to create backup file: #{e.message}"
          end
        end
      end
    end
  end
end