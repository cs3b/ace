# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "tmpdir"
require "yaml"
require "timeout"

class ExecutionVerdictCliTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  CLI = File.join(ROOT, "bin", "ace-test")

  def with_package(files)
    Dir.mktmpdir("execution-verdict") do |root|
      files.each do |name, content|
        path = File.join(root, "test", name)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end
      File.write(File.join(root, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
      FileUtils.mkdir_p(File.join(root, ".ace", "test"))
      config = {"version" => 1, "patterns" => {"first" => "test/first/*_test.rb", "failure" => "test/failure/*_test.rb", "last" => "test/last/*_test.rb"},
        "targets" => {"all" => ["first", "failure", "last"]},
        "execution" => {"mode" => "by-target", "target_fail_fast" => false, "target_isolation" => false}}
      File.write(File.join(root, ".ace", "test", "runner.yml"), YAML.dump(config))
      yield root
    end
  end

  def passing(marker = nil, text = "")
    <<~RUBY
      require "minitest/autorun"
      #{"File.write(#{marker.inspect}, 'ran')" if marker}
      puts #{text.inspect}
      class Passing#{marker ? 'Marker' : 'First'} < Minitest::Test
        def test_pass; assert true; end
      end
    RUBY
  end

  def green_failure(direct: false)
    "puts '3 tests, 4 assertions, 0 failures, 0 errors, 0 skips (0.01s)'\n" +
      (direct ? "raise 'controlled execution failure'\n" : "STDOUT.flush\nwarn 'controlled execution failure'\nexit 9\n")
  end

  def run_cli(root, *args)
    stdout, stderr, status = Open3.capture3({"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile")},
      RbConfig.ruby, CLI, root, *args, "--no-color", "--report-dir", File.join(root, "reports"), chdir: ROOT)
    summaries = Dir.glob(File.join(root, "reports", "**", "summary.json"))
    assert_equal 1, summaries.length, stdout + stderr
    summary = JSON.parse(File.read(summaries.first))
    report_root = File.dirname(summaries.first)
    report = JSON.parse(File.read(File.join(report_root, "report.json")))
    assert_equal summary["success"], report.dig("result", "success")
    assert_includes File.read(File.join(report_root, "report.md")), summary["success"] ? "✅ Success" : "❌ Failed"
    [stdout + stderr, status, summary]
  end

  def assert_failed(root, *args)
    output, status, summary = run_cli(root, *args)
    refute status.success?, output
    assert_equal false, summary["success"], output
    assert_equal 0, summary["errors"], output
    assert_match(/execution/i, output)
    summary
  end

  def test_target_modes_preserve_partial_counts_and_fail_fast_boundary
    %w[--direct --subprocess].each do |mode|
      [false, true].each do |fast|
        with_package("first/first_test.rb" => passing,
          "failure/failure_test.rb" => green_failure(direct: mode == "--direct"),
          "last/last_test.rb" => passing("marker")) do |root|
          summary = assert_failed(root, "all", mode, fast ? "--fail-fast" : "--no-fail-fast")
          assert_operator summary["passed"], :>=, 1
          assert_equal !fast, File.exist?(File.join(root, "marker"))
        end
      end
    end
  end

  def test_subprocess_per_file_and_batch_precedence
    [[%w[--subprocess --per-file --no-fail-fast], true],
      [%w[--subprocess --per-file --fail-fast], false],
      [%w[--subprocess --run-in-single-batch --no-fail-fast], false],
      [%w[--subprocess --run-in-single-batch --fail-fast], false]].each do |flags, marker|
      with_package("failure/a_test.rb" => green_failure, "failure/b_test.rb" => passing("marker")) do |root|
        summary = assert_failed(root, File.join(root, "test/failure/a_test.rb"), File.join(root, "test/failure/b_test.rb"), *flags)
        assert_equal marker, File.exist?(File.join(root, "marker"))
        assert_equal marker ? 4 : 3, summary["passed"]
      end
    end
  end

  def test_timeout_after_passing_target_preserves_real_counts
    %w[--direct --subprocess].each do |mode|
      [false, true].each do |fast|
        slow = "require 'minitest/autorun'\nclass SlowProbe < Minitest::Test; def test_slow; sleep 1.5; assert true; end; end\n"
        with_package("first/first_test.rb" => passing,
          "failure/slow_test.rb" => slow,
          "last/last_test.rb" => passing("marker")) do |root|
          output, status, summary = run_cli(root, "all", mode, "--timeout", "1", fast ? "--fail-fast" : "--no-fail-fast")
          refute status.success?, output
          assert_equal false, summary["success"]
          assert_equal 0, summary["errors"]
          assert_match(/timed out/, output)
          assert_operator summary["passed"], :>=, 1
          assert_equal !fast, File.exist?(File.join(root, "marker"))
        end
      end
    end
  end

  def test_child_signal_is_failure_without_completed_errors
    with_package("failure/signal_test.rb" => "Process.kill('TERM', Process.pid)\n") do |root|
      summary = assert_failed(root, "all", "--subprocess")
      assert_equal 0, summary["total"]
    end
  end

  def test_successful_timeout_text_and_assertion_failure
    with_package("first/first_test.rb" => passing(nil, "timeout is merely text")) do |root|
      output, status, summary = run_cli(root, "all", "--subprocess")
      assert status.success?, output
      assert_equal true, summary["success"]
    end
    with_package("first/first_test.rb" => passing.sub("assert true", "assert false")) do |root|
      output, status, summary = run_cli(root, "all", "--subprocess")
      refute status.success?, output
      assert_equal false, summary["success"]
      assert_equal 1, summary["failed"]
    end
  end

  def test_suite_consumer_observes_failed_package_verdict
    with_package("failure/failure_test.rb" => green_failure) do |root|
      runner_path = File.join(root, ".ace/test/runner.yml")
      runner_config = YAML.safe_load(File.read(runner_path))
      runner_config["execution"]["target_isolation"] = true
      File.write(runner_path, YAML.dump(runner_config))
      config = {"test_suite" => {"max_parallel" => 1,
        "packages" => [{"name" => "ace-verdict", "path" => root, "priority" => 1}],
        "test_options" => {"target" => "all", "format" => "progress", "save_reports" => true, "report_dir" => File.join(root, "reports")}}}
      File.write(File.join(root, ".ace/test/suite.yml"), YAML.dump(config))
      stdout, stderr, status = Open3.capture3({"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile")},
        RbConfig.ruby, File.join(ROOT, "bin/ace-test-suite"), chdir: root)
      refute status.success?, stdout + stderr
      summaries = Dir.glob(File.join(root, "reports", "**", "summary.json"))
      refute_empty summaries, stdout + stderr
      assert summaries.any? { |path| JSON.parse(File.read(path))["success"] == false }, stdout + stderr
    end
  end

  def test_operator_interrupt_exits_130_without_new_success_artifact
    %w[--direct --subprocess].each do |mode|
      with_package("failure/slow_test.rb" => <<~RUBY) do |root|
        require "minitest/autorun"
        class InterruptProbe < Minitest::Test
          def test_sleep
            File.write("ready", "ready")
            sleep 2
          end
        end
      RUBY
        reports = File.join(root, "reports")
        stale = File.join(reports, "prior", "summary.json")
        FileUtils.mkdir_p(File.dirname(stale))
        File.write(stale, '{"success":true}')
        original = File.binread(stale)
        Open3.popen3({"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile")}, RbConfig.ruby, CLI, root,
          "all", mode, "--report-dir", reports, chdir: ROOT) do |input, stdout, stderr, wait|
          input.close
          Timeout.timeout(10) { sleep 0.01 until File.exist?(File.join(root, "ready")) || !wait.alive? }
          assert wait.alive?, "probe exited before controlled operator interrupt"
          Process.kill("INT", wait.pid)
          status = Timeout.timeout(5) { wait.value }
          output = stdout.read + stderr.read
          assert_equal 130, status.exitstatus, output
          assert_match(/interrupted/, output)
        end
        assert_equal [stale], Dir.glob(File.join(reports, "**", "summary.json"))
        assert_equal original, File.binread(stale)
      end
    end
  end
end
