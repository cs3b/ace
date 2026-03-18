# frozen_string_literal: true

require "yaml"
require "fileutils"
require "ace/b36ts"

module Ace
  module Assign
    module Molecules
      # Manages assignment YAML file operations.
      #
      # Handles creation, loading, and updating of assignment.yaml files.
      # Uses ace-b36ts for assignment ID generation.
      class AssignmentManager
        # @param cache_base [String] Base cache directory
        def initialize(cache_base: nil)
          @cache_base = cache_base || Ace::Assign.cache_dir
        end

        # Create a new assignment
        #
        # @param name [String] Assignment name
        # @param description [String, nil] Assignment description
        # @param source_config [String] Path to source config file
        # @param parent [String, nil] Parent assignment ID for hierarchy linking
        # @return [Models::Assignment] Created assignment
        def create(name:, description: nil, source_config:, parent: nil)
          # Ensure cache base directory exists before generate_assignment_id
          FileUtils.mkdir_p(@cache_base)

          assignment_id = generate_assignment_id
          cache_dir = File.join(@cache_base, assignment_id)

          # Create directories
          FileUtils.mkdir_p(cache_dir)
          FileUtils.mkdir_p(File.join(cache_dir, "steps"))
          FileUtils.mkdir_p(File.join(cache_dir, "reports"))

          now = Time.now.utc

          assignment = Models::Assignment.new(
            id: assignment_id,
            name: name,
            description: description,
            created_at: now,
            updated_at: now,
            source_config: source_config,
            cache_dir: cache_dir,
            parent: parent
          )

          # Write assignment.yaml
          write_assignment_file(assignment)

          # Update .latest symlink for O(1) active assignment lookup
          update_latest_symlink(assignment_id)

          assignment
        end

        # Load an existing assignment by ID
        #
        # @param assignment_id [String] Assignment ID
        # @return [Models::Assignment, nil] Loaded assignment or nil
        def load(assignment_id)
          cache_dir = File.join(@cache_base, assignment_id)
          assignment_file = File.join(cache_dir, "assignment.yaml")

          return nil unless File.exist?(assignment_file)

          data = YAML.safe_load_file(assignment_file, permitted_classes: [Time, Date])
          Models::Assignment.from_h(data, cache_dir: cache_dir)
        end

        # Find the most recent active assignment
        #
        # Uses resolution order:
        # 1. .current symlink (explicit user selection)
        # 2. .latest symlink (auto, most recent)
        # 3. Scan all assignments (fallback)
        #
        # @return [Models::Assignment, nil] Most recent assignment or nil
        def find_active
          return nil unless File.directory?(@cache_base)

          # Priority 1: use .current symlink if it exists (explicit selection)
          current_symlink = File.join(@cache_base, ".current")
          if File.symlink?(current_symlink)
            assignment_id = File.basename(File.readlink(current_symlink))
            assignment = load(assignment_id)
            return assignment if assignment
          end

          # Priority 2: use .latest symlink if it exists
          latest_symlink = File.join(@cache_base, ".latest")
          if File.symlink?(latest_symlink)
            assignment_id = File.basename(File.readlink(latest_symlink))
            assignment = load(assignment_id)
            return assignment if assignment
          end

          # Fallback: find all assignment directories
          assignments = Dir.glob(File.join(@cache_base, "*", "assignment.yaml"))
                           .map { |f| load_from_file(f) }
                           .compact
                           .sort_by(&:updated_at)
                           .reverse

          assignments.first
        end

        # Set current assignment via .current symlink
        #
        # @param assignment_id [String] Assignment ID to set as current
        # @raise [AssignmentErrors::NotFound] if assignment doesn't exist
        def set_current(assignment_id)
          assignment = load(assignment_id)
          raise AssignmentErrors::NotFound, "Assignment '#{assignment_id}' not found" unless assignment

          current_symlink = File.join(@cache_base, ".current")

          # Remove old symlink if it exists
          File.delete(current_symlink) if File.symlink?(current_symlink)

          # Create new symlink
          target_dir = File.join(@cache_base, assignment_id)
          File.symlink(target_dir, current_symlink)

          assignment
        end

        # Clear current assignment selection
        #
        # Removes the .current symlink, falling back to .latest resolution
        def clear_current
          current_symlink = File.join(@cache_base, ".current")
          File.delete(current_symlink) if File.symlink?(current_symlink)
        end

        # Get the currently selected assignment ID (from .current symlink)
        #
        # @return [String, nil] Current assignment ID or nil
        def current_id
          current_symlink = File.join(@cache_base, ".current")
          return nil unless File.symlink?(current_symlink)

          File.basename(File.readlink(current_symlink))
        end

        # Delete an assignment's cache directory and clean up symlinks
        #
        # @param assignment_id [String] Assignment ID to delete
        # @return [Boolean] true if deleted, false if not found
        def delete(assignment_id)
          dir = File.join(@cache_base, assignment_id)
          return false unless File.directory?(dir)

          cleanup_symlink(".current", assignment_id)
          cleanup_symlink(".latest", assignment_id)
          FileUtils.rm_rf(dir)
          true
        end

        # Update assignment metadata
        #
        # @param assignment [Models::Assignment] Assignment to update
        # @return [Models::Assignment] Updated assignment
        def update(assignment)
          # Create new assignment with updated timestamp
          updated = Models::Assignment.new(
            id: assignment.id,
            name: assignment.name,
            description: assignment.description,
            created_at: assignment.created_at,
            updated_at: Time.now.utc,
            source_config: assignment.source_config,
            cache_dir: assignment.cache_dir,
            parent: assignment.parent
          )

          write_assignment_file(updated)

          # Update .latest symlink since this assignment was just updated
          update_latest_symlink(assignment.id)

          updated
        end

        # List all assignments
        #
        # @return [Array<Models::Assignment>] All assignments
        def list
          return [] unless File.directory?(@cache_base)

          Dir.glob(File.join(@cache_base, "*", "assignment.yaml"))
             .map { |f| load_from_file(f) }
             .compact
             .sort_by(&:updated_at)
             .reverse
        end

        private

        def generate_assignment_id
          base_id = Ace::B36ts.now
          candidate = base_id
          max_attempts = 100

          # Handle collision by appending suffix
          suffix = 0
          max_attempts.times do
            dir_path = File.join(@cache_base, candidate)
            # Atomic directory creation using Dir.mkdir - fails if exists
            begin
              Dir.mkdir(dir_path)
              return candidate
            rescue Errno::EEXIST
              # Directory already exists, try next candidate
              suffix += 1
              candidate = "#{base_id}#{suffix.to_s(36)}"
            end
          end

          # Max attempts exceeded - this should never happen in practice
          raise Error, "Failed to generate unique assignment ID after #{max_attempts} attempts. Cache directory may be corrupted."
        end

        def write_assignment_file(assignment)
          assignment_file = File.join(assignment.cache_dir, "assignment.yaml")
          File.write(assignment_file, assignment.to_h.to_yaml)
        end

        def load_from_file(assignment_file)
          cache_dir = File.dirname(assignment_file)
          data = YAML.safe_load_file(assignment_file, permitted_classes: [Time, Date])
          Models::Assignment.from_h(data, cache_dir: cache_dir)
        rescue StandardError => e
          warn "Failed to load assignment from #{assignment_file}: #{e.message}" if Ace::Assign.debug?
          nil
        end

        # Remove a symlink if it points to the specified assignment
        #
        # @param symlink_name [String] Symlink name (e.g., ".current", ".latest")
        # @param assignment_id [String] Assignment ID to match
        def cleanup_symlink(symlink_name, assignment_id)
          symlink_path = File.join(@cache_base, symlink_name)
          return unless File.symlink?(symlink_path)

          target = File.basename(File.readlink(symlink_path))
          File.delete(symlink_path) if target == assignment_id
        rescue StandardError
          # Non-fatal: continue without cleanup
        end

        # Update .latest symlink to point to the specified assignment
        # Provides O(1) active assignment lookup
        #
        # @param assignment_id [String] Assignment ID to link as .latest
        def update_latest_symlink(assignment_id)
          latest_symlink = File.join(@cache_base, ".latest")
          target_dir = File.join(@cache_base, assignment_id)

          # Remove old symlink if it exists
          File.delete(latest_symlink) if File.symlink?(latest_symlink)

          # Create new symlink
          File.symlink(target_dir, latest_symlink)
        rescue StandardError => e
          warn "Failed to update .latest symlink: #{e.message}" if Ace::Assign.debug?
          # Non-fatal: continue without symlink
        end
      end
    end
  end
end
