# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "yaml"
require "ace/core/cli/base"

module Ace
  module Git
    module CLI
      module Commands
      # ace-support-cli command for generating diffs
      # Migrated from ace-git-diff
      class Diff < Ace::Support::Cli::Command
        include Ace::Core::CLI::Base

        desc "Generate git diff with filtering (default command)"

        argument :range, required: false, desc: "Git range (e.g., HEAD~5..HEAD, origin/main..HEAD)"

        option :format, type: :string, aliases: ["f"], default: "diff",
                       desc: "Output format: diff, summary, grouped-stats"
        option :since, type: :string, aliases: ["s"],
                      desc: "Changes since date/duration (e.g., '7d', '1 week ago')"
        option :paths, type: :array, aliases: ["p"],
                      desc: "Include only these glob patterns"
        option :exclude, type: :array, aliases: ["e"],
                        desc: "Exclude these glob patterns"
        option :output, type: :string, aliases: ["o"],
                        desc: "Write diff to file instead of stdout"
        option :config, type: :string, aliases: ["c"],
                        desc: "Load config from specific file"
        option :raw, type: :boolean, default: false,
                     desc: "Raw unfiltered output (no exclusions)"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

        def call(range: nil, **options)
          # Verify we're in a git repository
          unless Atoms::CommandExecutor.in_git_repo?
            raise Ace::Git::GitError, "Not a git repository (or any of the parent directories)"
          end

          # Build options hash, including any custom config file
          diff_options = build_options(range, options)

          # Generate diff
          result = if options[:raw]
                     Organisms::DiffOrchestrator.raw(diff_options)
                   else
                     Organisms::DiffOrchestrator.generate(diff_options)
                   end

          # Output result
          output_result(result, options)

          # Return success
          0
        rescue Ace::Git::Error => e
          warn "Error generating diff: #{e.message}"
          1
        end

        private

        def build_options(range, cli_options)
          options = {}

          # Load custom config file if specified
          if cli_options[:config]
            custom_config = load_config_file(cli_options[:config])
            options.merge!(custom_config)
          end

          # Add range if specified
          options[:ranges] = [range] if range

          # Add since if specified
          options[:since] = cli_options[:since] if cli_options[:since]

          # Add path filters
          options[:paths] = cli_options[:paths] if cli_options[:paths]

          # Add exclude patterns (overrides config if specified)
          options[:exclude_patterns] = cli_options[:exclude] if cli_options[:exclude]

          # Add format
          options[:format] = normalized_format(cli_options[:format])

          options
        end

        # Load configuration from a YAML file
        # Handles both flat config and git:-rooted config (per .ace/git/config.yml format)
        # @param config_path [String] Path to config file
        # @return [Hash] Configuration hash
        def load_config_file(config_path)
          unless file_exist?(config_path)
            raise Ace::Git::ConfigError, "Config file not found: #{config_path}"
          end

          config = yaml_safe_load(file_read(config_path))
          config ||= {}

          # Handle git:-rooted config files (standard .ace/git/config.yml format)
          # Extract git section first, then extract diff config from it
          git_config = config["git"] || config[:git] || config
          Molecules::ConfigLoader.extract_diff_config(git_config)
        rescue Psych::SyntaxError => e
          raise Ace::Git::ConfigError, "Invalid YAML in config file: #{e.message}"
        end

        def output_result(result, options)
          content = format_content(result, options)

          # Write to file or stdout
          if options[:output]
            write_to_file(content, options[:output])
          else
            puts content
          end
        end

        def format_content(result, options)
          if result.empty?
            return "(no changes)"
          end

          case normalized_format(options[:format])
          when :summary
            format_summary(result)
          when :grouped_stats
            format_grouped_stats(result, output_path: options[:output])
          else
            result.content
          end
        end

        def write_to_file(content, output_path)
          # Validate path to prevent directory traversal attacks
          validate_output_path(output_path)

          # Create parent directories if needed
          FileUtils.mkdir_p(File.dirname(output_path)) unless File.dirname(output_path) == "."

          # Write content to file
          File.write(output_path, content)

          # Output confirmation to stderr so it doesn't interfere with piping
          warn "Diff written to: #{output_path}"
        end

        # Validate output path to prevent directory traversal attacks
        # Strictly restricts output paths to current working directory or temp directory
        # Uses File.realpath (when available) to resolve symlinks and normalize paths
        # @param path [String] Path to validate
        # @raise [Ace::Git::ConfigError] If path contains traversal sequences or escapes allowed directories
        def validate_output_path(path)
          # Check for null bytes (security)
          if path.include?("\0")
            raise Ace::Git::ConfigError, "Invalid output path: null bytes not allowed"
          end

          # Explicitly reject path traversal sequences
          if path.include?("..")
            raise Ace::Git::ConfigError, "Invalid output path: path traversal not allowed"
          end

          # Resolve the actual path - use realpath for existing paths to resolve symlinks,
          # otherwise use expand_path for new paths (file doesn't exist yet)
          expanded = File.expand_path(path)

          # Get allowed directories, resolving symlinks where possible
          cwd = resolve_real_path(Dir.pwd)
          tmpdir = resolve_real_path(Dir.tmpdir)

          # Strictly enforce that path is within cwd or tmpdir (no exceptions)
          unless expanded.start_with?("#{cwd}/") || expanded == cwd ||
                 expanded.start_with?("#{tmpdir}/") || expanded == tmpdir
            raise Ace::Git::ConfigError,
                  "Invalid output path: must be within working directory or temp directory"
          end
        end

        # Resolve path to real path (resolving symlinks), falling back to expand_path
        # @param path [String] Path to resolve
        # @return [String] Resolved path
        def resolve_real_path(path)
          File.realpath(path)
        rescue Errno::ENOENT
          File.expand_path(path)
        end

        def format_summary(result)
          summary = []
          summary << "# Diff Summary"
          summary << ""
          summary << result.summary
          summary << ""

          if result.files.any?
            summary << "## Files Changed"
            result.files.each do |file|
              summary << "- #{file}"
            end
            summary << ""
          end

          summary.join("\n")
        end

        def format_grouped_stats(result, output_path: nil)
          grouped_data = result.metadata[:grouped_stats] || result.metadata["grouped_stats"]
          return result.content unless grouped_data

          collapse_above = grouped_data[:collapse_above] || grouped_data["collapse_above"] || 5
          markdown = output_path && File.extname(output_path) == ".md"
          Atoms::GroupedStatsFormatter.format(grouped_data, markdown: markdown, collapse_above: collapse_above)
        end

        def normalized_format(value)
          return :diff if value.nil?

          value.to_s.tr("-", "_").to_sym
        end

        protected

        # Protected methods for external dependency access (testability pattern)
        # See guide://testable-code-patterns for rationale

        # Check if file exists (protected for test stubbing)
        def file_exist?(path)
          File.exist?(path)
        end

        # Read file content (protected for test stubbing)
        def file_read(path)
          File.read(path)
        end

        # Parse YAML safely (protected for test stubbing)
        def yaml_safe_load(content)
          YAML.safe_load(content, permitted_classes: [Symbol])
        end
      end
    end
  end
end
end
