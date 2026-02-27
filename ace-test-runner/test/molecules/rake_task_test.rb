# frozen_string_literal: true

require "test_helper"
require "ace/test_runner/rake_task"
require "rake"

class Ace::TestRunner::RakeTaskTest < Minitest::Test
  def setup
    @original_env = ENV.to_h
    # Clear Rake tasks between tests
    Rake::Task.clear

    # Mock system call to prevent actual test execution
    Ace::TestRunner::RakeTask.class_eval do
      alias_method :original_system, :system if method_defined?(:system)
      define_method(:system) do |cmd|
        @last_command = cmd
        true # Always return success for testing
      end

      attr_reader :last_command
    end
  end

  def teardown
    ENV.replace(@original_env)
    Rake::Task.clear
  end

  def test_creates_test_task_with_default_name
    task = Ace::TestRunner::RakeTask.new

    assert Rake::Task.task_defined?(:test), "Should define :test task"
    assert_equal :test, task.name
    assert_equal "Run tests with ace-test", task.description
  end

  def test_creates_test_task_with_custom_name
    task = Ace::TestRunner::RakeTask.new(:custom_test) do |t|
      t.description = "Custom test task"
    end

    assert Rake::Task.task_defined?(:custom_test), "Should define :custom_test task"
    assert_equal :custom_test, task.name
    assert_equal "Custom test task", task.description
  end

  def test_accepts_configuration_block
    task = Ace::TestRunner::RakeTask.new do |t|
      t.verbose = true
      t.format = "json"
      t.pattern = "test/unit/**/*_test.rb"
    end

    assert_equal true, task.verbose
    assert_equal "json", task.format
    assert_equal "test/unit/**/*_test.rb", task.pattern
  end

  def test_default_configuration
    task = Ace::TestRunner::RakeTask.new

    assert_equal %w[test lib], task.libs
    assert_equal "test/**/*_test.rb", task.pattern
    assert_equal false, task.verbose
    assert_nil task.format
  end

  def test_build_command_basic
    task = Ace::TestRunner::RakeTask.new
    command = task.send(:build_command)

    assert_equal "ace-test", command
  end

  def test_build_command_with_format
    task = Ace::TestRunner::RakeTask.new do |t|
      t.format = "compact"
    end
    command = task.send(:build_command)

    assert_equal "ace-test --format compact", command
  end

  def test_build_command_with_verbose
    task = Ace::TestRunner::RakeTask.new do |t|
      t.verbose = true
    end
    command = task.send(:build_command)

    assert_equal "ace-test --verbose", command
  end

  def test_build_command_with_test_files
    task = Ace::TestRunner::RakeTask.new do |t|
      t.test_files = ["test/foo_test.rb", "test/bar_test.rb"]
    end
    command = task.send(:build_command)

    assert_equal "ace-test test/foo_test.rb test/bar_test.rb", command
  end

  def test_build_command_with_options
    task = Ace::TestRunner::RakeTask.new do |t|
      t.options = ["--fail-fast", "--color"]
    end
    command = task.send(:build_command)

    assert_equal "ace-test --fail-fast --color", command
  end

  def test_build_command_with_test_env_variable
    ENV["TEST"] = "test/specific_test.rb"

    task = Ace::TestRunner::RakeTask.new
    command = task.send(:build_command)

    assert_equal "ace-test test/specific_test.rb", command
  end

  def test_build_command_with_testopts_env_variable
    ENV["TESTOPTS"] = "--verbose --fail-fast"

    task = Ace::TestRunner::RakeTask.new
    command = task.send(:build_command)

    assert_equal "ace-test --verbose --fail-fast", command
  end

  def test_build_command_with_all_options
    ENV["TEST"] = "test/specific_test.rb"
    ENV["TESTOPTS"] = "--filter user"

    task = Ace::TestRunner::RakeTask.new do |t|
      t.format = "ai"
      t.verbose = true
      t.options = ["--color"]
    end
    command = task.send(:build_command)

    expected = "ace-test --format ai --verbose test/specific_test.rb --filter user --color"
    assert_equal expected, command
  end

  def test_compatibility_accessors
    task = Ace::TestRunner::RakeTask.new

    # Test libs accessor
    task.libs = %w[test lib spec]
    assert_equal %w[test lib spec], task.libs

    # Test test_files accessor
    task.test_files = ["test/foo_test.rb"]
    assert_equal ["test/foo_test.rb"], task.test_files

    # Test warning accessor
    task.warning = true
    assert_equal true, task.warning

    # Test loader accessor
    task.loader = :direct
    assert_equal :direct, task.loader
  end

  def test_strips_assignment_context_vars_from_environment
    ENV["ACE_ASSIGN_ID"] = "test-assignment"
    ENV["ACE_ASSIGN_FORK_ROOT"] = "010"

    task = Ace::TestRunner::RakeTask.new

    # Track the env hash passed to system
    system_env = nil
    task.define_singleton_method(:system) do |*args|
      if args.first.is_a?(Hash)
        system_env = args.first
        true
      else
        true
      end
    end

    Rake::Task[:test].invoke

    # Verify assignment context vars are stripped (set to nil)
    assert_nil system_env["ACE_ASSIGN_ID"], "ACE_ASSIGN_ID should be nil in subprocess env"
    assert_nil system_env["ACE_ASSIGN_FORK_ROOT"], "ACE_ASSIGN_FORK_ROOT should be nil in subprocess env"
  end
end