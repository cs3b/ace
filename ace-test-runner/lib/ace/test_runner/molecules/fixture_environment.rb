# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Ace
  module TestRunner
    module Molecules
      # Builds a launch-ready hermetic environment for deterministic test children.
      #
      # The fixture environment:
      # - starts from the sanitized allowlisted base (Atoms::EnvironmentSanitizer)
      # - replaces HOME and XDG locations with test-owned directories
      # - applies explicit fixture overrides after sanitization
      # - validates required explicit configuration, naming missing keys not values
      #
      # Cleanup owns only the temporary root created here; the parent home,
      # project directories, and system temp locations are never touched.
      class FixtureEnvironment
        attr_reader :policy, :root, :env

        def initialize(policy:, parent_env:, root_factory: Dir.method(:mktmpdir))
          @policy = policy
          @parent_env = parent_env
          @root_factory = root_factory
          @root = nil
          @env = nil
        end

        # Build the fixture environment. Returns self for chaining.
        # A failed build cleans up the temporary root it created before raising.
        def build
          @root = @root_factory.call("ace-test-fixture-")
          @env = build_environment
          self
        rescue StandardError
          cleanup
          raise
        end

        # Remove the test-owned fixture root. Safe to call multiple times.
        def cleanup
          return unless @root

          FileUtils.rm_rf(@root)
          @root = nil
          @env = nil
        end

        private

        def build_environment
          env = Atoms::EnvironmentSanitizer.sanitize(@parent_env, @policy)
          env["MT_NO_AUTORUN"] = "1"
          apply_fixture_homes(env)
          @policy.overrides.each { |key, value| env[key] = value }
          validate_required_keys!(env)
          env
        end

        def apply_fixture_homes(env)
          home = File.join(@root, "home")
          config_home = File.join(home, ".config")
          cache_home = File.join(home, ".cache")
          data_home = File.join(home, ".local", "share")

          [home, config_home, cache_home, data_home].each { |dir| FileUtils.mkdir_p(dir) }

          @policy.fixture_home_keys.each do |key|
            env[key] = case key
            when "HOME" then home
            when "XDG_CONFIG_HOME" then config_home
            when "XDG_CACHE_HOME" then cache_home
            when "XDG_DATA_HOME" then data_home
            end
          end
        end

        def validate_required_keys!(env)
          missing = @policy.required_keys.select { |key| env[key].to_s.empty? }
          return if missing.empty?

          raise EnvironmentSetupError,
            "Missing required fixture environment for deterministic test mode: #{missing.join(", ")}." \
            " Supply the listed keys via runner configuration environment.overrides."
        end
      end
    end
  end
end
