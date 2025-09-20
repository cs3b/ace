# frozen_string_literal: true

module Ace
  module TestRunner
    module Models
      # Configuration for test execution
      class TestConfiguration
        attr_accessor :format, :report_dir, :save_reports, :fail_fast,
                      :verbose, :filter, :fix_deprecations, :patterns,
                      :timeout, :parallel, :color, :per_file

        def initialize(attributes = {})
          @format = attributes[:format] || "progress"  # Default to per-test progress
          @report_dir = attributes[:report_dir] || "test-reports"
          @save_reports = attributes.fetch(:save_reports, true)
          @fail_fast = attributes[:fail_fast] || false
          @verbose = attributes[:verbose] || false
          @filter = attributes[:filter]
          @fix_deprecations = attributes[:fix_deprecations] || false
          @patterns = attributes[:patterns] || default_patterns
          @timeout = attributes[:timeout]  # In seconds, nil = no timeout
          @parallel = attributes[:parallel] || false
          @color = attributes.fetch(:color, true)
          @per_file = attributes[:per_file] || false  # Default to grouped execution for performance
        end

        def valid_format?
          %w[ai compact json markdown progress progress-file].include?(format)
        end

        def validate!
          unless valid_format?
            raise ArgumentError, "Unknown format '#{format}'. Valid formats: progress, progress-file, compact, ai, json, markdown"
          end

          if save_reports && !writable_directory?(report_dir)
            raise ArgumentError, "Cannot write to #{report_dir}. Check permissions"
          end

          true
        end

        def formatter_class
          case format
          when "ai"
            Formatters::AiFormatter
          when "compact"
            Formatters::CompactFormatter
          when "json"
            Formatters::JsonFormatter
          when "markdown"
            Formatters::MarkdownFormatter
          when "progress"
            Formatters::ProgressFormatter
          when "progress-file"
            Formatters::ProgressFileFormatter
          else
            raise ArgumentError, "Unknown format: #{format}"
          end
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
            timeout: timeout,
            parallel: parallel,
            color: color,
            per_file: per_file
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
          [
            "test/**/*_test.rb",
            "spec/**/*_spec.rb"
          ]
        end

        def writable_directory?(dir)
          if Dir.exist?(dir)
            File.writable?(dir)
          else
            parent_dir = File.dirname(dir)
            Dir.exist?(parent_dir) && File.writable?(parent_dir)
          end
        end
      end
    end
  end
end