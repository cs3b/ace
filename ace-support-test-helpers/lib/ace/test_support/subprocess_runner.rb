# frozen_string_literal: true

require "open3"
require "tempfile"

module Ace
  module TestSupport
    # Module for running test code in isolated subprocesses
    # This ensures ENV variables and other global state don't leak between tests
    module SubprocessRunner
      # Run Ruby code in a subprocess with specified environment
      # @param env [Hash] Environment variables for the subprocess
      # @param code [String] Ruby code to execute
      # @param requires [Array<String>] Libraries to require before executing code
      # @return [Array<String, Process::Status>] stdout+stderr output and exit status
      def run_in_subprocess(code:, env: {}, requires: [])
        # Build require flags
        require_flags = requires.flat_map { |r| ["-r", r] }

        # Execute in subprocess
        Open3.capture2e(env, RbConfig.ruby, *require_flags, "-e", code)
      end

      # Run Ruby code in a clean environment (without PROJECT_ROOT_PATH)
      # @param code [String] Ruby code to execute
      # @param requires [Array<String>] Libraries to require before executing code
      # @return [Array<String, Process::Status>] stdout+stderr output and exit status
      def run_in_clean_env(code:, requires: [])
        # Create clean environment without PROJECT_ROOT_PATH
        # We need to explicitly unset it by setting to nil
        clean_env = {"PROJECT_ROOT_PATH" => nil}
        run_in_subprocess(env: clean_env, code: code, requires: requires)
      end

      # Run Ruby code in a subprocess with a temporary working directory
      # @param env [Hash] Environment variables for the subprocess
      # @param code [String] Ruby code to execute (will have access to temp_dir variable)
      # @param requires [Array<String>] Libraries to require before executing code
      # @return [Array<String, Process::Status>] stdout+stderr output and exit status
      def run_in_temp_dir(code:, env: {}, requires: [])
        Dir.mktmpdir("ace-test-") do |temp_dir|
          wrapped_code = <<~RUBY
            temp_dir = "#{temp_dir}"
            Dir.chdir(temp_dir)
            #{code}
          RUBY

          run_in_subprocess(env: env, code: wrapped_code, requires: requires)
        end
      end

      # Run a test file in an isolated subprocess
      # Useful for testing code that modifies require paths or other global state
      # @param test_file [String] Path to test file
      # @param env [Hash] Environment variables for the subprocess
      # @return [Array<String, Process::Status>] stdout+stderr output and exit status
      def run_isolated_test_file(test_file, env: {})
        clean_env = ENV.to_h.reject { |k, _| k == "PROJECT_ROOT_PATH" }.merge(env)

        # Run the test file directly with Ruby
        Open3.capture2e(clean_env, RbConfig.ruby, test_file)
      end
    end
  end
end
