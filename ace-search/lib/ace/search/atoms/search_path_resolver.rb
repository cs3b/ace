# frozen_string_literal: true

require "ace/support/fs"

module Ace
  module Search
    module Atoms
      # Resolve search path using 4-step priority algorithm
      #
      # Priority order:
      # 1. Explicit path argument (if provided)
      # 2. PROJECT_ROOT_PATH environment variable
      # 3. Project root detection via ProjectRootFinder
      # 4. Fallback to current directory
      class SearchPathResolver
        # Resolve search path with 4-step priority
        #
        # @param explicit_path [String, nil] Optional explicit path argument
        # @return [String] Resolved absolute or relative path
        def self.resolve(explicit_path = nil)
          new.resolve(explicit_path)
        end

        # Resolve search path with 4-step priority
        #
        # @param explicit_path [String, nil] Optional explicit path argument
        # @return [String] Resolved absolute or relative path
        def resolve(explicit_path = nil)
          # Step 1: Use explicit path if provided (and not whitespace-only)
          return explicit_path if explicit_path && !explicit_path.strip.empty?

          # Step 2: Check PROJECT_ROOT_PATH environment variable
          project_root_env = env_project_root
          if project_root_env && !project_root_env.empty?
            # We validate the ENV var path to prevent a misconfigured environment
            # from causing silent failures. We then fall back gracefully.
            # (Explicit paths are trusted and not validated here)
            return project_root_env if valid_path?(project_root_env)
          end

          # Step 3: Detect project root using ProjectRootFinder
          project_root = find_project_root
          return project_root if project_root

          # Step 4: Fallback to current directory
          "."
        end

        protected

        # Get PROJECT_ROOT_PATH environment variable
        # Extracted to protected method for testing
        #
        # @return [String, nil] Environment variable value
        def env_project_root
          ENV["PROJECT_ROOT_PATH"]
        end

        # Find project root using ProjectRootFinder
        # Extracted to protected method for testing
        #
        # @return [String, nil] Project root path or nil
        def find_project_root
          finder = Ace::Support::Fs::Molecules::ProjectRootFinder.new
          finder.find
        end

        # Check if path is valid (exists)
        # Extracted to protected method for testing
        #
        # @param path [String] Path to validate
        # @return [Boolean] true if path exists
        def valid_path?(path)
          Dir.exist?(File.expand_path(path))
        end
      end
    end
  end
end
