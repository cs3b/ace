# frozen_string_literal: true

require "yaml"
require_relative "../molecules/frontmatter_validator"
require_relative "../molecules/structure_validator"
require_relative "../molecules/integrity_validator"
require_relative "../molecules/release_validator"

module Ace
  module Taskflow
    module Organisms
      # Orchestrates comprehensive health checks for the taskflow system
      class TaskflowDoctor
        attr_reader :root_path, :options

        def initialize(root_path = nil, options = {})
          @root_path = root_path || find_taskflow_root
          @options = options
          @issues = []
          @stats = {
            files_scanned: 0,
            components: {},
            errors: 0,
            warnings: 0,
            info: 0
          }
        end

        # Run comprehensive health check
        # @return [Hash] Health check results
        def run_diagnosis
          return { valid: false, error: "No .ace-taskflow directory found" } unless @root_path

          # Start diagnosis
          @start_time = Time.now

          # Run checks based on options
          if options[:component]
            run_component_check(options[:component])
          elsif options[:release]
            run_release_check(options[:release])
          elsif options[:check]
            run_specific_check(options[:check])
          else
            run_full_check
          end

          # Calculate health score
          health_score = calculate_health_score

          # Build result
          {
            valid: @stats[:errors] == 0,
            health_score: health_score,
            issues: @issues,
            stats: @stats,
            duration: Time.now - @start_time,
            root_path: @root_path
          }
        end

        # Get issues that can be auto-fixed
        # @return [Array<Hash>] Auto-fixable issues
        def get_fixable_issues
          @issues.select { |issue| auto_fixable?(issue) }
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

        def run_full_check
          # Check structure
          run_structure_check if should_check?(:structure)

          # Collect active release statistics
          collect_active_stats

          # Check frontmatter in all files
          run_frontmatter_check if should_check?(:frontmatter)

          # Check integrity
          run_integrity_check if should_check?(:integrity)

          # Check releases
          run_release_check if should_check?(:releases)

          # Check for stale backup files
          check_backup_files

          # Check idea scope/status consistency
          check_idea_scope_consistency
        end

        def run_component_check(component)
          case component.to_sym
          when :tasks
            check_tasks
            check_backup_files
          when :ideas
            check_ideas
            check_idea_scope_consistency
          when :releases
            check_releases
          when :retros
            check_retros
          else
            add_issue(:error, "Unknown component: #{component}")
          end
        end

        def run_release_check(release = nil)
          if release
            check_specific_release(release)
          else
            check_releases
          end
        end

        def run_specific_check(check_type)
          case check_type.to_sym
          when :frontmatter
            run_frontmatter_check
          when :structure
            run_structure_check
          when :integrity
            run_integrity_check
          when :dependencies
            check_dependencies
          when :subtasks
            check_subtasks
          else
            add_issue(:error, "Unknown check type: #{check_type}")
          end
        end

        def should_check?(check_type)
          return true unless options[:check]
          options[:check].to_sym == check_type
        end

        def collect_active_stats
          require_relative "../organisms/task_manager"
          require_relative "../molecules/idea_loader"
          require_relative "../molecules/release_resolver"

          # Initialize with the same root_path used by doctor
          task_manager = Organisms::TaskManager.new(@root_path)
          idea_loader = Molecules::IdeaLoader.new(@root_path)
          release_resolver = Molecules::ReleaseResolver.new(@root_path)

          # Get primary active release for statistics
          active_release = release_resolver.find_primary_active
          return unless active_release

          # Use release name (e.g., "v.0.9.0")
          release = active_release[:name]

          # Get task statistics for active release
          task_stats = task_manager.get_statistics(release: release)

          # Get idea statistics for active release
          ideas = idea_loader.load_all(release: release, include_content: false)
          idea_stats = {
            total: ideas.size,
            by_status: {}
          }

          ideas.each do |idea|
            status = if idea[:path] && idea[:path].include?("/done/")
                      "done"
                     else
                      idea[:status] || "new"
                     end
            idea_stats[:by_status][status] ||= 0
            idea_stats[:by_status][status] += 1
          end

          # Store in stats
          @stats[:components][:active_stats] = {
            tasks: task_stats,
            ideas: idea_stats
          }
        end

        def run_structure_check
          validator = Molecules::StructureValidator.new(@root_path)
          result = validator.validate_all

          result[:issues].each do |issue|
            add_issue(issue[:type], issue[:message], issue[:location] || issue[:file])
          end

          @stats[:components][:structure] = result[:stats] if result[:stats]
        end

        def run_frontmatter_check
          # Find all markdown files
          md_files = Dir.glob(File.join(@root_path, "**/*.md"))
            .reject { |f| f.include?("/.git/") }

          md_files.each do |file|
            @stats[:files_scanned] += 1

            # Detect component type
            component_type = detect_component_type(file)
            next if component_type == :skip  # Skip review/docs/qa/backup files
            next if component_type == :unknown && !options[:verbose]

            result = Molecules::FrontmatterValidator.validate_file(file, component_type)

            result[:issues].each do |issue|
              add_issue(issue[:type], issue[:message], file)
            end
          end
        end

        def run_integrity_check
          validator = Molecules::IntegrityValidator.new(@root_path)
          result = validator.validate_all

          result[:issues].each do |issue|
            location = issue[:location] || issue[:locations]&.join(", ")
            add_issue(issue[:type], issue[:message], location)
          end

          @stats[:components][:integrity] = result[:stats] if result[:stats]
        end

        def check_releases
          validator = Molecules::ReleaseValidator.new(@root_path)
          result = validator.validate_all

          result[:issues].each do |issue|
            location = issue[:location] || issue[:locations]&.join(", ")
            add_issue(issue[:type], issue[:message], location)
          end

          @stats[:components][:releases] = result[:stats] if result[:stats]
        end

        def check_specific_release(release_name)
          release_path = find_release_path(release_name)
          unless release_path
            add_issue(:error, "Release not found: #{release_name}")
            return
          end

          # Check release structure
          validator = Molecules::StructureValidator.new(@root_path)
          result = validator.validate_release(release_path)

          result[:issues].each do |issue|
            add_issue(issue[:type], issue[:message], issue[:location] || release_path)
          end

          @stats[:components][:release] = result[:stats] if result[:stats]
        end

        def check_tasks
          config = Ace::Taskflow.configuration
          task_dir = config.task_dir
          # Find all task files
          task_files = Dir.glob(File.join(@root_path, "**", task_dir, "**", "task.*.md"))
            .concat(Dir.glob(File.join(@root_path, "**", task_dir, "**", "*.md")))
            .uniq

          task_files.each do |file|
            check_task_file(file)
          end
        end

        def check_ideas
          # Find all idea files
          idea_files = Dir.glob(File.join(@root_path, "**/ideas/**/*.md"))
            .reject { |f| f.include?("/.git/") }

          idea_files.each do |file|
            check_idea_file(file)
          end

          # Check for legacy format files (migration validation)
          check_legacy_idea_formats(idea_files)

          # Check idea structure (misplaced files)
          check_idea_structure
        end

        def check_retros
          # Find all retro files using configured directory name
          config = Ace::Taskflow.configuration
          retro_dir = config.retro_dir
          retro_files = Dir.glob(File.join(@root_path, "**", retro_dir, "**/*.md"))
            .reject { |f| f.include?("/.git/") }

          retro_files.each do |file|
            @stats[:files_scanned] += 1
            # Check if file is readable
            unless File.readable?(file)
              add_issue(:warning, "Cannot read retro file", file)
              next
            end

            # Check retro naming format
            check_retro_naming(file)
          end

          # Check for legacy format files (migration validation)
          check_legacy_retro_formats(retro_files)
        end

        def check_dependencies
          validator = Molecules::IntegrityValidator.new(@root_path)
          result = validator.validate_all

          # Filter to only dependency-related issues
          dependency_issues = result[:issues].select do |issue|
            issue[:message].include?("depend") || issue[:message].include?("circular")
          end

          dependency_issues.each do |issue|
            location = issue[:location] || issue[:locations]&.join(", ")
            add_issue(issue[:type], issue[:message], location)
          end
        end

        def check_subtasks
          require_relative "../organisms/task_manager"
          require_relative "../molecules/release_resolver"

          release_resolver = Molecules::ReleaseResolver.new(@root_path)
          active_release = release_resolver.find_primary_active
          return add_issue(:warning, "No active release found") unless active_release

          task_manager = Organisms::TaskManager.new(@root_path)
          all_tasks = task_manager.load_all(release: active_release[:name], include_content: false)

          subtask_issues = 0
          orphan_issues = 0

          all_tasks.each do |task|
            @stats[:files_scanned] += 1
            parent_id = task[:parent_id] || task.dig(:frontmatter, "parent_id")
            subtask_ids = task[:subtask_ids] || task.dig(:frontmatter, "subtask_ids") || []

            # Check parent reference exists
            if parent_id
              parent_task = all_tasks.find { |t| t[:id] == parent_id }
              unless parent_task
                add_issue(:error, "Subtask references non-existent parent_id: #{parent_id}", task[:path])
                orphan_issues += 1
              end
            end

            # Check subtask references exist
            subtask_ids.each do |subtask_id|
              subtask = all_tasks.find { |t| t[:id] == subtask_id }
              unless subtask
                add_issue(:error, "Parent task references non-existent subtask_id: #{subtask_id}", task[:path])
                subtask_issues += 1
              else
                # Check bidirectional consistency
                child_parent_id = subtask[:parent_id] || subtask.dig(:frontmatter, "parent_id")
                unless child_parent_id == task[:id]
                  add_issue(:warning, "Subtask #{subtask_id} does not reference parent #{task[:id]}", task[:path])
                end
              end
            end
          end

          @stats[:components][:subtasks] = {
            orphan_issues: orphan_issues,
            subtask_issues: subtask_issues
          }
        end

        def check_task_file(file)
          @stats[:files_scanned] += 1
          result = Molecules::FrontmatterValidator.validate_file(file, :task)

          result[:issues].each do |issue|
            add_issue(issue[:type], issue[:message], file)
          end

          # Additional task-specific checks
          check_task_location_consistency(file, result[:frontmatter]) if result[:frontmatter]
        end

        def check_idea_file(file)
          @stats[:files_scanned] += 1
          result = Molecules::FrontmatterValidator.validate_file(file, :idea)

          result[:issues].each do |issue|
            add_issue(issue[:type], issue[:message], file)
          end

          # Check naming convention
          check_idea_naming(file)
        end

        def check_task_location_consistency(file, frontmatter)
          return unless frontmatter["status"]

          config = Ace::Taskflow.configuration
          done_dir = config.done_dir
          # Use anchored regex pattern to avoid substring false positives
          # (e.g., "my_done_tasks" should not match "done")
          is_in_done = config.path_in_done_dir?(file)
          status = frontmatter["status"]
          # Terminal states that are valid in done/ directory (from configuration)
          terminal_states = config.terminal_statuses

          if terminal_states.include?(status) && !is_in_done
            add_issue(:warning, "Task with terminal status '#{status}' not in #{done_dir}/ directory", file)
          elsif !terminal_states.include?(status) && is_in_done
            add_issue(:error, "Task in #{done_dir}/ directory but status is '#{status}'", file)
          end
        end

        def check_idea_naming(file)
          filename = File.basename(file)
          # Check for new .idea.s.md format in directory-based ideas
          unless filename.end_with?(".idea.s.md")
            add_issue(:warning, "Non-standard idea filename format (expected .idea.s.md)", file)
          end
        end

        def check_retro_naming(file)
          filename = File.basename(file, ".md")
          # Check for Base36 ID prefix format (e.g., i50jj3-performance-analysis.md)
          unless filename.match?(/^[a-z0-9]+-/)
            add_issue(:warning, "Non-standard retro filename format (expected Base36 ID prefix)", file)
          end
        end

        def check_legacy_idea_formats(idea_files)
          # Check for legacy flat file .s.md format
          flat_files = idea_files.select { |f| f.end_with?(".s.md") && !f.end_with?(".idea.s.md") }
          flat_files.each do |file|
            add_issue(:warning, "Legacy flat file idea format (.s.md) found - run migration", file)
          end

          # Check for old idea.s.md format (without slug)
          old_idea_files = idea_files.select { |f| File.basename(f) == "idea.s.md" }
          old_idea_files.each do |file|
            add_issue(:warning, "Legacy idea.s.md format found (should use slug.idea.s.md)", file)
          end
        end

        def check_legacy_retro_formats(retro_files)
          # Check for legacy date-prefixed formats
          date_prefix_pattern = /^\d{4}-\d{2}-\d{2}-/
          legacy_files = retro_files.select { |f| File.basename(f).match?(date_prefix_pattern) }
          legacy_files.each do |file|
            add_issue(:warning, "Legacy date-prefixed retro format found (YYYY-MM-DD-) - run migration", file)
          end
        end

        def find_release_path(release_name)
          config = Ace::Taskflow.configuration
          # Look in active releases
          active_path = File.join(@root_path, release_name)
          return active_path if Dir.exist?(active_path)

          # Look in backlog
          backlog_path = File.join(@root_path, config.backlog_dir, release_name)
          return backlog_path if Dir.exist?(backlog_path)

          # Look in done
          done_path = File.join(@root_path, config.done_dir, release_name)
          return done_path if Dir.exist?(done_path)

          nil
        end

        def detect_component_type(file)
          # Skip non-content files (review reports, docs, qa artifacts, backups)
          # These are supporting files in task directories, not tasks themselves
          return :skip if file.include?("/review/") ||
                          file.include?("/docs/") ||
                          file.include?("/qa/") ||
                          file.match?(/\.backup\./)

          # Get configured directory names
          config = Ace::Taskflow.configuration
          task_dir = config.task_dir       # e.g., "tasks"
          retro_dir = config.retro_dir     # e.g., "retros"

          # For ideas, use "ideas" at release level (config.ideas_dir is global path "backlog/ideas")
          ideas_dir_name = "ideas"

          # Check directory structure first (more reliable than filename)
          # Directory patterns use configured names
          case file
          when /\/#{Regexp.escape(retro_dir)}\//
            :retro
          when /\/#{ideas_dir_name}\//
            :idea
          when /release\.md$/
            :release
          when /\/#{Regexp.escape(task_dir)}\/.*task\.\d{3,}.*\.md$/
            # Must be in tasks/ directory AND match filename pattern
            :task
          else
            :unknown
          end
        end

        # Check for stale backup files in active task directories
        def check_backup_files
          config = Ace::Taskflow.configuration
          done_dir = config.done_dir

          # Glob for backup files in all task directories, excluding archive
          backup_files = Dir.glob(File.join(@root_path, "**", "*.backup.*"))
            .reject { |f| f.include?("/#{done_dir}/") }
            .reject { |f| f.include?("/.git/") }

          backup_files.each do |file|
            add_issue(:warning, "Stale backup file (safe to delete)", file)
          end
        end

        # Check idea scope/status consistency
        def check_idea_scope_consistency
          config = Ace::Taskflow.configuration
          done_dir = config.done_dir
          maybe_dir = config.maybe_dir

          idea_files = Dir.glob(File.join(@root_path, "**/ideas/**/*.md"))
            .reject { |f| f.include?("/.git/") }

          idea_files.each do |file|
            # Read frontmatter to get status
            begin
              content = File.read(file)
              next unless content =~ /\A---\s*\n(.*?)\n---/m
              frontmatter = YAML.safe_load($1) || {}
            rescue StandardError
              next
            end

            status = frontmatter["status"]
            in_archive = file.include?("/#{done_dir}/")
            in_maybe = file.include?("/#{maybe_dir}/")

            # Error: Ideas in maybe/_archive/ — invalid nesting
            if in_maybe && in_archive
              add_issue(:error, "Idea in #{maybe_dir}/#{done_dir}/ (invalid nesting, should be in ideas/#{done_dir}/)", file)
              next
            end

            # Error: Ideas in _archive/ with non-terminal status
            if in_archive && status && !%w[done obsolete cancelled].include?(status)
              add_issue(:error, "Idea in #{done_dir}/ but status is '#{status}' (expected terminal status)", file)
            end

            # Warning: Ideas with status: done not in _archive/
            if status == "done" && !in_archive
              add_issue(:warning, "Idea with status 'done' not in #{done_dir}/ directory", file)
            end

            # Warning: Ideas with status: parked not in maybe/
            if status == "parked" && !in_maybe
              add_issue(:warning, "Idea with status 'parked' not in #{maybe_dir}/ directory", file)
            end
          end
        end

        # Check idea file structure using IdeaStructureValidator
        def check_idea_structure
          require_relative "../molecules/idea_structure_validator"
          validator = Molecules::IdeaStructureValidator.new(@root_path)
          result = validator.validate_all

          result[:misplaced].each do |misplaced|
            add_issue(:warning, "Misplaced idea file: #{misplaced[:reason]}", misplaced[:path])
          end
        end

        def add_issue(type, message, location = nil)
          issue = {
            type: type,
            message: message
          }
          issue[:location] = location if location

          @issues << issue

          # Update stats
          case type
          when :error
            @stats[:errors] += 1
          when :warning
            @stats[:warnings] += 1
          when :info
            @stats[:info] += 1
          end
        end

        def calculate_health_score
          # Base score
          score = 100

          # Deduct for errors (heavy penalty)
          score -= @stats[:errors] * 10

          # Deduct for warnings (moderate penalty)
          score -= @stats[:warnings] * 3

          # Deduct for info issues (light penalty)
          score -= @stats[:info] * 1

          # Ensure score is between 0 and 100
          [[score, 0].max, 100].min
        end

        def auto_fixable?(issue)
          # Define which issues can be auto-fixed
          return false unless issue[:type] == :error || issue[:type] == :warning

          # Get configured done directory name for dynamic patterns
          config = Ace::Taskflow.configuration
          done_dir = Regexp.escape(config.done_dir)

          # Check for specific fixable patterns
          fixable_patterns = [
            /Missing closing '---' delimiter/,
            /not in #{done_dir}\/ directory/,
            /in #{done_dir}\/ directory but status is/,
            /Missing recommended field:/,
            /Missing default/,
            /Stale backup file/,
            /invalid nesting, should be in ideas/
          ]

          fixable_patterns.any? { |pattern| issue[:message].match?(pattern) }
        end
      end
    end
  end
end