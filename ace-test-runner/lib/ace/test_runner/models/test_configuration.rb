# frozen_string_literal: true

module Ace
  module TestRunner
    module Models
      # Configuration for test execution
      class TestConfiguration
        attr_accessor :format, :report_dir, :save_reports, :fail_fast,
          :verbose, :filter, :fix_deprecations, :patterns,
          :timeout, :parallel, :color, :per_file, :groups,
          :target, :config_path, :failure_limits, :profile,
          :execution, :files, :run_in_single_batch

        def initialize(attributes = {})
          @format = attributes[:format] || "progress"  # Default to per-test progress
          @report_dir = attributes[:report_dir] || ".ace-local/test/reports"
          @save_reports = attributes.fetch(:save_reports, true)
          @fail_fast = attributes[:fail_fast] || false
          @verbose = attributes[:verbose] || false
          @filter = attributes[:filter]
          @fix_deprecations = attributes[:fix_deprecations] || false
          @patterns = attributes[:patterns] || default_patterns
          @groups = attributes[:groups] || default_groups
          @target = attributes[:target]
          @config_path = attributes[:config_path]
          @timeout = attributes[:timeout]  # In seconds, nil = no timeout
          @parallel = attributes[:parallel] || false
          @color = attributes.fetch(:color, true)
          @per_file = attributes[:per_file] || false  # Default to grouped execution for performance
          @failure_limits = attributes[:failure_limits] || {max_display: 7}
          @profile = attributes[:profile]  # nil means no profiling, number means show N slowest tests
          @execution = attributes[:execution] || {}
          @files = attributes[:files]  # Specific files to test (overrides target/patterns)
          @run_in_single_batch = attributes[:run_in_single_batch] || false
        end

        def valid_format?
          %w[json progress progress-file].include?(format)
        end

        def validate!
          unless valid_format?
            raise ArgumentError, "Unknown format '#{format}'. Valid formats: progress, progress-file, json"
          end

          if save_reports && !writable_directory?(report_dir)
            raise ArgumentError, "Cannot write to #{report_dir}. Check permissions"
          end

          # Validate execution_mode if provided
          if execution_mode && !%w[grouped all-at-once].include?(execution_mode)
            raise ArgumentError, "Unknown execution_mode '#{execution_mode}'. Valid modes: grouped, all-at-once"
          end

          true
        end

        def execution_mode
          # Default to "all-at-once" for simple, fast execution
          @execution&.[](:mode) || @execution&.dig("mode") || "all-at-once"
        end

        def group_isolation
          # Default to true for better isolation in grouped mode
          # Use fetch to handle false values correctly (|| would treat false as falsy)
          mode = @execution&.[](:group_isolation)
          mode = @execution&.dig("group_isolation") if mode.nil?
          mode.nil? || mode
        end

        def formatter_class
          # Use lazy loader to load formatter on demand
          Atoms::LazyLoader.load_formatter(format)
        end

        def to_h
          {
            format: format,
            report_dir: report_dir,
            save_reports: save_reports,
            fail_fast: fail_fast,
            verbose: verbose,
            filter: filter,
            fix_deprecations: fix_deprecations,
            patterns: patterns,
            groups: groups,
            target: target,
            config_path: config_path,
            timeout: timeout,
            parallel: parallel,
            color: color,
            per_file: per_file,
            failure_limits: failure_limits,
            profile: profile,
            execution: execution,
            files: files,
            run_in_single_batch: run_in_single_batch
          }
        end

        def merge(options)
          self.class.new(to_h.merge(options))
        end

        def self.from_file(path)
          return new unless File.exist?(path)

          config_data = YAML.load_file(path)
          test_config = config_data["test"] || {}
          new(test_config.transform_keys(&:to_sym))
        end

        def self.from_cascade
          # Use ace-core configuration cascade if available
          if defined?(Ace::Core::Configuration)
            config = Ace::Core::Configuration.new
            test_config = config.get("test", {})
            new(test_config.transform_keys(&:to_sym))
          else
            new
          end
        end

        private

        def default_patterns
          {
            atoms: "test/unit/atoms/**/*_test.rb",
            molecules: "test/unit/molecules/**/*_test.rb",
            organisms: "test/unit/organisms/**/*_test.rb",
            models: "test/unit/models/**/*_test.rb",
            integration: "test/integration/**/*_test.rb",
            all: "test/**/*_test.rb"
          }
        end

        def default_groups
          {
            unit: %w[atoms molecules organisms models],
            all: %w[unit integration],
            quick: %w[atoms molecules]
          }
        end

        def writable_directory?(dir)
          if Dir.exist?(dir)
            File.writable?(dir)
          else
            nearest_existing = dir
            loop do
              parent = File.dirname(nearest_existing)
              break if parent == nearest_existing

              nearest_existing = parent
              break if Dir.exist?(nearest_existing)
            end

            Dir.exist?(nearest_existing) && File.writable?(nearest_existing)
          end
        end
      end
    end
  end
end
