# frozen_string_literal: true

require "pathname"

module Ace
  module Taskflow
    module Molecules
      # Validates directory structure and file organization
      class StructureValidator
        def initialize(root_path = nil)
          @root_path = root_path || find_taskflow_root
        end

        # Validate the entire taskflow structure
        # @return [Hash] Validation result with :valid, :issues, and :stats
        def validate_all
          issues = []
          stats = {
            releases: { active: 0, backlog: 0, pending: 0, done: 0 },
            tasks: { total: 0, mislocated: 0 },
            ideas: { total: 0, mislocated: 0 },
            retros: { total: 0 },
            orphaned_files: 0,
            invalid_paths: 0
          }

          # Validate root structure
          validate_root_structure(issues, stats)

          # Validate releases
          validate_releases(issues, stats)

          # Check for orphaned files
          find_orphaned_files(issues, stats)

          # Check naming conventions
          validate_naming_conventions(issues, stats)

          {
            valid: issues.none? { |i| i[:type] == :error },
            issues: issues,
            stats: stats
          }
        end

        # Validate a specific release
        # @param release_path [String] Path to release
        # @return [Hash] Validation result
        def validate_release(release_path)
          issues = []
          stats = {
            tasks: { total: 0, mislocated: 0 },
            ideas: { total: 0, mislocated: 0 },
            docs: 0,
            invalid_paths: 0,
            orphaned_files: 0
          }

          unless Dir.exist?(release_path)
            return { valid: false, issues: [{ type: :error, message: "Release directory not found: #{release_path}" }], stats: stats }
          end

          # Check required directories
          check_release_directories(release_path, issues, stats)

          config = Ace::Taskflow.configuration
          # Check task structure
          validate_task_structure(File.join(release_path, config.task_dir), issues, stats)

          # Check idea structure
          validate_idea_structure(File.join(release_path, "ideas"), issues, stats)

          {
            valid: issues.none? { |i| i[:type] == :error },
            issues: issues,
            stats: stats
          }
        end

        private

        def find_taskflow_root
          current = Dir.pwd
          while current != "/"
            taskflow_dir = File.join(current, ".ace-taskflow")
            return taskflow_dir if Dir.exist?(taskflow_dir)
            current = File.dirname(current)
          end
          nil
        end

        def validate_root_structure(issues, stats)
          unless @root_path && Dir.exist?(@root_path)
            issues << { type: :error, message: ".ace-taskflow directory not found" }
            return
          end

          # Check for standard directories
          %w[backlog pending done].each do |dir|
            path = File.join(@root_path, dir)
            unless Dir.exist?(path)
              issues << { type: :warning, message: "Missing standard directory: #{dir}/", location: @root_path }
            end
          end

          # Check for active releases (v.X.Y.Z pattern)
          Dir.glob(File.join(@root_path, "v.*")).each do |release_dir|
            if File.basename(release_dir).match?(/^v\.\d+\.\d+\.\d+$/)
              stats[:releases][:active] += 1
            else
              issues << { type: :warning, message: "Non-standard release directory name: #{File.basename(release_dir)}", location: release_dir }
            end
          end
        end

        def validate_releases(issues, stats)
          # Check active releases
          Dir.glob(File.join(@root_path, "v.*")).each do |release_dir|
            validate_release_internal(release_dir, :active, issues, stats)
          end

          # Check backlog releases
          backlog_dir = File.join(@root_path, "backlog")
          if Dir.exist?(backlog_dir)
            Dir.glob(File.join(backlog_dir, "v.*")).each do |release_dir|
              validate_release_internal(release_dir, :backlog, issues, stats)
            end
          end

          # Check pending releases
          pending_dir = File.join(@root_path, "pending")
          if Dir.exist?(pending_dir)
            Dir.glob(File.join(pending_dir, "v.*")).each do |release_dir|
              validate_release_internal(release_dir, :pending, issues, stats)
            end
          end

          # Check done releases
          done_dir = File.join(@root_path, "done")
          if Dir.exist?(done_dir)
            Dir.glob(File.join(done_dir, "v.*")).each do |release_dir|
              validate_release_internal(release_dir, :done, issues, stats)
            end
          end
        end

        def validate_release_internal(release_dir, location, issues, stats)
          release_name = File.basename(release_dir)

          # Check version format
          unless release_name.match?(/^v\.\d+\.\d+\.\d+$/)
            issues << { type: :warning, message: "Non-standard release version: #{release_name}", location: release_dir }
          end

          # Update stats
          stats[:releases][location] += 1

          # Check for required directories in release
          check_release_directories(release_dir, issues, stats)
        end

        def check_release_directories(release_dir, issues, stats)
          config = Ace::Taskflow.configuration
          # Standard directories for a release (using configured names)
          subdirs = [config.task_dir, "ideas", "docs", config.retro_dir]
          subdirs.each do |subdir|
            path = File.join(release_dir, subdir)
            unless Dir.exist?(path)
              issues << { type: :info, message: "Missing directory: #{subdir}/", location: release_dir }
            end
          end

          # Check for release descriptor file (any .md in release root)
          release_files = Dir.glob(File.join(release_dir, "*.md")).select { |f| File.file?(f) && File.dirname(f) == release_dir }
          if release_files.empty?
            issues << { type: :warning, message: "Missing release descriptor file (*.md in release root)", location: release_dir }
          end
        end

        def validate_task_structure(task_dir, issues, stats)
          return unless Dir.exist?(task_dir)

          # Check tasks in main directory
          Dir.glob(File.join(task_dir, "*")).each do |task_folder|
            next unless File.directory?(task_folder)
            next if File.basename(task_folder) == "done"

            validate_task_folder(task_folder, :active, issues, stats)
          end

          # Check done tasks
          done_dir = File.join(task_dir, "done")
          if Dir.exist?(done_dir)
            Dir.glob(File.join(done_dir, "*")).each do |task_folder|
              next unless File.directory?(task_folder)
              validate_task_folder(task_folder, :done, issues, stats)
            end
          end
        end

        def validate_task_folder(task_folder, location, issues, stats)
          folder_name = File.basename(task_folder)
          stats[:tasks] ||= { total: 0, mislocated: 0 }
          stats[:tasks][:total] += 1

          # Check folder naming convention (NNN or NNN-description)
          unless folder_name.match?(/^\d{3}(-[\w-]+)?$/)
            issues << { type: :warning, message: "Non-standard task folder name: #{folder_name}", location: task_folder }
            stats[:invalid_paths] ||= 0
          stats[:invalid_paths] += 1
          end

          # Check for task file
          task_files = Dir.glob(File.join(task_folder, "task.*.md"))
          if task_files.empty?
            # Try older format
            task_files = Dir.glob(File.join(task_folder, "*.md"))
          end

          if task_files.empty?
            issues << { type: :error, message: "No task file found", location: task_folder }
          elsif task_files.size > 1
            # Check if one is the main task file
            main_task = task_files.find { |f| File.basename(f).match?(/^task\.\d+\.md$/) }
            unless main_task
              issues << { type: :warning, message: "Multiple markdown files, unclear which is main task", location: task_folder }
            end
          end

          # Check for standard subdirectories
          %w[docs ux qa].each do |subdir|
            path = File.join(task_folder, subdir)
            # These are optional, so just track if present
            stats["task_#{subdir}".to_sym] ||= 0
            stats["task_#{subdir}".to_sym] += 1 if Dir.exist?(path)
          end
        end

        def validate_idea_structure(idea_dir, issues, stats)
          return unless Dir.exist?(idea_dir)

          # Check ideas in main directory
          Dir.glob(File.join(idea_dir, "*")).each do |item|
            next if File.basename(item) == "done"

            if File.file?(item) && item.end_with?(".md")
              validate_idea_file(item, :pending, issues, stats)
            elsif File.directory?(item)
              validate_idea_directory(item, :pending, issues, stats)
            end
          end

          # Check done ideas
          done_dir = File.join(idea_dir, "done")
          if Dir.exist?(done_dir)
            Dir.glob(File.join(done_dir, "*")).each do |item|
              if File.file?(item) && item.end_with?(".md")
                validate_idea_file(item, :done, issues, stats)
              elsif File.directory?(item)
                validate_idea_directory(item, :done, issues, stats)
              end
            end
          end
        end

        def validate_idea_file(file_path, location, issues, stats)
          filename = File.basename(file_path)
          stats[:ideas] ||= { total: 0, mislocated: 0 }
          stats[:ideas][:total] += 1

          # Check naming convention (YYYYMMDD-description.md or YYYYMMDD-HHMMSS-description.md)
          unless filename.match?(/^\d{8}(-\d{6})?-[\w-]+\.md$/)
            issues << { type: :warning, message: "Non-standard idea filename: #{filename}", location: file_path }
            stats[:invalid_paths] ||= 0
          stats[:invalid_paths] += 1
          end
        end

        def validate_idea_directory(dir_path, location, issues, stats)
          dirname = File.basename(dir_path)
          stats[:ideas] ||= { total: 0, mislocated: 0 }
          stats[:ideas][:total] += 1

          # Directory ideas should follow same naming as files (without .md)
          unless dirname.match?(/^\d{8}(-\d{6})?-[\w-]+$/)
            issues << { type: :warning, message: "Non-standard idea directory name: #{dirname}", location: dir_path }
            stats[:invalid_paths] ||= 0
          stats[:invalid_paths] += 1
          end

          # Check for idea.md file inside
          idea_file = File.join(dir_path, "idea.md")
          unless File.exist?(idea_file)
            issues << { type: :warning, message: "Missing idea.md in idea directory", location: dir_path }
          end
        end

        def find_orphaned_files(issues, stats)
          # Look for files that don't belong to standard structure
          Dir.glob(File.join(@root_path, "**/*")).each do |path|
            next if File.directory?(path)
            next if path.include?("/.git/")
            next if path.include?("/docs/")
            next if path.include?("/retros/")

            relative_path = path.sub(@root_path + "/", "")

            # Check if file is in expected location
            unless expected_file_location?(relative_path)
              issues << { type: :info, message: "Orphaned file", location: path }
              stats[:orphaned_files] += 1
            end
          end
        end

        def expected_file_location?(relative_path)
          # Define expected file patterns
          patterns = [
            /^v\.\d+\.\d+\.\d+\/[^\/]+\.md$/,  # Any .md file in release root
            /^v\.\d+\.\d+\.\d+\/t\/\d{3}(-[\w-]+)?\/.*\.md$/,
            /^v\.\d+\.\d+\.\d+\/ideas\/(done\/)?(\d{8}(-\d{6})?-[\w-]+\.md|\d{8}(-\d{6})?-[\w-]+\/.*)/,
            /^v\.\d+\.\d+\.\d+\/docs\/.*\.md$/,
            /^v\.\d+\.\d+\.\d+\/retros\/.*\.md$/,
            /^(backlog|pending|done)\/v\.\d+\.\d+\.\d+\/.*/,
            /^backlog\/(ideas|tasks)\/.*/
          ]

          patterns.any? { |pattern| relative_path.match?(pattern) }
        end

        def validate_naming_conventions(issues, stats)
          # Additional naming convention checks
          # This is covered by individual validators above
        end
      end
    end
  end
end