# frozen_string_literal: true

require "yaml"
require "open3"
require "timeout"
require 'ace/support/config'
require "ace/core/atoms/process_terminator" # Keep from ace-support-core for process cleanup
require "ace/git"
require_relative "../errors"

module Ace
  module Review
    module Molecules
      # Parses review subjects and returns ace-bundle configuration
      # Delegates actual content extraction to ace-bundle
      #
      # == Config Passthrough API
      #
      # The primary API returns ace-bundle config hashes that ReviewManager
      # passes directly to ace-bundle via user.context.md:
      #
      # - {#parse_typed_subject_config} - Single typed subject (pr:, diff:, files:, task:)
      # - {#merge_typed_subject_configs} - Multiple subjects merged into one config
      #
      # This avoids extracting content only to save it to a file and re-read it.
      #
      class SubjectExtractor
        # @param options [Hash] Configuration options
        # @option options [Integer] :taskflow_timeout Timeout for ace-task subprocess (default: 10s)
        def initialize(options = {})
          @taskflow_timeout = options[:taskflow_timeout] || TASKFLOW_TIMEOUT
        end

      # Extract subject from configuration
        # @param subject_config [String, Hash] subject configuration
        # @return [String] extracted subject content
        # @note Prefer parse_typed_subject_config or merge_typed_subject_configs for new code
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

        # Parse typed subject string and return ace-bundle config
        # Does NOT extract content - returns config for direct use with ace-bundle
        # @param input [String] typed subject like "pr:77", "files:*.rb", "diff:HEAD~3"
        # @return [Hash, nil] ace-bundle config hash or nil if not a typed subject
        def parse_typed_subject_config(input)
          return nil unless input.is_a?(String)

          parse_typed_subject(input)
        end

        # Merge multiple subjects into unified ace-bundle config
        # Does NOT extract content - returns merged config for direct use with ace-bundle
        # Uses Config.merge() with :coerce_union strategy for consistent merge behavior
        # @param subjects [Array<String, Hash>] array of subject configurations
        # @return [Hash, nil] merged ace-bundle config hash or nil if empty
        def merge_typed_subject_configs(subjects)
          return nil unless subjects.is_a?(Array) && subjects.any?

          # Use Config objects with :coerce_union strategy to progressively merge subjects
          # This enables future per-key merge strategies via _merge directive
          initial_config = Ace::Support::Config::Models::Config.new({}, merge_strategy: :coerce_union)

          merged_config = subjects.reduce(initial_config) do |acc, subject|
            config_hash = resolve_single_subject(subject)
            acc.merge(config_hash)
          end

          merged_config.empty? ? nil : merged_config.to_h
        end

        private

        # Deep merge configs with array concatenation, dedup, and recursive hash merging
        # Uses Config.merge() with :coerce_union strategy for consistent merge behavior
        #
        # @param base [Hash] base configuration hash
        # @param overlay [Hash] overlay configuration hash
        # @return [Hash] merged configuration (new hash, does not mutate inputs)
        def deep_merge_arrays(base, overlay)
          Ace::Support::Config::Models::Config.new(base, merge_strategy: :coerce_union)
            .merge(overlay)
            .to_h
        end

        # Resolve a single subject to ace-bundle config
        # @param subject [String, Hash] single subject configuration
        # @return [Hash] ace-bundle config hash
        def resolve_single_subject(subject)
          case subject
          when String
          parse_typed_subject(subject) || parse_keyword_or_pattern(subject)
        when Hash
          subject
        else
            {}
          end
        end

        def extract_from_string(input)
          # Try typed subject first (new)
          if (typed_config = parse_typed_subject(input))
            return use_ace_bundle(typed_config)
          end

          # Try to parse as YAML first
          begin
            parsed = YAML.safe_load(input)
            return extract_from_hash(parsed) if parsed.is_a?(Hash)
          rescue Psych::SyntaxError
            # Continue with string processing
          end

          use_ace_bundle(parse_keyword_or_pattern(input))
        end

        # Parse special keywords and auto-detect patterns
        # @param input [String] input string to parse
        # @return [Hash] ace-bundle config hash
        def parse_keyword_or_pattern(input)
          case input.downcase
          when "staged"
            { "diffs" => ["--staged"] }
          when "working", "unstaged"
            { "diffs" => [""] }
          when "pr", "pull-request"
            tracking = Ace::Git::Molecules::BranchReader.tracking_branch
            range = tracking ? "#{tracking}...HEAD" : "origin/main...HEAD"
            { "diffs" => [range] }
          else
            auto_detect_pattern(input)
          end
        end

        # Auto-detect whether input is a git range or file pattern
        # @param input [String] input string to analyze
        # @return [Hash] ace-bundle config hash
        def auto_detect_pattern(input)
          if looks_like_git_range?(input)
            { "diffs" => [input] }
          elsif input.include?("*") || input.include?("/")
            { "files" => [input] }
          else
            # Default to git diff
            { "diffs" => [input] }
          end
        end

        def extract_from_hash(config)
          # Pass configuration directly to ace-bundle without transformation
          use_ace_bundle(config)
        end

        def use_ace_bundle(config)
          # Use ace-bundle for unified content extraction
          # Pass config directly as inline YAML - ace-bundle's load_inline_yaml
          # supports both flat keys (files, diffs, commands, pr) and nested
          # structure (bundle: { diffs: [...] }) for typed subject compatibility
          context_md = "#{YAML.dump(config).strip}\n---\n\n"

          result = Ace::Bundle.load_auto(context_md, format: 'markdown')
          result.content
        rescue StandardError => e
          warn "ace-bundle extraction failed: #{e.message}" if Ace::Review.debug?
          ""
        end

        def parse_typed_subject(input)
          case input
          when /^diff:(.+)$/
            { "bundle" => { "diffs" => [::Regexp.last_match(1)] } }
          when /^diff:$/
            raise ArgumentError, "Empty value for diff: subject. Usage: diff:RANGE (e.g., diff:HEAD~3...HEAD)"
          when /^pr:(.+)$/
            pr_refs = ::Regexp.last_match(1).split(",").map(&:strip).reject(&:empty?).uniq
            if pr_refs.empty?
              raise ArgumentError, "No valid PR references provided. Usage: pr:REF (e.g., pr:123, pr:owner/repo#456)"
            end
            # Pre-validate PR refs for early error feedback using ace-git's parser
            # Supports: simple numbers (123), qualified refs (owner/repo#456), GitHub URLs
            pr_refs.each do |ref|
              Ace::Git::Atoms::PrIdentifierParser.parse(ref)
            end
            { "bundle" => { "pr" => pr_refs } }
          when /^pr:$/
            raise ArgumentError, "Empty value for pr: subject. Usage: pr:NUMBER (e.g., pr:123)"
          when /^files:(.+)$/
            file_patterns = ::Regexp.last_match(1).split(",").map(&:strip).reject(&:empty?)
            if file_patterns.empty?
              raise ArgumentError, "No valid file patterns provided. Usage: files:PATTERN (e.g., files:src/**/*.rb)"
            end
            { "bundle" => { "files" => file_patterns } }
          when /^files:$/
            raise ArgumentError, "Empty value for files: subject. Usage: files:PATTERN (e.g., files:src/**/*.rb)"
          when /^commit:(.+)$/
            commit_hash = ::Regexp.last_match(1).strip
            if commit_hash.empty?
              raise ArgumentError, "Empty value for commit: subject. Usage: commit:HASH"
            end
            # Normalize to lowercase for validation (git hashes are lowercase)
            commit_hash = commit_hash.downcase
            # Validate hash format: 6-40 hexadecimal characters
            unless commit_hash.match?(/\A[a-f0-9]{6,40}\z/)
              raise ArgumentError, "Invalid commit hash format: '#{commit_hash}'. Must be 6-40 hexadecimal characters."
            end
            { "bundle" => { "diffs" => ["#{commit_hash}~1..#{commit_hash}"] } }
          when /^commit:$/
            raise ArgumentError, "Empty value for commit: subject. Usage: commit:HASH"
          when /^task:(.+)$/
            resolve_task_subject(::Regexp.last_match(1), timeout: @taskflow_timeout)
          when /^task:$/
            raise ArgumentError, "Empty value for task: subject. Usage: task:REF (e.g., task:145)"
          else
            nil  # Fall through to existing parsing
          end
        end

        # Default timeout for ace-task subprocess (in seconds)
        # Can be overridden via options for environments with slow I/O
        TASKFLOW_TIMEOUT = 10

        def resolve_task_subject(ref, timeout: TASKFLOW_TIMEOUT)
          # Validate ref format to prevent injection (alphanumeric, dots, dashes, plus only)
          # Plus is needed for qualified task refs like v.0.9.0+task.145
          unless ref.match?(/\A[\w.\-+]+\z/)
            raise ArgumentError, "Invalid task reference format: #{ref}"
          end

          # Use Open3.popen3 with PID tracking for proper timeout handling
          # Ensures child process is terminated on timeout (prevents orphaned processes)
          stdout, status = execute_taskflow_with_timeout(ref, timeout)

          unless status&.success?
            raise Errors::TaskNotFoundError, ref
          end

          task_path = stdout.strip
          if task_path.empty?
            raise Errors::TaskPathNotFoundError, ref
          end

          # ace-task 'task REF --path' returns the path to the main task file
          # (e.g., .ace-task/v.0.9.0/tasks/145-feature/145.s.md).
          # We use File.dirname to get the task's directory and glob for all
          # solution files (*.s.md) within it - this includes the main task
          # and any subtasks (145.01.s.md, 145.02.s.md, etc.)
          { "bundle" => { "files" => ["#{File.dirname(task_path)}/**/*.s.md"] } }
        end

        # Execute ace-task with timeout and proper process cleanup
        # @param ref [String] Task reference
        # @param timeout_seconds [Integer] Timeout in seconds
        # @return [Array] stdout, status
        # @raise [Errors::MissingDependencyError] if ace-task not installed
        # @raise [Errors::CommandTimeoutError] if command exceeds timeout
        def execute_taskflow_with_timeout(ref, timeout_seconds)
          pid = nil
          stdout_str = ""
          status = nil

          begin
            Timeout.timeout(timeout_seconds) do
              stdout_str, _stderr, status, pid = run_taskflow_command(ref)
            end
          rescue Errno::ENOENT
            raise Errors::MissingDependencyError.new("ace-task", install_command: "gem install ace-task")
          rescue Timeout::Error
            # Ensure child process is terminated on timeout
            Ace::Core::Atoms::ProcessTerminator.terminate(pid) if pid
            raise Errors::CommandTimeoutError.new("ace-task show #{ref} --path", timeout_seconds)
          end

          [stdout_str, status]
        end

        # Run ace-task command - can be stubbed in tests
        # Uses Open3.popen3 with PID tracking for proper process cleanup on timeout
        # @param ref [String] Task reference
        # @return [Array] [stdout, stderr, status, pid]
        def run_taskflow_command(ref)
          stdout_str = ""
          stderr_str = ""
          status = nil
          pid = nil

          Open3.popen3("ace-task", "show", ref, "--path") do |_stdin, stdout, stderr, wait_thr|
            pid = wait_thr.pid
            stdout_str = stdout.read
            stderr_str = stderr.read
            status = wait_thr.value
          end

          [stdout_str, stderr_str, status, pid]
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
