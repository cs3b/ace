# frozen_string_literal: true

require_relative "../../atoms/taskflow_management/directory_navigator"
require_relative "../../molecules/taskflow_management/release_path_resolver"

module CodingAgentTools
  module Organisms
    module TaskflowManagement
      # ReleaseManager provides a unified interface for all release operations
      # This organism consolidates release management functionality that was
      # previously scattered across multiple molecules and scripts
      class ReleaseManager
        # Release information structure with enhanced metadata
        ReleaseInfo = Struct.new(:path, :version, :name, :type, :status, :task_count, :created_at, :modified_at) do
          def completed?
            type == :done
          end

          def current?
            type == :current
          end

          def backlog?
            type == :backlog
          end
        end

        # Manager result structure for consistent API
        ManagerResult = Struct.new(:data, :success, :error_message) do
          def success?
            success
          end

          def failed?
            !success
          end
        end

        # Initialize ReleaseManager
        # @param base_path [String] Base path for release resolution
        def initialize(base_path: ".")
          @base_path = base_path
          @directory_navigator = Atoms::TaskflowManagement::DirectoryNavigator
          @release_resolver = Molecules::TaskflowManagement::ReleasePathResolver
        end

        # Get current release information
        # @return [ManagerResult] Result containing current release info or error
        def current
          result = @release_resolver.get_current_release(base_path: @base_path)

          if result.success?
            release_info = enhance_release_info(result.release_info, :current)
            ManagerResult.new(release_info, true, nil)
          else
            ManagerResult.new(nil, false, result.error_message)
          end
        rescue => e
          ManagerResult.new(nil, false, "Error getting current release: #{e.message}")
        end

        # Find next available release in backlog (lowest version ready to move to current)
        # @return [ManagerResult] Result containing next release info or error
        def next
          # Since backlog doesn't contain versioned releases based on our analysis,
          # we'll implement a placeholder that can be enhanced when backlog structure changes
          backlog_path = File.join(@base_path, "dev-taskflow/backlog")

          unless File.exist?(backlog_path) && File.directory?(backlog_path)
            return ManagerResult.new(nil, false, "Backlog directory not found: #{backlog_path}")
          end

          # Look for any directory that could be a versioned release
          potential_release_paths = find_potential_releases_in_backlog(backlog_path)

          if potential_release_paths.empty?
            return ManagerResult.new(nil, true, "No versioned releases found in backlog")
          end

          # Convert paths to release info objects first
          potential_releases = potential_release_paths.map { |path| create_release_info(path, :backlog) }

          # Sort by version and return the lowest
          sorted_releases = sort_releases_by_version(potential_releases)
          next_release = sorted_releases.first

          ManagerResult.new(next_release, true, nil)
        rescue => e
          ManagerResult.new(nil, false, "Error finding next release: #{e.message}")
        end

        # Generate next available task ID with minor version bump
        # @return [ManagerResult] Result containing generated task ID or error
        def generate_id
          # Get all releases to find the latest version
          all_releases_result = all
          return all_releases_result unless all_releases_result.success?

          latest_version = find_latest_version(all_releases_result.data)
          next_version = bump_minor_version(latest_version)
          next_task_number = find_next_task_number(next_version)

          new_task_id = "#{next_version}+task.#{next_task_number}"
          ManagerResult.new(new_task_id, true, nil)
        rescue => e
          ManagerResult.new(nil, false, "Error generating task ID: #{e.message}")
        end

        # Generate next release directory with codename
        # @param codename [String] Optional codename for the release
        # @return [ManagerResult] Result containing version and path or error
        def generate_release(codename: nil)
          # Get all releases to find the latest version
          all_releases_result = all
          return all_releases_result unless all_releases_result.success?

          latest_version = find_latest_version(all_releases_result.data)
          next_version = bump_minor_version(latest_version)

          # Generate or validate codename
          final_codename = codename || generate_unique_codename(all_releases_result.data)

          # Create release directory path
          release_name = "#{next_version}-#{final_codename}"
          release_path = File.join(@base_path, "dev-taskflow", "backlog", release_name)

          # Create directory structure
          Dir.mkdir(release_path) unless File.exist?(release_path)
          Dir.mkdir(File.join(release_path, "tasks")) unless File.exist?(File.join(release_path, "tasks"))

          # Create basic release info file
          create_release_info_file(release_path, next_version, final_codename)

          result_data = {
            version: next_version,
            codename: final_codename,
            path: release_path
          }

          ManagerResult.new(result_data, true, nil)
        rescue => e
          ManagerResult.new(nil, false, "Error generating release: #{e.message}")
        end

        # List all releases across done/current/backlog with metadata
        # @return [ManagerResult] Result containing array of all releases or error
        def all
          all_releases = []

          # Scan done releases
          all_releases.concat(scan_releases_in_directory("done", :done))

          # Scan current releases
          all_releases.concat(scan_releases_in_directory("current", :current))

          # Scan backlog releases
          all_releases.concat(scan_releases_in_directory("backlog", :backlog))

          # Sort by version (semantic version comparison)
          sorted_releases = sort_releases_by_version(all_releases)

          ManagerResult.new(sorted_releases, true, nil)
        rescue => e
          ManagerResult.new([], false, "Error listing all releases: #{e.message}")
        end

        # Resolve path within current release directory
        # @param subpath [String] Subdirectory path to resolve (e.g., "reflections", "tasks", "reflections/synthesis")
        # @param create_if_missing [Boolean] Whether to create directory if it doesn't exist (default: false)
        # @return [String] Absolute path to the resolved directory
        # @raise [StandardError] If no current release exists or path validation fails
        def resolve_path(subpath, create_if_missing: false)
          raise ArgumentError, "subpath cannot be nil or empty" if subpath.nil? || subpath.to_s.empty?

          # Get current release
          current_result = current
          unless current_result.success?
            raise StandardError, "Cannot resolve path: #{current_result.error_message}"
          end

          current_release = current_result.data
          resolved_path = File.join(current_release.path, subpath)

          # Validate the resolved path for security
          unless @directory_navigator.safe_directory_path?(resolved_path)
            raise SecurityError, "Resolved path failed safety validation: #{resolved_path}"
          end

          # Create directory if requested and doesn't exist
          if create_if_missing && (!File.exist?(resolved_path) || !File.directory?(resolved_path))
            @directory_navigator.ensure_directory_exists(resolved_path)
          end

          File.expand_path(resolved_path)
        end

        # Validate that release context detection is consistent
        # This helps detect potential inconsistencies between tools early
        # @return [ManagerResult] Result indicating validation status
        def validate_release_context_consistency
          # Get current release through our normal detection method
          current_result = current
          return current_result unless current_result.success?

          current_release = current_result.data

          # Validate that there's exactly one release in current directory
          current_path = File.join(@base_path, "dev-taskflow/current")
          if File.exist?(current_path) && File.directory?(current_path)
            subdirs = Dir.entries(current_path).select do |entry|
              next false if entry == "." || entry == ".."
              File.directory?(File.join(current_path, entry))
            end

            case subdirs.size
            when 0
              return ManagerResult.new(nil, false, "No current release found - current directory is empty")
            when 1
              # This is the expected state
              detected_name = subdirs.first
              if detected_name != current_release.name
                return ManagerResult.new(nil, false,
                  "Inconsistency detected: Directory name '#{detected_name}' != detected release name '#{current_release.name}'")
              end
            else
              # Multiple releases in current - this could cause inconsistencies
              return ManagerResult.new(nil, false,
                "Multiple releases in current directory: #{subdirs.join(", ")}. This may cause tool inconsistencies.")
            end
          end

          validation_info = {
            current_release: current_release.name,
            path: current_release.path,
            validation_status: "consistent"
          }

          ManagerResult.new(validation_info, true, "Release context validation passed")
        rescue => e
          ManagerResult.new(nil, false, "Error validating release context: #{e.message}")
        end

        private

        # Enhance release info with additional metadata
        def enhance_release_info(basic_info, type)
          return nil unless basic_info

          path = basic_info.respond_to?(:path) ? basic_info.path : basic_info[:path]
          version = basic_info.respond_to?(:version) ? basic_info.version : basic_info[:version]
          name = basic_info.respond_to?(:name) ? basic_info.name : File.basename(path)

          create_release_info_with_metadata(path, version, name, type)
        end

        # Create enhanced release info with metadata
        def create_release_info_with_metadata(path, version, name, type)
          task_count = count_tasks_in_release(path)
          created_at = File.exist?(path) ? File.ctime(path) : nil
          modified_at = File.exist?(path) ? File.mtime(path) : nil

          # Determine status based on task completion
          status = determine_release_status(path, type)

          ReleaseInfo.new(path, version, name, type, status, task_count, created_at, modified_at)
        end

        # Create basic release info
        def create_release_info(path, type)
          name = File.basename(path)
          version = extract_version_from_name(name)
          create_release_info_with_metadata(path, version, name, type)
        end

        # Count tasks in a release directory
        def count_tasks_in_release(path)
          return 0 unless File.exist?(path) && File.directory?(path)

          tasks_dir = File.join(path, "tasks")
          return 0 unless File.exist?(tasks_dir) && File.directory?(tasks_dir)

          Dir.glob(File.join(tasks_dir, "*.md")).count
        end

        # Determine release status based on task completion
        def determine_release_status(path, type)
          return "archived" if type == :done
          return "active" if type == :current
          return "planned" if type == :backlog
          "unknown"
        end

        # Find potential releases in backlog directory
        def find_potential_releases_in_backlog(backlog_path)
          potential_releases = []

          Dir.entries(backlog_path).each do |entry|
            next if entry.start_with?(".")

            entry_path = File.join(backlog_path, entry)
            next unless File.directory?(entry_path)

            # Check if directory name suggests it's a versioned release
            if entry.match?(/^v\.\d+\.\d+\.\d+/)
              potential_releases << entry_path
            end
          end

          potential_releases
        end

        # Scan releases in a specific directory
        def scan_releases_in_directory(directory_name, type)
          releases = []
          base_dir = File.join(@base_path, "dev-taskflow", directory_name)

          return releases unless File.exist?(base_dir) && File.directory?(base_dir)

          Dir.entries(base_dir).each do |entry|
            next if entry.start_with?(".")

            entry_path = File.join(base_dir, entry)
            next unless File.directory?(entry_path)

            releases << create_release_info(entry_path, type)
          end

          releases
        end

        # Sort releases by semantic version
        def sort_releases_by_version(releases)
          releases.sort_by do |release|
            version = release.version || release.name
            parse_semantic_version(version)
          end
        end

        # Parse semantic version for sorting
        def parse_semantic_version(version_string)
          # Extract version numbers from strings like "v.0.3.0-migration" or "v.0.1.0-foundation"
          match = version_string.match(/v\.(\d+)\.(\d+)\.(\d+)/)
          if match
            [match[1].to_i, match[2].to_i, match[3].to_i]
          else
            # Fallback for non-semantic versions - sort alphabetically
            [999, 999, 999, version_string]
          end
        end

        # Extract version from directory name
        def extract_version_from_name(name)
          match = name.match(/^(v\.\d+\.\d+\.\d+)/)
          match ? match[1] : name
        end

        # Generate unique codename using LLM
        def generate_unique_codename(existing_releases)
          existing_codenames = extract_existing_codenames(existing_releases)

          # Use llm-query with system prompt for cleaner generation
          system_prompt = "return only with one word codename, we already have #{existing_codenames.join(", ")}"
          user_prompt = "give one word codename for release"

          # Use shell escaping to handle quotes properly
          escaped_user_prompt = user_prompt.gsub('"', '\\"')
          escaped_system_prompt = system_prompt.gsub('"', '\\"')

          # Use bundle exec to ensure gem context
          cmd = "bundle exec llm-query gflash \"#{escaped_user_prompt}\" --system \"#{escaped_system_prompt}\""

          result = `#{cmd} 2>/dev/null`.strip

          # Fallback if LLM fails
          if result.empty? || result.downcase.include?("error")
            generate_fallback_codename(existing_codenames)
          else
            # Extract only the first line (the actual codename) and clean it up
            first_line = result.split("\n").first.to_s.strip
            clean_codename = first_line.gsub(/[^a-zA-Z0-9-]/, "").downcase
            clean_codename.empty? ? generate_fallback_codename(existing_codenames) : clean_codename
          end
        end

        # Extract existing codenames from releases
        def extract_existing_codenames(releases)
          codenames = []

          releases.each do |release|
            name = release.name || File.basename(release.path)
            # Extract codename from names like "v.0.3.0-migration"
            match = name.match(/^v\.\d+\.\d+\.\d+-(.+)$/)
            codenames << match[1] if match
          end

          codenames
        end

        # Generate fallback codename if LLM fails
        def generate_fallback_codename(existing_codenames)
          timestamp = Time.now.strftime("%Y%m%d%H%M")
          codename = "release-#{timestamp}"

          # Ensure uniqueness
          counter = 1
          while existing_codenames.include?(codename)
            codename = "release-#{timestamp}-#{counter}"
            counter += 1
          end

          codename
        end

        # Create release info file
        def create_release_info_file(release_path, version, codename)
          info_content = <<~INFO
            # Release #{version} - #{codename}
            
            ## Overview
            Release #{version} with codename "#{codename}"
            
            ## Status
            - Status: PLANNED
            - Type: BACKLOG
            - Created: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
            
            ## Tasks
            Tasks for this release will be added to the `tasks/` directory.
            
            ## Notes
            Add any release-specific notes here.
          INFO

          File.write(File.join(release_path, "README.md"), info_content)
        end

        # Find latest version from all releases
        def find_latest_version(releases)
          return "v.0.0.0" if releases.empty?  # Changed from v.0.1.0 to v.0.0.0

          # Filter to only semantic versions (ignore non-versioned releases like "ideas", "future-considerations")
          semantic_releases = releases.select do |release|
            version_name = release.version || release.name
            version_name.match?(/^v\.\d+\.\d+\.\d+/)
          end

          return "v.0.0.0" if semantic_releases.empty?

          # Get the highest semantic version
          latest_release = semantic_releases.max_by { |release| parse_semantic_version(release.version || release.name) }
          latest_release.version || extract_version_from_name(latest_release.name)
        end

        # Bump minor version (e.g., v.0.3.0 -> v.0.4.0)
        def bump_minor_version(version)
          match = version.match(/^v\.(\d+)\.(\d+)\.(\d+)/)
          if match
            major, minor, patch = match[1].to_i, match[2].to_i, match[3].to_i
            "v.#{major}.#{minor + 1}.#{patch}"
          else
            "v.0.1.0"  # Default fallback
          end
        end

        # Find next task number for a version
        def find_next_task_number(version)
          # For now, start with task 1 for new versions
          # This could be enhanced to scan existing tasks for the version
          1
        end
      end
    end
  end
end
