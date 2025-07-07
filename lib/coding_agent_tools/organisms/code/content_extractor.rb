# frozen_string_literal: true

require_relative "../../molecules/code/git_diff_extractor"
require_relative "../../molecules/code/file_pattern_extractor"
require_relative "../../models/code/review_target"

module CodingAgentTools
  module Organisms
    module Code
      # Extracts and formats review content
      # This is an organism - it orchestrates molecules for content extraction
      class ContentExtractor
        def initialize
          @diff_extractor = Molecules::Code::GitDiffExtractor.new
          @file_extractor = Molecules::Code::FilePatternExtractor.new
        end

        # Extract content for a target
        # @param target [String] target specification
        # @return [Models::Code::ReviewTarget] extracted target
        def extract_content(target)
          # Determine target type
          if @diff_extractor.git_diff_target?(target)
            extract_git_content(target)
          elsif File.exist?(target) && !File.directory?(target)
            extract_single_file_content(target)
          else
            extract_pattern_content(target)
          end
        end

        # Save extracted content to session directory
        # @param target [Models::Code::ReviewTarget] extracted target
        # @param session_dir [String] session directory path
        # @return [Hash] {success: Boolean, error: String}
        def save_content(target, session_dir)
          case target.type
          when "git_diff"
            save_git_diff(target, session_dir)
          when "single_file", "file_pattern"
            save_file_content(target, session_dir)
          else
            { success: false, error: "Unknown target type: #{target.type}" }
          end
        end

        # Extract and save content in one operation
        # @param target_spec [String] target specification
        # @param session_dir [String] session directory path
        # @return [Models::Code::ReviewTarget] extracted target
        def extract_and_save(target_spec, session_dir)
          target = extract_content(target_spec)
          
          # Save if extraction was successful
          if target.type != "error"
            save_result = save_content(target, session_dir)
            unless save_result[:success]
              # Update target with save error
              target = Models::Code::ReviewTarget.new(
                type: "error",
                target_spec: target_spec,
                resolved_paths: [],
                content_type: "none",
                size_info: { error: save_result[:error] }
              )
            end
          end
          
          target
        end

        private

        # Extract git-based content
        # @param target [String] target specification
        # @return [Models::Code::ReviewTarget] extracted target
        def extract_git_content(target)
          result = @diff_extractor.extract_diff(target)
          
          if result[:success]
            Models::Code::ReviewTarget.new(
              type: "git_diff",
              target_spec: target,
              resolved_paths: [],  # Git diffs don't have file paths
              content_type: "diff",
              size_info: {
                lines: result[:metadata][:line_count],
                words: result[:metadata][:word_count],
                files: result[:metadata][:files_changed],
                additions: result[:metadata][:additions],
                deletions: result[:metadata][:deletions]
              }
            )
          else
            Models::Code::ReviewTarget.new(
              type: "error",
              target_spec: target,
              resolved_paths: [],
              content_type: "none",
              size_info: { error: result[:error] }
            )
          end
        end

        # Extract single file content
        # @param target [String] file path
        # @return [Models::Code::ReviewTarget] extracted target
        def extract_single_file_content(target)
          result = @file_extractor.extract_files(target)
          
          if result[:success]
            Models::Code::ReviewTarget.new(
              type: "single_file",
              target_spec: target,
              resolved_paths: result[:file_list],
              content_type: "xml",
              size_info: {
                files: 1,
                lines: count_lines_in_file(target)
              }
            )
          else
            Models::Code::ReviewTarget.new(
              type: "error",
              target_spec: target,
              resolved_paths: [],
              content_type: "none",
              size_info: { error: result[:error] }
            )
          end
        end

        # Extract pattern-based content
        # @param target [String] file pattern
        # @return [Models::Code::ReviewTarget] extracted target
        def extract_pattern_content(target)
          result = @file_extractor.extract_files(target)
          
          if result[:success]
            Models::Code::ReviewTarget.new(
              type: "file_pattern",
              target_spec: target,
              resolved_paths: result[:file_list],
              content_type: "xml",
              size_info: {
                files: result[:file_list].count,
                lines: count_total_lines(result[:file_list])
              }
            )
          else
            Models::Code::ReviewTarget.new(
              type: "error",
              target_spec: target,
              resolved_paths: [],
              content_type: "none",
              size_info: { error: result[:error] }
            )
          end
        end

        # Save git diff content
        # @param target [Models::Code::ReviewTarget] target with content
        # @param session_dir [String] session directory
        # @return [Hash] save result
        def save_git_diff(target, session_dir)
          @diff_extractor.extract_and_save(target.target_spec, session_dir)
        end

        # Save file content
        # @param target [Models::Code::ReviewTarget] target with content
        # @param session_dir [String] session directory
        # @return [Hash] save result
        def save_file_content(target, session_dir)
          @file_extractor.extract_and_save(target.target_spec, session_dir)
        end

        # Count lines in a file
        # @param file_path [String] file path
        # @return [Integer] line count
        def count_lines_in_file(file_path)
          File.readlines(file_path).count
        rescue
          0
        end

        # Count total lines in multiple files
        # @param file_paths [Array<String>] file paths
        # @return [Integer] total line count
        def count_total_lines(file_paths)
          file_paths.sum { |path| count_lines_in_file(path) }
        end
      end
    end
  end
end