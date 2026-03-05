# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/molecules/diff_generator"
require "ace/git/models/diff_config"

class DiffGeneratorTest < AceGitTestCase
  def setup
    super
    @config = Ace::Git::Models::DiffConfig.new
  end

  def mock_executor
    mock = Minitest::Mock.new
    mock
  end

  def test_generate_returns_diff_output_on_success
    config = Ace::Git::Models::DiffConfig.from_hash("ranges" => ["HEAD~1..HEAD"])

    executor = Object.new
    def executor.execute(*args)
      @last_args = args
      { success: true, output: "diff content" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "diff content", result
    assert_includes executor.last_args, "HEAD~1..HEAD"
  end

  def test_generate_raises_error_on_failure
    config = Ace::Git::Models::DiffConfig.from_hash("ranges" => ["invalid..range"])

    executor = Object.new
    def executor.execute(*args)
      { success: false, output: "", error: "fatal: invalid ref" }
    end

    error = assert_raises(Ace::Git::GitError) do
      Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    end
    assert_match(/fatal: invalid ref/, error.message)
  end

  def test_generate_uses_staged_diff_for_staged_format
    config = Ace::Git::Models::DiffConfig.from_hash("format" => "staged")

    # Create mock that expects staged_diff to be called
    executor = Object.new
    def executor.staged_diff
      "staged changes"
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "staged changes", result
  end

  def test_generate_uses_working_diff_for_working_format
    config = Ace::Git::Models::DiffConfig.from_hash("format" => "working")

    executor = Object.new
    def executor.working_diff
      "working changes"
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "working changes", result
  end

  def test_generate_for_range_executes_range_diff
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.execute(*args)
      @last_args = args
      { success: true, output: "range diff" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate_for_range("origin/main..HEAD", config, executor: executor)
    assert_equal "range diff", result
    assert_includes executor.last_args, "origin/main..HEAD"
  end

  def test_staged_returns_cached_diff
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.execute(*args)
      @last_args = args
      { success: true, output: "staged diff content" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.staged(config, executor: executor)
    assert_equal "staged diff content", result
    assert_includes executor.last_args, "--cached"
  end

  def test_working_returns_working_diff
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.execute(*args)
      @last_args = args
      { success: true, output: "working diff content" }
    end

    result = Ace::Git::Molecules::DiffGenerator.working(config, executor: executor)
    assert_equal "working diff content", result
  end

  def test_generate_includes_path_filters
    config = Ace::Git::Models::DiffConfig.from_hash(
      "ranges" => ["HEAD~1..HEAD"],
      "paths" => ["lib/**/*.rb", "src/**/*.js"]
    )

    executor = Object.new
    def executor.execute(*args)
      @last_args = args
      { success: true, output: "filtered diff" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "filtered diff", result
    assert_includes executor.last_args, "--"
    assert_includes executor.last_args, "lib/**/*.rb"
    assert_includes executor.last_args, "src/**/*.js"
  end

  def test_generate_includes_whitespace_flags
    config = Ace::Git::Models::DiffConfig.from_hash(
      "ranges" => ["HEAD~1..HEAD"],
      "exclude_whitespace" => true
    )

    executor = Object.new
    def executor.execute(*args)
      @last_args = args
      { success: true, output: "no whitespace diff" }
    end

    def executor.last_args
      @last_args
    end

    Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_includes executor.last_args, "-w"
  end

  def test_generate_defaults_to_tracking_ref_when_tracking_exists
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.has_unstaged_changes?
      false
    end

    def executor.has_staged_changes?
      false
    end

    def executor.tracking_branch
      "feature/001"
    end

    def executor.ref_exists?(ref)
      ref == "feature/001"
    end

    def executor.execute(*args, timeout: nil)
      @last_args = args
      { success: true, output: "diff output" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "diff output", result
    assert_includes executor.last_args, "feature/001...HEAD"
  end

  def test_generate_falls_back_to_origin_main_when_tracking_missing
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.has_unstaged_changes?
      false
    end

    def executor.has_staged_changes?
      false
    end

    def executor.tracking_branch
      nil
    end

    def executor.ref_exists?(ref)
      ref == "origin/main"
    end

    def executor.execute(*args, timeout: nil)
      @last_args = args
      { success: true, output: "diff output" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "diff output", result
    assert_includes executor.last_args, "origin/main...HEAD"
  end

  def test_generate_falls_back_to_last_commit_when_no_remote_ref_exists
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.has_unstaged_changes?
      false
    end

    def executor.has_staged_changes?
      false
    end

    def executor.tracking_branch
      "origin/main"
    end

    def executor.ref_exists?(ref)
      ref == "HEAD~1"
    end

    def executor.execute(*args, timeout: nil)
      @last_args = args
      { success: true, output: "diff output" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "diff output", result
    assert_includes executor.last_args, "HEAD~1..HEAD"
  end

  def test_generate_smart_default_uses_unstaged_when_available
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.has_unstaged_changes?
      true
    end

    def executor.execute(*args)
      @last_args = args
      { success: true, output: "unstaged diff" }
    end

    def executor.last_args
      @last_args
    end

    Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    # When there are unstaged changes, range should be nil (meaning unstaged)
    refute_includes executor.last_args, "--cached"
  end

  def test_generate_passes_timeout_to_executor
    config = Ace::Git::Models::DiffConfig.from_hash(
      "ranges" => ["HEAD~1..HEAD"],
      "timeout" => 60
    )

    executor = Object.new
    def executor.execute(*args, timeout: nil)
      @timeout = timeout
      @args = args
      { success: true, output: "diff output" }
    end

    def executor.timeout
      @timeout
    end

    Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal 60, executor.timeout, "Timeout from config should be passed to executor"
  end

  def test_generate_uses_default_timeout_when_not_specified
    config = Ace::Git::Models::DiffConfig.new

    executor = Object.new
    def executor.has_unstaged_changes?
      true
    end

    def executor.execute(*args, timeout: nil)
      @timeout = timeout
      { success: true, output: "diff output" }
    end

    def executor.timeout
      @timeout
    end

    Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal Ace::Git.git_timeout, executor.timeout, "Should use config timeout when not specified"
  end

  def test_generate_treats_empty_range_as_working_diff
    # Empty string ranges should be treated as "no range" and fall through
    # to smart defaults (working tree diff when there are unstaged changes)
    config = Ace::Git::Models::DiffConfig.from_hash("ranges" => [""])

    executor = Object.new
    def executor.has_unstaged_changes?
      true
    end

    def executor.execute(*args, timeout: nil)
      @last_args = args
      { success: true, output: "working diff" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "working diff", result
    # Should NOT include the empty string as a range argument
    refute_includes executor.last_args, ""
  end

  def test_generate_treats_whitespace_only_range_as_working_diff
    # Whitespace-only ranges should also be treated as "no range"
    config = Ace::Git::Models::DiffConfig.from_hash("ranges" => ["  \t  "])

    executor = Object.new
    def executor.has_unstaged_changes?
      true
    end

    def executor.execute(*args, timeout: nil)
      @last_args = args
      { success: true, output: "working diff" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "working diff", result
  end

  def test_generate_uses_first_non_empty_range
    # If mix of empty and non-empty ranges, use first non-empty
    config = Ace::Git::Models::DiffConfig.from_hash("ranges" => ["", "HEAD~1..HEAD", ""])

    executor = Object.new
    def executor.execute(*args, timeout: nil)
      @last_args = args
      { success: true, output: "range diff" }
    end

    def executor.last_args
      @last_args
    end

    result = Ace::Git::Molecules::DiffGenerator.generate(config, executor: executor)
    assert_equal "range diff", result
    assert_includes executor.last_args, "HEAD~1..HEAD"
  end

  def test_generate_numstat_includes_numstat_flag
    config = Ace::Git::Models::DiffConfig.from_hash(
      "ranges" => ["HEAD~1..HEAD"],
      "paths" => ["ace-git/lib/**/*.rb"]
    )

    executor = Object.new
    def executor.execute(*args, timeout: nil)
      @last_args = args
      @timeout = timeout
      { success: true, output: "7\t2\tace-git/lib/ace/git/cli/commands/diff.rb\n" }
    end

    def executor.last_args
      @last_args
    end

    output = Ace::Git::Molecules::DiffGenerator.generate_numstat(config, executor: executor)

    assert_match(/ace-git\/lib\/ace\/git\/cli\/commands\/diff\.rb/, output)
    assert_includes executor.last_args, "--numstat"
    assert_includes executor.last_args, "HEAD~1..HEAD"
    assert_includes executor.last_args, "ace-git/lib/**/*.rb"
  end
end
