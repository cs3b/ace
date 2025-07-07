# frozen_string_literal: true

require_relative "../../atoms/code/git_command_executor"
require_relative "../../atoms/code/file_content_reader"

module CodingAgentTools
  module Molecules
    module Code
      # Extracts git diffs for various target types
      # This is a molecule - it composes atoms to extract git diff content
      class GitDiffExtractor
        def initialize
          @git_executor = Atoms::Code::GitCommandExecutor.new
          @file_reader = Atoms::Code::FileContentReader.new
        end

        # Extract diff for a target specification
        # @param target_spec [String] target specification (range, 'staged', etc.)
        # @return [Hash] {content: String, metadata: Hash, success: Boolean, error: String}
        def extract_diff(target_spec)
          # Check if git is available
          unless @git_executor.available?
            return {
              content: nil,
              metadata: {},
              success: false,
              error: "Git is not available"
            }
          end
          
          # Execute diff command
          result = @git_executor.diff(target_spec)
          
          if result[:success]
            metadata = build_diff_metadata(target_spec, result[:output])
            {
              content: result[:output],
              metadata: metadata,
              success: true,
              error: nil
            }
          else
            {
              content: nil,
              metadata: {},
              success: false,
              error: result[:error]
            }
          end
        end

        # Save diff to file with metadata
        # @param target_spec [String] target specification
        # @param session_dir [String] session directory path
        # @return [Hash] {diff_file: String, meta_file: String, success: Boolean, error: String}
        def extract_and_save(target_spec, session_dir)
          # Extract diff
          result = extract_diff(target_spec)
          return result unless result[:success]
          
          # Save diff file
          diff_file = File.join(session_dir, "input.diff")
          meta_file = File.join(session_dir, "input.meta")
          
          begin
            File.write(diff_file, result[:content])
            
            # Write metadata
            meta_content = <<~META
              # Diff Metadata
              target: #{target_spec}
              type: git_diff
              size: #{result[:metadata][:line_count]} lines
            META
            File.write(meta_file, meta_content)
            
            {
              diff_file: diff_file,
              meta_file: meta_file,
              success: true,
              error: nil
            }
          rescue => e
            {
              diff_file: nil,
              meta_file: nil,
              success: false,
              error: "Failed to save diff: #{e.message}"
            }
          end
        end

        # Check if target is a git diff target
        # @param target [String] target specification
        # @return [Boolean] true if target is git-based
        def git_diff_target?(target)
          return true if %w[staged unstaged working].include?(target)
          return true if target.include?("..")
          return true if target =~ /^[a-f0-9]{7,40}$/  # Git SHA
          false
        end

        private

        # Build metadata for diff
        # @param target_spec [String] target specification
        # @param content [String] diff content
        # @return [Hash] diff metadata
        def build_diff_metadata(target_spec, content)
          lines = content.lines
          {
            target: target_spec,
            type: "git_diff",
            line_count: lines.count,
            word_count: content.split(/\s+/).count,
            files_changed: count_files_in_diff(lines),
            additions: count_additions(lines),
            deletions: count_deletions(lines),
            empty: content.strip.empty?
          }
        end

        # Count files changed in diff
        # @param lines [Array<String>] diff lines
        # @return [Integer] number of files
        def count_files_in_diff(lines)
          lines.count { |line| line.start_with?("diff --git") }
        end

        # Count additions in diff
        # @param lines [Array<String>] diff lines
        # @return [Integer] number of additions
        def count_additions(lines)
          lines.count { |line| line.start_with?("+") && !line.start_with?("+++") }
        end

        # Count deletions in diff
        # @param lines [Array<String>] diff lines
        # @return [Integer] number of deletions
        def count_deletions(lines)
          lines.count { |line| line.start_with?("-") && !line.start_with?("---") }
        end
      end
    end
  end
end