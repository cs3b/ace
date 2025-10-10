# frozen_string_literal: true

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

          # Check frontmatter in all files
          run_frontmatter_check if should_check?(:frontmatter)

          # Check integrity
          run_integrity_check if should_check?(:integrity)

          # Check releases
          run_release_check if should_check?(:releases)
        end

        def run_component_check(component)
          case component.to_sym
          when :tasks
            check_tasks
          when :ideas
            check_ideas
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
          else
            add_issue(:error, "Unknown check type: #{check_type}")
          end
        end

        def should_check?(check_type)
          return true unless options[:check]
          options[:check].to_sym == check_type
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
          # Find all task files
          task_files = Dir.glob(File.join(@root_path, "**/t/**/task.*.md"))
            .concat(Dir.glob(File.join(@root_path, "**/t/**/*.md")))
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
        end

        def check_retros
          # Find all retro files
          retro_files = Dir.glob(File.join(@root_path, "**/retros/**/*.md"))
            .reject { |f| f.include?("/.git/") }

          retro_files.each do |file|
            @stats[:files_scanned] += 1
            # Retros typically don't have strict requirements
            # Just check if file is readable
            unless File.readable?(file)
              add_issue(:warning, "Cannot read retro file", file)
            end
          end
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

          is_in_done = file.include?("/done/")
          status = frontmatter["status"]

          if status == "done" && !is_in_done
            add_issue(:warning, "Task marked as done but not in done/ directory", file)
          elsif status != "done" && is_in_done
            add_issue(:error, "Task in done/ directory but status is '#{status}'", file)
          end
        end

        def check_idea_naming(file)
          filename = File.basename(file)
          unless filename.match?(/^\d{8}(-\d{6})?-[\w-]+\.md$/)
            add_issue(:warning, "Non-standard idea filename format", file)
          end
        end

        def find_release_path(release_name)
          # Look in active releases
          active_path = File.join(@root_path, release_name)
          return active_path if Dir.exist?(active_path)

          # Look in backlog
          backlog_path = File.join(@root_path, "backlog", release_name)
          return backlog_path if Dir.exist?(backlog_path)

          # Look in done
          done_path = File.join(@root_path, "done", release_name)
          return done_path if Dir.exist?(done_path)

          nil
        end

        def detect_component_type(file)
          case file
          when /\/t\/.*\.md$/, /task\.\d+\.md$/
            :task
          when /\/ideas\/.*\.md$/
            :idea
          when /\/retros\/.*\.md$/
            :retro
          when /release\.md$/
            :release
          else
            :unknown
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

          # Check for specific fixable patterns
          fixable_patterns = [
            /Missing closing '---' delimiter/,
            /marked as done but not in done\/ directory/,
            /in done\/ directory but status is/,
            /Missing recommended field:/,
            /Missing default/
          ]

          fixable_patterns.any? { |pattern| issue[:message].match?(pattern) }
        end
      end
    end
  end
end