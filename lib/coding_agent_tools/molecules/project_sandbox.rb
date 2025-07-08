# frozen_string_literal: true

require "pathname"
require_relative "../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    class ProjectSandbox
      attr_reader :project_root

      def initialize(project_root = nil, allowed_patterns = nil, forbidden_patterns = nil)
        @project_root = resolve_project_root(project_root)
        @allowed_patterns = allowed_patterns || default_allowed_patterns
        @forbidden_patterns = forbidden_patterns || default_forbidden_patterns
      end

      def validate_path(path)
        return failure("Path cannot be nil") if path.nil?
        return failure("Path cannot be empty") if path.to_s.strip.empty?

        normalized_path = normalize_path(path)

        # Check if path is within project root
        unless within_project_root?(normalized_path)
          return failure("Path is outside project root: #{path}")
        end

        # Check forbidden patterns
        if matches_forbidden_pattern?(normalized_path)
          return failure("Path matches forbidden pattern: #{path}")
        end

        # Check allowed patterns
        unless matches_allowed_pattern?(normalized_path)
          return failure("Path does not match any allowed pattern: #{path}")
        end

        success(normalized_path)
      end

      def safe_path(path)
        result = validate_path(path)
        raise Error, result[:error] unless result[:success]
        result[:path]
      end

      def within_sandbox?(path)
        validate_path(path)[:success]
      end

      def relative_to_project(path)
        validated_path = safe_path(path)
        # Normalize project root to match the normalized validated_path
        normalized_root = normalize_path(@project_root)
        Pathname.new(validated_path).relative_path_from(Pathname.new(normalized_root)).to_s
      end

      def absolute_path(path)
        if Pathname.new(path).absolute?
          safe_path(path)
        else
          safe_path(File.join(@project_root, path))
        end
      end

      private

      def resolve_project_root(root)
        path = if root
          File.expand_path(root)
        else
          detect_project_root
        end

        # Normalize the path to handle symlinks consistently
        if File.exist?(path)
          File.realpath(path)
        else
          path
        end
      end

      def detect_project_root
        CodingAgentTools::Atoms::ProjectRootDetector.find_project_root(Dir.pwd)
      end

      def normalize_path(path)
        # Expand path and resolve symlinks
        expanded = File.expand_path(path.to_s)

        # Resolve symlinks if path exists
        if File.exist?(expanded)
          File.realpath(expanded)
        else
          expanded
        end
      end

      def within_project_root?(normalized_path)
        project_root_real = File.realpath(@project_root)

        # Handle case where path doesn't exist yet
        normalized_path_real = if !File.exist?(normalized_path)
          normalized_path
        else
          File.realpath(normalized_path)
        end

        # Path must start with project root
        normalized_path_real.start_with?(project_root_real + "/") ||
          normalized_path_real == project_root_real
      end

      def matches_forbidden_pattern?(path)
        project_root_real = File.realpath(@project_root)
        relative_path = path.sub(project_root_real + "/", "")

        @forbidden_patterns.any? do |pattern|
          File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      def matches_allowed_pattern?(path)
        project_root_real = File.realpath(@project_root)
        relative_path = path.sub(project_root_real + "/", "")

        @allowed_patterns.any? do |pattern|
          File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      def default_allowed_patterns
        [
          "**/*.md",
          "**/*.rb",
          "**/*.yml",
          "**/*.yaml",
          "**/*.sh",
          "bin/*",
          "dev-tools/**/*",
          "dev-taskflow/**/*",
          "dev-handbook/**/*",
          ".coding-agent/**/*"
        ]
      end

      def default_forbidden_patterns
        [
          "**/.git/**",
          "**/node_modules/**",
          "**/coverage/**",
          "**/tmp/**",
          "**/*.log",
          "**/.DS_Store",
          "**/Gemfile.lock",
          "**/package-lock.json"
        ]
      end

      def success(path)
        {success: true, path: path}
      end

      def failure(error)
        {success: false, error: error}
      end
    end
  end
end
