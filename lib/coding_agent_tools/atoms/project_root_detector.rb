# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    class ProjectRootDetector
      class << self
        def find_project_root(start_path = nil)
          start_path ||= Dir.pwd

          # Check cache first
          cache_key = "#{start_path}:#{ENV["PROJECT_ROOT"]}"
          return @cached_root if @cached_root && @cached_cache_key == cache_key

          @cached_cache_key = cache_key
          @cached_root = detect_root(start_path)
        end

        def reset_cache!
          @cached_root = nil
          @cached_cache_key = nil
        end

        attr_writer :debug_mode

        def debug_mode
          @debug_mode ||= false
        end

        private

        def detect_root(start_path)
          # 1. Highest priority: PROJECT_ROOT environment variable
          if ENV["PROJECT_ROOT"]
            debug_log "Checking PROJECT_ROOT environment variable: #{ENV["PROJECT_ROOT"]}"
            env_root = File.expand_path(ENV["PROJECT_ROOT"])
            if validate_project_root(env_root)
              debug_log "Using PROJECT_ROOT from environment: #{env_root}"
              return env_root
            else
              debug_log "WARNING: PROJECT_ROOT environment variable points to invalid path: #{env_root}"
            end
          end

          # 2. Special case: detect dev-* directories and suggest parent
          current_path = File.expand_path(start_path)
          special_dir_root = check_special_directories(current_path)
          if special_dir_root
            debug_log "Found project root via special directory detection: #{special_dir_root}"
            return special_dir_root
          end

          # 3. Standard marker-based upward traversal
          max_iterations = 20
          current_path = File.expand_path(start_path)

          max_iterations.times do
            debug_log "Checking path: #{current_path}"

            if root_marker_exists?(current_path)
              debug_log "Found project root: #{current_path}"
              return current_path
            end

            parent_path = File.dirname(current_path)
            break if parent_path == current_path

            current_path = parent_path
          end

          # Enhanced error message with PROJECT_ROOT suggestion
          raise Error, "Could not detect project root from #{start_path}. " \
                       "Searched #{max_iterations} levels up. " \
                       "Try setting PROJECT_ROOT environment variable to your project's root directory, " \
                       "or ensure you're running from within the tools-meta project."
        end

        def root_marker_exists?(path)
          PRIMARY_MARKERS.any? { |marker| marker_exists_in_path?(path, marker) } ||
            SECONDARY_MARKERS.any? { |marker| marker_exists_in_path?(path, marker) } ||
            gemspec_exists_in_path?(path) ||
            TERTIARY_MARKERS.any? { |marker| marker_exists_in_path?(path, marker) }
        end

        def marker_exists_in_path?(path, marker)
          marker_path = File.join(path, marker)
          exists = File.exist?(marker_path)
          debug_log "  Checking #{marker}: #{exists ? "FOUND" : "not found"} at #{marker_path}"
          exists
        end

        def gemspec_exists_in_path?(path)
          gemspec_files = Dir.glob(File.join(path, "*.gemspec"))
          exists = !gemspec_files.empty?
          debug_log "  Checking *.gemspec: #{exists ? "FOUND (#{gemspec_files.first})" : "not found"} in #{path}"
          exists
        end

        def validate_project_root(path)
          return false unless File.directory?(path)

          # Check if it has any of our expected markers
          if root_marker_exists?(path)
            return true
          end

          # Or contains the expected multi-repo structure (at least 2 dev-* directories)
          dev_dirs_present = DEV_DIRECTORIES.count { |dir| File.directory?(File.join(path, dir)) }
          dev_dirs_present >= 2
        end

        def check_special_directories(current_path)
          # Check if we're in or under a dev-* directory
          path_parts = current_path.split(File::SEPARATOR)

          dev_dir_index = path_parts.rindex { |part| DEV_DIRECTORIES.include?(part) }
          return nil unless dev_dir_index

          # Get the parent directory of the dev-* directory
          parent_path = File.join(*path_parts[0...dev_dir_index])
          parent_path = "/" if parent_path.empty?

          debug_log "Found dev-* directory '#{path_parts[dev_dir_index]}', checking parent: #{parent_path}"

          # Validate that the parent is actually a project root
          if validate_project_root(parent_path)
            parent_path
          else
            debug_log "Parent directory #{parent_path} is not a valid project root"
            nil
          end
        end

        def debug_log(message)
          puts "[ProjectRootDetector] #{message}" if debug_mode
        end

        PRIMARY_MARKERS = [".git"].freeze
        SECONDARY_MARKERS = ["Gemfile"].freeze
        TERTIARY_MARKERS = [".ruby-version", ".tools-meta"].freeze
        DEV_DIRECTORIES = ["dev-handbook", "dev-tools", "dev-taskflow"].freeze
      end
    end
  end
end
