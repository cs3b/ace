# frozen_string_literal: true

require 'yaml'
require 'pathname'

module AceTools
  module TestReporter
    class Configuration
      attr_accessor :mode, :report_dir, :max_reports, :group_by,
                    :color_output, :verbose, :json_output, :markdown_output

      CONFIG_FILE = '.test-reporter.yml'
      ACE_TEST_CONFIG = '.coding-agent/ace-test.yml'

      def initialize
        @mode = 'agent'
        @report_dir = 'test-report'
        @max_reports = 10
        @group_by = 'auto'
        @color_output = !ENV['CI']
        @verbose = ENV['VERBOSE'] == 'true'
        @json_output = true
        @markdown_output = true

        # Load ace-test.yml first if available
        load_ace_test_config
        # Then load .test-reporter.yml for overrides
        load_config_file if File.exist?(CONFIG_FILE)
        load_env_vars

        # Ensure report_dir is resolved properly
        @report_dir = resolve_report_dir(@report_dir)
      end

      def to_h
        {
          mode: mode,
          report_dir: report_dir,
          max_reports: max_reports,
          group_by: group_by,
          color_output: color_output,
          verbose: verbose,
          json_output: json_output,
          markdown_output: markdown_output
        }
      end

      private

      def load_ace_test_config
        # Try multiple locations for ace-test.yml
        config_locations = [
          File.join(Dir.pwd, ACE_TEST_CONFIG),
          File.join(project_root_fallback, ACE_TEST_CONFIG)
        ]

        config_locations.each do |location|
          next unless File.exist?(location)

          begin
            config = YAML.load_file(location)
            if config.is_a?(Hash) && config.dig('reporters', 'agent')
              agent_config = config['reporters']['agent']
              @group_by = agent_config['group_by'] if agent_config['group_by']
              @max_reports = agent_config['max_failures'] if agent_config['max_failures']
              @report_dir = agent_config['output_dir'] if agent_config['output_dir']
            end
            break # Stop after first successful config load
          rescue StandardError => e
            # Continue to next location
          end
        end
      end

      def load_config_file
        config = YAML.load_file(CONFIG_FILE)
        return unless config.is_a?(Hash)

        config.each do |key, value|
          setter = "#{key}="
          send(setter, value) if respond_to?(setter)
        end
      rescue StandardError => e
        warn "Error loading #{CONFIG_FILE}: #{e.message}"
      end

      def project_root_fallback
        begin
          require_relative '../atoms/project_root_detector'
          AceTools::Atoms::ProjectRootDetector.find_project_root
        rescue StandardError
          Dir.pwd
        end
      end

      def load_env_vars
        @mode = ENV['TEST_REPORTER_MODE'] if ENV['TEST_REPORTER_MODE']
        @report_dir = ENV['TEST_REPORT_DIR'] if ENV['TEST_REPORT_DIR']
        @group_by = ENV['TEST_GROUP_BY'] if ENV['TEST_GROUP_BY']
      end

      def resolve_report_dir(dir)
        return dir if Pathname.new(dir).absolute?

        # When running tests, use the current working directory as base
        # since ace-test changes to the tools directory
        File.expand_path(dir, Dir.pwd)
      end
    end
  end
end