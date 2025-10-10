# frozen_string_literal: true

require_relative "../molecules/release_resolver"

module Ace
  module Taskflow
    module Molecules
      # Validates release structure and metadata
      class ReleaseValidator
        def initialize(root_path = nil)
          @root_path = root_path || find_taskflow_root
          @release_resolver = ReleaseResolver.new(@root_path)
        end

        # Validate all releases
        # @return [Hash] Validation result with :valid, :issues, :stats
        def validate_all
          issues = []
          stats = {
            active: 0,
            backlog: 0,
            done: 0,
            total: 0,
            with_errors: 0
          }

          releases = @release_resolver.find_all

          releases.each do |release|
            validate_release(release, issues, stats)
          end

          # Check for version conflicts
          check_version_conflicts(releases, issues)

          # Check release progression
          check_release_progression(releases, issues)

          {
            valid: issues.none? { |i| i[:type] == :error },
            issues: issues,
            stats: stats
          }
        end

        # Validate a specific release
        # @param release [Hash] Release info from ReleaseResolver
        # @param issues [Array] Issues array to append to
        # @param stats [Hash] Stats hash to update
        def validate_release(release, issues, stats)
          stats[:total] += 1
          stats[release[:status]] += 1 if [:active, :backlog, :done].include?(release[:status])

          # Check version format
          unless release[:name].match?(/^v\.\d+\.\d+\.\d+$/)
            issues << {
              type: :error,
              message: "Invalid release version format: #{release[:name]} (expected v.X.Y.Z)",
              location: release[:path]
            }
            stats[:with_errors] += 1
          end

          # Check release.md file
          release_file = File.join(release[:path], "release.md")
          unless File.exist?(release_file)
            issues << {
              type: :warning,
              message: "Missing release.md file",
              location: release[:path]
            }
          else
            validate_release_file(release_file, release, issues)
          end

          # Check required directories
          validate_release_directories(release[:path], release[:name], issues)

          # Validate status matches location
          validate_status_location(release, issues)
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

        def validate_release_file(file_path, release, issues)
          content = File.read(file_path)

          # Check for basic structure
          unless content.include?("# Release #{release[:name]}")
            issues << {
              type: :info,
              message: "Release file doesn't contain expected header",
              location: file_path
            }
          end

          # Check for standard sections
          expected_sections = ["## Goals", "## Tasks", "## Timeline"]
          expected_sections.each do |section|
            unless content.include?(section)
              issues << {
                type: :info,
                message: "Missing recommended section: #{section}",
                location: file_path
              }
            end
          end
        end

        def validate_release_directories(release_path, release_name, issues)
          # Required directories
          required_dirs = {
            "t" => "tasks directory",
            "ideas" => "ideas directory"
          }

          required_dirs.each do |dir, description|
            dir_path = File.join(release_path, dir)
            unless Dir.exist?(dir_path)
              issues << {
                type: :warning,
                message: "Missing #{description}: #{dir}/",
                location: release_path
              }
            end
          end

          # Optional but recommended directories
          optional_dirs = {
            "docs" => "documentation directory",
            "retros" => "retrospectives directory"
          }

          optional_dirs.each do |dir, description|
            dir_path = File.join(release_path, dir)
            unless Dir.exist?(dir_path)
              issues << {
                type: :info,
                message: "Missing optional #{description}: #{dir}/",
                location: release_path
              }
            end
          end

          # Check for done subdirectory in tasks
          task_done_dir = File.join(release_path, "t", "done")
          unless Dir.exist?(task_done_dir)
            issues << {
              type: :info,
              message: "Missing t/done/ directory for completed tasks",
              location: release_path
            }
          end

          # Check for done subdirectory in ideas
          idea_done_dir = File.join(release_path, "ideas", "done")
          unless Dir.exist?(idea_done_dir)
            issues << {
              type: :info,
              message: "Missing ideas/done/ directory for completed ideas",
              location: release_path
            }
          end
        end

        def validate_status_location(release, issues)
          actual_location = determine_actual_location(release[:path])

          case release[:status]
          when :active
            unless actual_location == :active
              issues << {
                type: :error,
                message: "Active release #{release[:name]} is in #{actual_location} directory",
                location: release[:path]
              }
            end
          when :backlog
            unless actual_location == :backlog
              issues << {
                type: :error,
                message: "Backlog release #{release[:name]} is in #{actual_location} directory",
                location: release[:path]
              }
            end
          when :done
            unless actual_location == :done
              issues << {
                type: :warning,
                message: "Done release #{release[:name]} is in #{actual_location} directory",
                location: release[:path]
              }
            end
          end
        end

        def determine_actual_location(path)
          if path.include?("/backlog/")
            :backlog
          elsif path.include?("/done/")
            :done
          else
            :active
          end
        end

        def check_version_conflicts(releases, issues)
          # Group releases by version
          versions = {}
          releases.each do |release|
            version = release[:name]
            versions[version] ||= []
            versions[version] << release
          end

          # Check for duplicates
          versions.each do |version, version_releases|
            if version_releases.size > 1
              locations = version_releases.map { |r| r[:path] }
              issues << {
                type: :error,
                message: "Duplicate release version: #{version}",
                locations: locations
              }
            end
          end
        end

        def check_release_progression(releases, issues)
          active_releases = releases.select { |r| r[:status] == :active }

          # Check if there are too many active releases
          if active_releases.size > 3
            issues << {
              type: :warning,
              message: "Too many active releases (#{active_releases.size}). Consider moving some to backlog or done.",
              releases: active_releases.map { |r| r[:name] }
            }
          end

          # Check version progression
          active_versions = active_releases.map { |r| parse_version(r[:name]) }.compact.sort

          if active_versions.size > 1
            # Check for version gaps
            active_versions.each_cons(2) do |v1, v2|
              if version_gap?(v1, v2)
                issues << {
                  type: :info,
                  message: "Version gap between #{format_version(v1)} and #{format_version(v2)}",
                  location: @root_path
                }
              end
            end
          end
        end

        def parse_version(version_string)
          if version_string =~ /^v\.(\d+)\.(\d+)\.(\d+)$/
            [$1.to_i, $2.to_i, $3.to_i]
          else
            nil
          end
        end

        def format_version(version_array)
          "v.#{version_array.join('.')}"
        end

        def version_gap?(v1, v2)
          # Check if there's a significant gap in version numbers
          # Major version gap
          return true if (v2[0] - v1[0]) > 1

          # Minor version gap when major is same
          if v2[0] == v1[0]
            return true if (v2[1] - v1[1]) > 2
          end

          false
        end
      end
    end
  end
end