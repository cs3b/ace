# frozen_string_literal: true

require "yaml"
require "open3"

module Ace
  module Review
    module Molecules
      # Extracts review subject (code to review) from various sources
      class SubjectExtractor
        def initialize
          @git = Atoms::GitExtractor
          @file_reader = Atoms::FileReader
        end

        # Extract subject from configuration
        # @param subject_config [String, Hash] subject configuration
        # @return [String] extracted subject content
        def extract(subject_config)
          return "" unless subject_config

          case subject_config
          when String
            extract_from_string(subject_config)
          when Hash
            extract_from_hash(subject_config)
          else
            ""
          end
        end

        private

        def extract_from_string(input)
          # Try to parse as YAML first
          parsed = YAML.safe_load(input)
          return extract_from_hash(parsed) if parsed.is_a?(Hash)

          # Check if it's a git range
          if looks_like_git_range?(input)
            return extract_git_diff(input)
          end

          # Check if it's a file pattern
          if input.include?("*") || input.include?("/")
            return extract_files(input)
          end

          # Check for special keywords
          case input.downcase
          when "staged"
            @git.staged_diff[:output] || ""
          when "working", "unstaged"
            @git.working_diff[:output] || ""
          when "pr", "pull-request"
            extract_pr_diff
          else
            # Default to git diff
            extract_git_diff(input)
          end
        rescue Psych::SyntaxError
          # If YAML parsing fails, treat as git range
          extract_git_diff(input)
        end

        def extract_from_hash(config)
          parts = []

          # Execute commands
          if config["commands"]
            config["commands"].each do |command|
              result = execute_command(command)
              parts << format_command_output(command, result) if result[:success]
            end
          end

          # Read files
          if config["files"]
            files = config["files"]
            files = [files] unless files.is_a?(Array)

            files.each do |file_pattern|
              content = extract_files(file_pattern)
              parts << content unless content.empty?
            end
          end

          # Git diff
          if config["diff"]
            diff_output = extract_git_diff(config["diff"])
            parts << diff_output unless diff_output.empty?
          end

          parts.join("\n\n" + "=" * 80 + "\n\n")
        end

        def extract_git_diff(range)
          result = @git.git_diff(range)
          return "" unless result[:success]

          <<~OUTPUT
            Git Diff: #{range}
            #{"-" * 40}
            #{result[:output]}
          OUTPUT
        end

        def extract_files(pattern)
          results = @file_reader.read_pattern(pattern)
          return "" if results.empty?

          output = []
          results.each do |path, result|
            next unless result[:success]

            output << <<~FILE
              File: #{path}
              #{"-" * 40}
              #{result[:content]}
            FILE
          end

          output.join("\n\n")
        end

        def extract_pr_diff
          # Try to get diff against tracking branch
          tracking = @git.tracking_branch
          return extract_git_diff("#{tracking}...HEAD") if tracking

          # Fall back to origin/main
          extract_git_diff("origin/main...HEAD")
        end

        def execute_command(command)
          stdout, stderr, status = Open3.capture3(command)

          {
            success: status.success?,
            output: stdout,
            error: stderr
          }
        rescue StandardError => e
          {
            success: false,
            output: "",
            error: e.message
          }
        end

        def format_command_output(command, result)
          <<~OUTPUT
            Command: #{command}
            #{"-" * 40}
            #{result[:output]}
          OUTPUT
        end

        def looks_like_git_range?(input)
          input.include?("..") ||
            input.include?("HEAD") ||
            input.include?("~") ||
            input.include?("^") ||
            input.match?(/^[a-f0-9]{6,40}/)
        end
      end
    end
  end
end