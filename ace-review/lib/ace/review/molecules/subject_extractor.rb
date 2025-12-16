# frozen_string_literal: true

require "yaml"
require "open3"
require "timeout"
require_relative "../errors"

module Ace
  module Review
    module Molecules
      # Extracts review subject (code to review) from various sources
      # Delegates to ace-context for unified content aggregation
      #
      # == Dual Extraction Paths
      #
      # This class supports two code paths for typed subjects (pr:, diff:, files:, task:):
      #
      # 1. **Direct extraction** via {#extract}:
      #    - Parses typed subject → builds ace-context config → calls ace-context → returns content
      #    - Used when caller needs immediate content (e.g., legacy flows)
      #    - Example: `extract("diff:HEAD~3")` → returns diff content string
      #
      # 2. **Config passthrough** via {#parse_typed_subject_config}:
      #    - Parses typed subject → returns config hash for caller to pass to ace-context later
      #    - Used by ReviewManager for optimized flow (avoids double extraction)
      #    - Example: `parse_typed_subject_config("pr:77")` → returns `{"context"=>{"pr"=>"77"}}`
      #
      # The config passthrough path is preferred for performance - it allows ReviewManager to
      # pass the config directly to ace-context when generating prompts, avoiding the overhead
      # of extracting content only to save it to a file and re-read it.
      #
      class SubjectExtractor
        def initialize
          @git = Ace::Context::Atoms::GitExtractor
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

        # Parse typed subject string and return ace-context config
        # Does NOT extract content - returns config for direct use with ace-context
        # @param input [String] typed subject like "pr:77", "files:*.rb", "diff:HEAD~3"
        # @return [Hash, nil] ace-context config hash or nil if not a typed subject
        def parse_typed_subject_config(input)
          return nil unless input.is_a?(String)

          parse_typed_subject(input)
        end

        private

        def extract_from_string(input)
          # Try typed subject first (new)
          if (typed_config = parse_typed_subject(input))
            return use_ace_context(typed_config)
          end

          # Try to parse as YAML first
          begin
            parsed = YAML.safe_load(input)
            return extract_from_hash(parsed) if parsed.is_a?(Hash)
          rescue Psych::SyntaxError
            # Continue with string processing
          end

          # Handle special keywords (updated to use ace-context)
          case input.downcase
          when "staged"
            return use_ace_context({ "diffs" => ["--staged"] })
          when "working", "unstaged"
            return use_ace_context({ "diffs" => [""] })
          when "pr", "pull-request"
            tracking = @git.tracking_branch
            range = tracking ? "#{tracking}...HEAD" : "origin/main...HEAD"
            return use_ace_context({ "diffs" => [range] })
          end

          # Check if it's a git range
          if looks_like_git_range?(input)
            return use_ace_context({ "diffs" => [input] })
          end

          # Check if it's a file pattern
          if input.include?("*") || input.include?("/")
            return use_ace_context({ "files" => [input] })
          end

          # Default to git diff
          use_ace_context({ "diffs" => [input] })
        end

        def extract_from_hash(config)
          # Pass configuration directly to ace-context without transformation
          use_ace_context(config)
        end

        def use_ace_context(config)
          # Use ace-context for unified content extraction
          # Pass config directly as inline YAML - ace-context's load_inline_yaml
          # supports both flat keys (files, diffs, commands, pr) and nested
          # structure (context: { diffs: [...] }) for typed subject compatibility
          context_md = "#{YAML.dump(config).strip}\n---\n\n"

          result = Ace::Context.load_auto(context_md, format: 'markdown')
          result.content
        rescue StandardError => e
          warn "ace-context extraction failed: #{e.message}" if Ace::Review.debug?
          ""
        end

        def parse_typed_subject(input)
          case input
          when /^diff:(.+)$/
            { "context" => { "diffs" => [::Regexp.last_match(1)] } }
          when /^diff:$/
            raise ArgumentError, "Empty value for diff: subject. Usage: diff:RANGE (e.g., diff:HEAD~3...HEAD)"
          when /^pr:(.+)$/
            pr_refs = ::Regexp.last_match(1).split(",").map(&:strip).reject(&:empty?).uniq
            if pr_refs.empty?
              raise ArgumentError, "No valid PR references provided. Usage: pr:NUMBER (e.g., pr:123 or pr:123,456)"
            end
            # Validate that all PR references are numeric
            invalid_refs = pr_refs.reject { |ref| ref =~ /\A\d+\z/ }
            unless invalid_refs.empty?
              raise ArgumentError, "PR references must be numeric: #{invalid_refs.join(', ')}. Usage: pr:123 or pr:123,456"
            end
            { "context" => { "pr" => pr_refs } }
          when /^pr:$/
            raise ArgumentError, "Empty value for pr: subject. Usage: pr:NUMBER (e.g., pr:123)"
          when /^files:(.+)$/
            { "context" => { "files" => ::Regexp.last_match(1).split(",").map(&:strip) } }
          when /^files:$/
            raise ArgumentError, "Empty value for files: subject. Usage: files:PATTERN (e.g., files:src/**/*.rb)"
          when /^task:(.+)$/
            resolve_task_subject(::Regexp.last_match(1))
          when /^task:$/
            raise ArgumentError, "Empty value for task: subject. Usage: task:REF (e.g., task:145)"
          else
            nil  # Fall through to existing parsing
          end
        end

        # Default timeout for ace-taskflow subprocess (in seconds)
        TASKFLOW_TIMEOUT = 10

        def resolve_task_subject(ref)
          # Validate ref format to prevent injection (alphanumeric, dots, dashes, plus only)
          # Plus is needed for qualified task refs like v.0.9.0+task.145
          unless ref.match?(/\A[\w.\-+]+\z/)
            raise ArgumentError, "Invalid task reference format: #{ref}"
          end

          # Use Open3 with array args for safe subprocess execution
          # Add timeout to prevent hanging on stuck ace-taskflow lookups
          begin
            stdout = nil
            status = nil
            Timeout.timeout(TASKFLOW_TIMEOUT) do
              stdout, _stderr, status = Open3.capture3("ace-taskflow", "task", ref, "--path")
            end
          rescue Errno::ENOENT
            raise Errors::MissingDependencyError.new("ace-taskflow", install_command: "gem install ace-taskflow")
          rescue Timeout::Error
            raise Errors::CommandTimeoutError.new("ace-taskflow task #{ref} --path", TASKFLOW_TIMEOUT)
          end

          unless status.success?
            raise Errors::TaskNotFoundError, ref
          end

          task_path = stdout.strip
          if task_path.empty?
            raise Errors::TaskPathNotFoundError, ref
          end

          # ace-taskflow 'task REF --path' returns the path to the main task file
          # (e.g., .ace-taskflow/v.0.9.0/tasks/145-feature/145.s.md).
          # We use File.dirname to get the task's directory and glob for all
          # solution files (*.s.md) within it - this includes the main task
          # and any subtasks (145.01.s.md, 145.02.s.md, etc.)
          { "context" => { "files" => ["#{File.dirname(task_path)}/**/*.s.md"] } }
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