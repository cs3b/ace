# frozen_string_literal: true

require "open3"

module Ace
  module TestSupport
    module Fixtures
      # Shared mock fixtures for ace-test-runner testing
      # Used to stub subprocess execution and speed up integration tests
      module TestRunnerMocks
        # Standard successful test run output
        # @param package [String] The package name (default: "ace-bundle")
        # @param test_count [Integer] Number of tests run (default: 2)
        # @param assertion_count [Integer] Number of assertions (default: 4)
        # @return [String] Mock test output
        def self.mock_success_output(package: "ace-bundle", test_count: 2, assertion_count: 4)
          <<~OUTPUT
            Running tests in #{package}
            #{"." * test_count}
            Finished tests in 0.001s
            #{test_count} tests, #{assertion_count} assertions, 0 failures
          OUTPUT
        end

        # Mock profile output (slowest tests)
        # @return [String] Mock profile header
        def self.mock_profile_output
          <<~OUTPUT

            Slowest Tests:
            =============
          OUTPUT
        end

        # Mock error output for unknown target
        # @param target [String] The unknown target name
        # @return [String] Mock error output
        def self.mock_unknown_target_error(target)
          <<~OUTPUT
            Error: Unknown target '#{target}'
            No matching files found for pattern: #{target}
          OUTPUT
        end

        # Mock error output for package not found
        # @param path [String] The invalid package path
        # @return [String] Mock error output
        def self.mock_package_not_found_error(path)
          <<~OUTPUT
            Error: Package not found: #{path}
            Directory does not exist or is not a valid package
          OUTPUT
        end

        # Standard success status object for Open3.capture3
        # @return [Object] Mock status with success? => true
        def self.mock_success_status
          status = Object.new
          status.define_singleton_method(:success?) { true }
          status.define_singleton_method(:exitstatus) { 0 }
          status
        end

        # Standard failure status object for Open3.capture3
        # @return [Object] Mock status with success? => false
        def self.mock_failure_status
          status = Object.new
          status.define_singleton_method(:success?) { false }
          status.define_singleton_method(:exitstatus) { 1 }
          status
        end

        # Stub Open3.capture3 for test runner execution
        # @param output [String] The mock output (default: success output)
        # @param success [Boolean] Whether the mock should succeed (default: true)
        # @yield Block where the stub is active
        def self.stub_test_run(output: mock_success_output, success: true)
          status = success ? mock_success_status : mock_failure_status
          Open3.stub(:capture3, [output, "", status]) do
            yield
          end
        end
      end
    end
  end
end
