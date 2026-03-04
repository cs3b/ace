# frozen_string_literal: true

require "yaml"
require "fileutils"
require "tmpdir"

module Ace
  module TestSupport
    # Helpers for config testing across all ace-* gems
    module ConfigHelpers
      # Execute block with test mode enabled
      #
      # This helper enables Ace::Support::Config test mode for the duration of the block,
      # skipping filesystem searches and returning mock config instead.
      #
      # @param mock_config [Hash] Mock configuration data to return (default: {})
      # @yield Block to execute with test mode enabled
      # @return [Object] Result of the block
      #
      # @example Skip config filesystem access
      #   with_test_config do
      #     config = Ace::Support::Config.create.resolve
      #     assert_equal({}, config.data)
      #   end
      #
      # @example Provide mock config
      #   with_test_config({ "key" => "value" }) do
      #     config = Ace::Support::Config.create.resolve
      #     assert_equal "value", config.get("key")
      #   end
      #
      def with_test_config(mock_config = {})
        require 'ace/support/config'

        original_test_mode = Ace::Support::Config.test_mode
        original_mock = Ace::Support::Config.default_mock

        Ace::Support::Config.test_mode = true
        Ace::Support::Config.default_mock = mock_config

        yield
      ensure
        Ace::Support::Config.test_mode = original_test_mode
        Ace::Support::Config.default_mock = original_mock
      end

      # Execute block with real config (test mode disabled)
      #
      # This helper temporarily disables test mode for integration tests
      # that need to test actual filesystem-based config loading.
      #
      # @yield Block to execute with real config
      # @return [Object] Result of the block
      #
      # @example Run integration test with real config
      #   with_real_config do
      #     with_temp_config(".git" => "", ".ace" => { "config.yml" => "key: value" }) do
      #       config = Ace::Support::Config.create.resolve
      #       assert_equal "value", config.get("key")
      #     end
      #   end
      #
      def with_real_config
        require 'ace/support/config'

        original_test_mode = Ace::Support::Config.test_mode

        Ace::Support::Config.test_mode = false

        yield
      ensure
        Ace::Support::Config.test_mode = original_test_mode
      end

      # Execute block with temporary config file
      def with_config(path, content)
        FileUtils.mkdir_p(File.dirname(path))

        # Handle both Hash and String content
        file_content = case content
                      when Hash
                        content.to_yaml
                      when String
                        content
                      else
                        raise ArgumentError, "Content must be Hash or String"
                      end

        File.write(path, file_content)
        yield
      ensure
        FileUtils.rm_f(path) if path && File.exist?(path)
      end

      # Execute block with temporary environment variables
      def with_env(vars)
        old_values = {}

        vars.each do |key, value|
          old_values[key] = ENV[key]
          ENV[key] = value
        end

        yield
      ensure
        old_values.each do |key, value|
          if value.nil?
            ENV.delete(key)
          else
            ENV[key] = value
          end
        end
      end

      # Create multi-level config setup for any ace-* gem
      def with_cascade_configs(gem_name = "core", configs = {})
        paths = []
        old_home = ENV["HOME"]
        temp_home = nil

        begin
          # Create project config
          if configs[:project]
            project_path = "./.ace/#{gem_name}/config.yml"
            FileUtils.mkdir_p(File.dirname(project_path))
            File.write(project_path, configs[:project].to_yaml)
            paths << project_path
          end

          # Create home config
          if configs[:home]
            temp_home = Dir.mktmpdir("ace-test-home")
            ENV["HOME"] = temp_home
            home_path = File.join(temp_home, ".ace", gem_name, "config.yml")
            FileUtils.mkdir_p(File.dirname(home_path))
            File.write(home_path, configs[:home].to_yaml)
            paths << home_path
          end

          yield
        ensure
          ENV["HOME"] = old_home
          FileUtils.rm_rf(temp_home) if temp_home && Dir.exist?(temp_home)
          paths.each { |path| FileUtils.rm_f(path) if File.exist?(path) }
        end
      end

      # Create sample config content
      def sample_config(gem_name: "core", level: "default", custom: {})
        base = {
          "ace" => {
            "level" => level,
            gem_name => {
              "version" => "1.0.0",
              "environment" => "test"
            }
          }
        }

        deep_merge(base, custom)
      end

      # Create .env file content
      def sample_env_content(vars = {})
        default_vars = {
          "ACE_ENV" => "test",
          "ACE_DEBUG" => "false"
        }

        default_vars.merge(vars).map do |key, value|
          "#{key}=#{value}"
        end.join("\n")
      end

      # Assert config has expected structure
      def assert_config_structure(config, expected)
        assert_kind_of Hash, config

        expected.each do |key, value|
          assert config.key?(key), "Config missing key: #{key}"

          if value.is_a?(Hash)
            assert_config_structure(config[key], value)
          else
            assert_equal value, config[key], "Config value mismatch for #{key}"
          end
        end
      end

      # Assert config cascade precedence
      def assert_precedence(resolver, key_path, expected_value, source_description)
        config = resolver.resolve
        actual = config.get(*key_path.split('.'))

        assert_equal expected_value, actual,
          "Expected #{key_path} to be '#{expected_value}' from #{source_description}, got '#{actual}'"
      end

      # Create malformed YAML content
      def malformed_yaml
        "ace:\n  invalid: [\n    unclosed"
      end

      # Create valid but complex YAML
      def complex_yaml
        {
          "ace" => {
            "arrays" => [1, 2, 3],
            "nested" => {
              "deep" => {
                "value" => "found"
              }
            },
            "symbols" => {
              "key" => :symbol_value
            }
          }
        }.to_yaml
      end

      private

      # Deep merge helper
      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |_key, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          else
            new_val
          end
        end
      end
    end
  end
end
