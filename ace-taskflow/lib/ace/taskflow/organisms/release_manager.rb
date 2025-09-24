# frozen_string_literal: true

require "fileutils"
require_relative "../molecules/release_resolver"
require_relative "../molecules/task_loader"
require_relative "../molecules/config_loader"
require_relative "../atoms/path_builder"

module Ace
  module Taskflow
    module Organisms
      # Release business logic orchestration
      class ReleaseManager
        attr_reader :root_path, :config

        def initialize(config = nil)
          @config = config || Molecules::ConfigLoader.load
          @root_path = Molecules::ConfigLoader.find_root
          @resolver = Molecules::ReleaseResolver.new(@root_path)
          @task_loader = Molecules::TaskLoader.new(@root_path)
        end

        # Show active release(s)
        # @return [Array<Hash>] Active releases
        def show_active
          @resolver.find_active
        end

        # Show specific release
        # @param identifier [String] Release identifier
        # @return [Hash, nil] Release info
        def show_release(identifier)
          @resolver.find_release(identifier)
        end

        # List all releases
        # @param filter [String] Filter by status (backlog, active, done)
        # @return [Array<Hash>] Filtered releases
        def list_releases(filter = nil)
          releases = @resolver.find_all

          if filter
            releases.select { |r| r[:status] == filter }
          else
            releases
          end
        end

        # Create new release in backlog
        # @param name [String] Release name (e.g., v.0.10.0)
        # @return [Hash] Result with :success and :message
        def create_release(name)
          # Validate name format
          unless name.match?(/^v\.\d+\.\d+\.\d+/)
            return { success: false, message: "Invalid release name format. Use v.X.Y.Z" }
          end

          # Check if already exists
          if @resolver.exists?(name)
            return { success: false, message: "Release #{name} already exists" }
          end

          # Create in backlog
          release_path = Atoms::PathBuilder.build_release_path(@root_path, name, "backlog")

          begin
            FileUtils.mkdir_p(release_path)
            FileUtils.mkdir_p(File.join(release_path, "t"))
            FileUtils.mkdir_p(File.join(release_path, "ideas"))
            FileUtils.mkdir_p(File.join(release_path, "docs"))

            # Create release.md file
            release_file = File.join(release_path, "release.md")
            File.write(release_file, generate_release_template(name))

            { success: true, message: "Created release #{name} in backlog", path: release_path }
          rescue StandardError => e
            { success: false, message: "Failed to create release: #{e.message}" }
          end
        end

        # Promote release from backlog to active
        # @param name [String] Release name or nil for next in backlog
        # @return [Hash] Result with :success and :message
        def promote_release(name = nil)
          if name.nil?
            # Find next release in backlog
            backlog = list_releases("backlog")
            if backlog.empty?
              return { success: false, message: "No releases in backlog to promote" }
            end
            # Sort by version and take the lowest
            release = backlog.min_by { |r| r[:version] }
            name = release[:name]
          else
            # Find specific release
            release = @resolver.find_release(name)
            unless release
              return { success: false, message: "Release #{name} not found" }
            end
            unless release[:status] == "backlog"
              return { success: false, message: "Release #{name} is not in backlog (status: #{release[:status]})" }
            end
          end

          # Move from backlog to active
          old_path = Atoms::PathBuilder.build_release_path(@root_path, name, "backlog")
          new_path = Atoms::PathBuilder.build_release_path(@root_path, name, "active")

          begin
            FileUtils.mv(old_path, new_path)
            { success: true, message: "Promoted #{name}: backlog → active", path: new_path }
          rescue StandardError => e
            { success: false, message: "Failed to promote release: #{e.message}" }
          end
        end

        # Demote release from active to done (or backlog)
        # @param name [String] Release name or nil for current
        # @param to [String] Target status (done or backlog)
        # @return [Hash] Result with :success and :message
        def demote_release(name = nil, to: "done")
          if name.nil?
            # Use primary active release
            primary = @resolver.find_primary_active
            unless primary
              return { success: false, message: "No active release to demote" }
            end
            name = primary[:name]
          else
            # Find specific release
            release = @resolver.find_release(name)
            unless release
              return { success: false, message: "Release #{name} not found" }
            end
            unless release[:status] == "active"
              return { success: false, message: "Release #{name} is not active (status: #{release[:status]})" }
            end
          end

          # Validate before demotion
          validation = validate_release(name)
          if !validation[:valid] && to == "done"
            return {
              success: false,
              message: "Release #{name} has validation issues:\n#{validation[:issues].join("\n")}"
            }
          end

          # Move release
          old_path = Atoms::PathBuilder.build_release_path(@root_path, name, "active")
          new_path = Atoms::PathBuilder.build_release_path(@root_path, name, to)

          begin
            # Ensure target directory exists
            target_dir = File.dirname(new_path)
            FileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)

            FileUtils.mv(old_path, new_path)
            { success: true, message: "Demoted #{name}: active → #{to}", path: new_path }
          rescue StandardError => e
            { success: false, message: "Failed to demote release: #{e.message}" }
          end
        end

        # Validate release for completion
        # @param name [String] Release name or nil for current
        # @return [Hash] Validation result
        def validate_release(name = nil)
          if name.nil?
            primary = @resolver.find_primary_active
            return { valid: false, issues: ["No active release"] } unless primary
            name = primary[:name]
          end

          release = @resolver.find_release(name)
          return { valid: false, issues: ["Release not found"] } unless release

          issues = []
          stats = release[:statistics]

          # Check for in-progress tasks
          if stats[:statuses]["in-progress"] && stats[:statuses]["in-progress"] > 0
            issues << "#{stats[:statuses]['in-progress']} task(s) still in progress"
          end

          # Check for high-priority pending tasks
          pending_tasks = @task_loader.load_tasks_from_context(release[:path])
          high_priority_pending = pending_tasks.select do |task|
            task[:status] == "pending" && task[:priority] == "high"
          end

          unless high_priority_pending.empty?
            issues << "#{high_priority_pending.size} high-priority task(s) pending"
          end

          # Warning for any pending tasks
          total_pending = stats[:statuses]["pending"] || 0
          if total_pending > 0
            issues << "#{total_pending} pending task(s) remain"
          end

          {
            valid: issues.empty?,
            issues: issues,
            statistics: stats
          }
        end

        # Generate changelog for release
        # @param name [String] Release name or nil for current
        # @return [String] Changelog content
        def generate_changelog(name = nil)
          if name.nil?
            primary = @resolver.find_primary_active
            return "No active release" unless primary
            name = primary[:name]
          end

          release = @resolver.find_release(name)
          return "Release not found" unless release

          tasks = @task_loader.load_tasks_from_context(release[:path])

          changelog = "## #{name}\n\n"

          # Group tasks by status
          done_tasks = tasks.select { |t| t[:status] == "done" }
          pending_tasks = tasks.select { |t| t[:status] == "pending" }
          blocked_tasks = tasks.select { |t| t[:status] == "blocked" }

          unless done_tasks.empty?
            changelog += "### Completed (#{done_tasks.size} tasks)\n"
            done_tasks.each do |task|
              changelog += "- #{task[:title]}\n"
            end
            changelog += "\n"
          end

          unless pending_tasks.empty?
            changelog += "### Pending (#{pending_tasks.size} tasks)\n"
            pending_tasks.each do |task|
              changelog += "- #{task[:title]}\n"
            end
            changelog += "\n"
          end

          unless blocked_tasks.empty?
            changelog += "### Blocked (#{blocked_tasks.size} tasks)\n"
            blocked_tasks.each do |task|
              changelog += "- #{task[:title]}\n"
            end
            changelog += "\n"
          end

          changelog
        end

        private

        def generate_release_template(name)
          <<~TEMPLATE
            # Release: #{name}

            ## Overview

            *Description of this release*

            ## Goals

            - [ ] Goal 1
            - [ ] Goal 2
            - [ ] Goal 3

            ## Status

            - **Created**: #{Time.now.strftime('%Y-%m-%d')}
            - **Status**: backlog
            - **Target Date**: TBD

            ## Notes

            *Additional notes about this release*
          TEMPLATE
        end
      end
    end
  end
end