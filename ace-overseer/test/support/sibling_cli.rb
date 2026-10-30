# frozen_string_literal: true

require "stringio"
require "ace/task"
require "ace/task/cli"
require "ace/assign"
require "ace/hitl"

# Performance helper (test/optimize): runs sibling-package CLIs
# (ace-task, ace-assign, ace-hitl) in this process through the exact
# CLI.start entry the binstubs use, minus the per-invocation
# Ruby/bundler boot (~0.7s each). Reserved for choreography (fixture
# state the test drives but does not assert on): the packages under
# test (ace-overseer, ace-coworker) always run as real subprocesses
# through their binstubs.
module SiblingCli
  module_function

  # Open3::Status-compatible result for assertions.
  Status = Struct.new(:exitstatus) do
    def success?
      exitstatus.zero?
    end
  end

  # call(cli, argv, chdir:) -> [stdout, stderr, status]; cli is a
  # callable taking an argv array, e.g. ->(a) { Ace::Task::TaskCLI.start(a) }
  def call(cli, argv, chdir: Dir.pwd, env: {})
    out = StringIO.new
    err = StringIO.new
    previous_out, previous_err = $stdout, $stderr
    previous_env = env.keys.to_h { |k| [k, ENV[k]] }
    exit_code = 0
    begin
      env.each { |k, v| ENV[k] = v }
      Dir.chdir(chdir) do
        $stdout = out
        $stderr = err
        begin
          # A subprocess would start with empty config state; replicate
          # that: clear the process-global project-root cache and drop
          # the thread-local config test mode/mock (set by AceTestCase)
          # so sibling CLIs resolve real fixture configuration relative
          # to the fixture cwd.
          Ace::Support::Config.reset! if Ace::Support::Config.respond_to?(:reset!)
          test_mode_key = :ace_config_test_mode
          mock_key = :ace_config_default_mock
          saved_mode = Thread.current[test_mode_key]
          saved_mock = Thread.current[mock_key]
          Thread.current[test_mode_key] = nil
          Thread.current[mock_key] = nil
          begin
            code = cli.call(argv)
            exit_code = code.nil? ? 0 : code
          ensure
            Thread.current[test_mode_key] = saved_mode
            Thread.current[mock_key] = saved_mock
          end
        rescue Ace::Support::Cli::Error => e
          err.puts e.message
          exit_code = e.exit_code
        end
      end
    ensure
      previous_env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      $stdout = previous_out
      $stderr = previous_err
    end
    [out.string, err.string, Status.new(exit_code)]
  end

  def run_task(*argv, chdir: Dir.pwd, env: {})
    call(->(a) { Ace::Task::TaskCLI.start(a) }, argv, chdir: chdir, env: env)
  end

  def run_assign(*argv, chdir: Dir.pwd, env: {})
    call(->(a) { Ace::Assign::CLI.start(a) }, argv, chdir: chdir, env: env)
  end

  def run_hitl(*argv, chdir: Dir.pwd, env: {})
    call(->(a) { Ace::Hitl::HitlCLI.start(a) }, argv, chdir: chdir, env: env)
  end
end
