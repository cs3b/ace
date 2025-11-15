# frozen_string_literal: true

require "pathname"

module Ace
  module Taskflow
    module Molecules
      # Validates that idea files follow the proper directory structure
      # All ideas must be within folders inside the ideas/ subdirectory
      # Structure: release/ideas/folder-name/file.md (NOT release/ideas/file.md)
      class IdeaStructureValidator
        # .s.md = simple/standard ideas, .i.md = idea drafts
        IDEA_FILE_PATTERN = /\.(s|i)\.md$/

        def initialize(root_path)
          @root_path = root_path
        end

        # Validate idea structure across all releases
        # @return [Hash] with keys :valid, :misplaced
        #   - valid: Array of properly placed idea files
        #   - misplaced: Array of misplaced idea files with metadata
        def validate_all
          misplaced_ideas = []
          valid_ideas = []

          # Find all potential idea files
          idea_files = find_all_idea_files

          idea_files.each do |file_path|
            if properly_placed?(file_path)
              valid_ideas << file_path
            else
              misplaced_ideas << {
                path: file_path,
                reason: misplacement_reason(file_path),
                suggested_location: suggest_proper_location(file_path)
              }
            end
          end

          {
            valid: valid_ideas,
            misplaced: misplaced_ideas,
            total: idea_files.size
          }
        end

        # Check if a specific path is properly placed
        # @param path [String] The file or directory path to check
        # @return [Boolean] true if properly placed in folder within ideas/ subdirectory
        def properly_placed?(path)
          # Convert to relative path from taskflow root
          begin
            relative_path = Pathname.new(path).relative_path_from(Pathname.new(@root_path)).to_s
          rescue ArgumentError
            # Path is outside root, definitely misplaced
            return false
          end

          # Must be within ideas/ directory
          # Valid paths include:
          # - backlog/ideas/folder/**/*
          # - v.X.Y.Z/ideas/folder/**/*
          # - done/v.X.Y.Z/ideas/folder/**/*
          return false unless relative_path.include?("/ideas/")

          # Must be in a folder within ideas/, not a flat file
          # Path structure: [...]/ideas/folder-name/file.md
          # NOT: [...]/ideas/file.md
          parts = relative_path.split("/")
          ideas_index = parts.index("ideas")
          return false if ideas_index.nil?

          # After "ideas/", must have at least 2 parts (folder + file)
          remaining_parts = parts[(ideas_index + 1)..-1]
          remaining_parts.length >= 2
        end

        private

        def find_all_idea_files
          # Find all markdown files that match idea patterns
          Dir.glob(File.join(@root_path, "**", "*.md")).select do |file|
            idea_file?(file)
          end
        end

        # Check if a file is an idea file (vs task, retro, or other file type)
        def idea_file?(file)
          return false unless file.match?(IDEA_FILE_PATTERN)
          return false if task_file?(file)
          return false if retro_file?(file)
          return false if release_file?(file)
          return false if docs_file_outside_ideas?(file)
          true
        end

        # Check if file is a task file
        def task_file?(file)
          file.include?("/tasks/") || file.match?(/task\.\d+\./)
        end

        # Check if file is a retrospective/reflection file
        def retro_file?(file)
          file.include?("/retro/") || file.match?(/reflection\.s\.md$/)
        end

        # Check if file is a release file
        def release_file?(file)
          file.match?(/release.*\.md$/)
        end

        # Check if file is in docs/ but not in ideas/ subdirectory
        def docs_file_outside_ideas?(file)
          file.include?("/docs/") && !file.include?("/ideas/")
        end

        def misplacement_reason(path)
          relative_path = Pathname.new(path).relative_path_from(Pathname.new(@root_path)).to_s
          parts = relative_path.split("/")

          if relative_path.split("/").size == 2
            "File is at release root level, should be in ideas/folder/ subdirectory"
          elsif !relative_path.include?("/ideas/")
            "File is not within ideas/ subdirectory structure"
          elsif flat_file_in_ideas?(relative_path)
            "File is a flat file in ideas/, should be in ideas/folder/ subdirectory"
          else
            "File location doesn't match expected pattern"
          end
        end

        # Check if path is a flat file directly in ideas/ (not in a folder)
        def flat_file_in_ideas?(relative_path)
          return false unless relative_path.include?("/ideas/")

          parts = relative_path.split("/")
          ideas_index = parts.index("ideas")
          return false if ideas_index.nil?

          # If only 2 parts after ideas/ (ideas/file.md), it's a flat file
          remaining_parts = parts[(ideas_index + 1)..-1]
          remaining_parts.length == 1
        end

        def suggest_proper_location(path)
          relative_path = Pathname.new(path).relative_path_from(Pathname.new(@root_path)).to_s
          parts = relative_path.split("/")
          filename = parts.pop

          # The remaining parts form the directory where the file was found
          # For nested structures like done/v.0.1.0/file.md, we preserve all parts
          directory_parts = parts

          # Generate folder name from filename
          folder_name = generate_folder_name(filename)

          # Check if "ideas" is already in the path
          if directory_parts.include?("ideas")
            # File is already in ideas/ directory (flat file case)
            # Suggestion: just add the folder within existing ideas/
            File.join(@root_path, *directory_parts, folder_name, filename)
          else
            # File is outside ideas/ directory
            # Suggestion: add ideas/ then folder
            File.join(@root_path, *directory_parts, "ideas", folder_name, filename)
          end
        end

        # Generate a folder name from a filename
        # Converts "my-idea.s.md" or "20251115-1200-my-idea.s.md" to "my-idea"
        def generate_folder_name(filename)
          # Remove extension
          basename = filename.sub(/\.(s|i)\.md$/, "")

          # Remove timestamp prefix if present (YYYYMMDD-HHMM- or YYYYMMDD-HHMMSS-)
          basename = basename.sub(/^\d{8}-\d{4,6}-/, "")

          # If basename is only a timestamp (YYYYMMDD-HHMM or YYYYMMDD-HHMMSS), use "idea"
          if basename.match?(/^\d{8}-\d{4,6}$/)
            return "idea"
          end

          # If basename is empty after removing timestamp, use "idea" as default
          basename.empty? ? "idea" : basename
        end
      end
    end
  end
end
