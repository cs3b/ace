# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"
require "tmpdir"
require "timeout"

class SuiteExecutionEvidenceTest < Minitest::Test
  Runner = Ace::TestRunner
  Evidence = Runner::Molecules::ExecutionEvidence
  Storage = Runner::Molecules::ReportStorage
  ROOT = File.expand_path("../../../..", __dir__)

  class FixtureMonitor < Runner::Suite::ProcessMonitor
    attr_accessor :command

    private

    def build_command(_package, _options)
      command
    end
  end

  def saved(evidence, passed: 3, failed: 0)
    storage = Storage.new(base_dir: File.join(evidence.package_path, "reports"))
    directory = storage.reserve(evidence.identity)
    result = Runner::Models::TestResult.new(passed: passed, failed: failed, assertions: 9, duration: 0.25)
    report = Runner::Models::TestReport.new(result: result, files_tested: ["test/a_test.rb"])
    storage.save_report(report, format: :all, report_dir: directory)
    evidence.publish(result, files: report.files_tested, report_dir: directory)
    directory
  end

  def test_fixed_clock_concurrent_allocation_and_publication_never_overwrite
    Dir.mktmpdir do |root|
      time = Time.utc(2026, 10, 5)
      paths = Time.stub(:now, time) do
        threads = 8.times.map do |index|
          Thread.new do
            evidence = Evidence.new(package_path: root)
            saved(evidence, passed: index + 1)
          end
        end
        threads.map(&:value)
      end
      assert_equal 8, paths.uniq.length
      assert_equal (1..8).to_a, paths.map { |path| JSON.parse(File.read(File.join(path, "summary.json")))["passed"] }.sort
      assert_includes paths, File.realpath(File.join(root, "reports/latest"))
    end
  end

  def test_completion_is_exclusive_and_summary_detail_are_one_execution
    Dir.mktmpdir do |root|
      evidence = Evidence.new(package_path: root)
      directory = saved(evidence)
      snapshot = evidence.read(pid: Process.pid, save_reports: true)
      assert_equal 3, snapshot[:total]
      assert_equal 9, snapshot[:assertions]
      assert_equal directory, snapshot[:report_dir]
      assert_raises(Errno::EEXIST) { evidence.publish(Runner::Models::TestResult.new, files: []) }
      other = Evidence.new(package_path: root)
      other_dir = saved(other, failed: 1)
      FileUtils.cp(File.join(other_dir, "report.json"), File.join(directory, "report.json"))
      assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: true) }
    end
  end

  def test_absent_incomplete_malformed_mismatched_and_unreadable_completion_fail
    Dir.mktmpdir do |root|
      evidence = Evidence.new(package_path: root)
      assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: false) }
      evidence.publish(Runner::Models::TestResult.new, files: [])
      original = JSON.parse(File.read(evidence.path))
      [{"completed" => false}, {"execution_id" => "unrelated"}, {"entry_id" => "unrelated"},
        {"package" => "unrelated"}, {"pid" => Process.pid + 1}, {"package_path" => "/unrelated"},
        {"selected_files" => nil}, {"total" => "0"}, {"assertions" => nil}, {"success" => nil},
        {"duration" => -1}, {"report_dir" => "/fabricated"}].each do |change|
        File.write(evidence.path, JSON.generate(original.merge(change)))
        assert_raises(Runner::Error, change.inspect) { evidence.read(pid: Process.pid, save_reports: false) }
      end
      ["{", "[]", "null"].each do |content|
        File.write(evidence.path, content)
        assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: false) }
      end
      FileUtils.rm_f(evidence.path)
      Dir.mkdir(evidence.path)
      assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: false) }
    end
  end

  def test_saved_completion_requires_readable_matching_summary_and_detail
    Dir.mktmpdir do |root|
      evidence = Evidence.new(package_path: root)
      directory = saved(evidence)
      %w[summary.json report.json].each do |name|
        path = File.join(directory, name)
        original = File.read(path)
        ["{", "[]", "null", JSON.generate({execution_id: "other"})].each do |content|
          File.write(path, content)
          assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: true) }
        end
        FileUtils.rm_f(path)
        assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: true) }
        File.write(path, original)
      end
    end
  end

  def fixture_command(root, failure: false, saved: true, exit_code: 0, barrier: false)
    body = <<~RUBY
      require #{File.join(ROOT, "ace-test-runner/lib/ace/test_runner").inspect}
      evidence = Ace::TestRunner::Molecules::ExecutionEvidence.for_invocation(Dir.pwd)
      result = Ace::TestRunner::Models::TestResult.new(passed: 3, failed: #{failure ? 1 : 0}, assertions: 9, duration: 0.25)
      directory = nil
      if #{saved}
        storage = Ace::TestRunner::Molecules::ReportStorage.new(base_dir: #{File.join(root, 'reports').inspect})
        directory = storage.reserve(evidence.identity)
        report = Ace::TestRunner::Models::TestReport.new(result: result, files_tested: ['test/a_test.rb'])
        storage.save_report(report, format: :all, report_dir: directory)
      end
      evidence.publish(result, files: ['test/a_test.rb'], report_dir: directory)
      File.write(#{File.join(root, 'ready').inspect}, evidence.identity)
      if #{barrier}
        sleep 0.01 until File.exist?(#{File.join(root, 'release').inspect})
      end
      exit #{exit_code}
    RUBY
    [RbConfig.ruby, "-rbundler/setup", "-e", body]
  end

  def wait_for
    Timeout.timeout(15) { sleep 0.01 until yield }
  end

  def test_controlled_latest_replacement_cannot_change_captured_verdict_counts_or_links
    [false, true].product([false, true]).each do |failure, save_reports|
      Dir.mktmpdir do |root|
        File.write(File.join(root, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
        package = {"name" => "ace-sample", "path" => root, "entry_id" => "suite-entry"}
        monitor = FixtureMonitor.new
        monitor.command = fixture_command(root, failure: failure, saved: save_reports, barrier: true)
        final = nil
        monitor.start_package(package, {"save_reports" => save_reports}) { |_pkg, status, _out| final = status if status[:completed] }
        wait_for { File.exist?(File.join(root, "ready")) }
        child_id = File.read(File.join(root, "ready"))
        other = Evidence.new(package_path: root)
        other_dir = saved(other, passed: 25, failed: failure ? 0 : 1)
        assert_equal other_dir, File.realpath(File.join(root, "reports/latest"))
        File.write(File.join(root, "release"), "release")
        wait_for { monitor.check_processes; !monitor.running? }
        assert_equal !failure, final[:success]
        assert_equal failure ? 4 : 3, final.dig(:results, :tests)
        assert_equal 9, final.dig(:results, :assertions)
        assert_equal child_id, final.dig(:results, :execution_id)
        child_dir = save_reports ? File.join(root, "reports", child_id) : nil
        assert_equal child_dir, final.dig(:results, :report_dir)
        aggregate = Runner::Suite::ResultAggregator.new([package], runtime_results: {"suite-entry" => final})
        captured = aggregate.aggregate
        saved(Evidence.new(package_path: root), passed: 86)
        assert_equal captured, aggregate.aggregate
        assert_equal !failure, captured[:results].first[:success]
        assert_equal child_dir, captured[:results].first[:report_dir]
        assert_equal 9, captured[:total_assertions]
        if failure && save_reports
          assert_includes Runner::Molecules::FailedPackageReporter.format_for_display(captured[:failed_packages].first), child_id
        end
      ensure
        monitor&.stop_all
      end
    end
  end

  def test_nonzero_timeout_and_interruption_never_accept_passing_receipt
    [:exit, :timeout, :interrupt].each do |mode|
      Dir.mktmpdir do |root|
        File.write(File.join(root, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
        package = {"name" => "ace-sample", "path" => root, "entry_id" => "entry"}
        current_time = Time.now
        monitor = FixtureMonitor.new(package_timeout: 1, clock: -> { current_time })
        monitor.command = fixture_command(root, saved: false, exit_code: mode == :exit ? 9 : 0, barrier: mode != :exit)
        final = nil
        monitor.start_package(package, {"save_reports" => false}) { |_pkg, status, _out| final = status if status[:completed] }
        wait_for { File.exist?(File.join(root, "ready")) }
        if mode == :timeout
          current_time += 2
          monitor.check_processes
        elsif mode == :interrupt
          monitor.send(:terminate_process_group, monitor.processes.fetch("entry"), signal: "TERM", reason: :interrupt)
        end
        wait_for { monitor.check_processes; !monitor.running? }
        refute final[:success]
        assert_equal 3, final.dig(:results, :tests)
        assert_equal 9, final.dig(:results, :assertions)
        assert_match(mode == :exit ? /status 9/ : mode == :timeout ? /Timed out/ : /Interrupted/, final.dig(:results, :error))
      ensure
        monitor&.stop_all
      end
    end
  end
  def test_real_cli_children_duplicate_entries_saved_no_save_and_explicit_zero
    [true, false].each do |save_reports|
      [false, true].each do |zero|
        Dir.mktmpdir do |root|
          File.write(File.join(root, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
          FileUtils.mkdir_p(File.join(root, ".ace/test"))
          FileUtils.mkdir_p(File.join(root, "test"))
          File.write(File.join(root, ".ace/test/runner.yml"), YAML.dump({"version" => 1,
            "patterns" => {"probe" => "test/*_test.rb"}, "targets" => {"all" => ["probe"]},
            "execution" => {"mode" => "by-target", "target_isolation" => false}}))
          unless zero
            File.write(File.join(root, "test/probe_test.rb"), <<~RUBY)
              require "minitest/autorun"
              class Probe < Minitest::Test
                def test_pass
                  refute ENV.key?("ACE_TEST_EXECUTION")
                  assert true
                end
              end
            RUBY
          end
          # A concurrently published unrelated saved run is deliberately left at latest.
          stale_directory = saved(Evidence.new(package_path: root), passed: 25)
          stale_summary = File.read(File.join(stale_directory, "summary.json"))
          config = {"test_suite" => {"max_parallel" => 2,
            "packages" => 2.times.map { {"name" => "ace-probe", "path" => root} },
            "test_options" => {"target" => "all", "save_reports" => save_reports,
              "color" => false, "report_dir" => File.join(root, "reports")},
            "display" => {"color" => false}}}
          orchestrator = Runner::Suite::Orchestrator.new(config)
          code = nil
          output, = capture_io { code = orchestrator.run }
          assert_equal 0, code, output
          assert_equal 2, orchestrator.results.size
          summaries = orchestrator.results.values.map { |status| status[:results] }
          assert_equal 2, summaries.map { |result| result[:execution_id] }.uniq.length
          assert summaries.all? { |result| result[:tests] == (zero ? 0 : 1) }, output
          assert summaries.all? { |result| result[:assertions] == (zero ? 0 : 2) }, output
          assert_equal stale_summary, File.read(File.join(stale_directory, "summary.json"))
          completion_paths = summaries.map { |result| result[:completion_path] }
          assert completion_paths.all? { |path| File.file?(path) }
          if save_reports
            assert_equal 2, summaries.map { |result| result[:report_dir] }.uniq.length
            summaries.each do |result|
              assert File.file?(File.join(result[:report_dir], "summary.json"))
              assert_includes output, result[:report_dir]
            end
          else
            assert summaries.all? { |result| result[:report_dir].nil? }
            assert_equal [stale_directory], Dir.children(File.join(root, "reports")).reject { |name| name == "latest" }
              .map { |name| File.realpath(File.join(root, "reports", name)) }
            assert_includes output, "no saved report"
          end
          # Both displays retain distinct state and counts for identical labels.
          [Runner::Suite::SimpleDisplayManager, Runner::Suite::DisplayManager].each do |display_class|
            manager = display_class.new(orchestrator.packages, config)
            display_output, = capture_io do
              manager.initialize_display
              orchestrator.packages.each do |package|
                manager.update_package(package, orchestrator.results.fetch(package["entry_id"]))
              end
            end
            assert_equal 2, manager.instance_variable_get(:@package_status).size
            if display_class == Runner::Suite::DisplayManager
              assert_equal 2, manager.lines.values.uniq.size
            end
            assert_includes display_output, "#{zero ? 0 : 1} tests"
          end
        end
      end
    end
  end

  def test_zero_exit_without_receipt_cannot_become_zero_selection
    Dir.mktmpdir do |root|
      saved(Evidence.new(package_path: root), passed: 25)
      package = {"name" => "ace-sample", "path" => root}
      monitor = FixtureMonitor.new
      monitor.command = [RbConfig.ruby, "-e", "exit 0"]
      final = nil
      monitor.start_package(package, {"save_reports" => false}) { |_pkg, status, _out| final = status if status[:completed] }
      wait_for { monitor.check_processes; !monitor.running? }
      refute final[:success]
      assert_equal 0, final.dig(:results, :tests)
      assert_match(/completion evidence/, final.dig(:results, :error))
    ensure
      monitor&.stop_all
    end
  end

  def test_selected_but_unexecuted_success_is_not_explicit_zero_selection
    [true, false].each do |save_reports|
      Dir.mktmpdir do |root|
        evidence = Evidence.new(package_path: root)
        result = Runner::Models::TestResult.new
        files = ["test/selected_test.rb"]
        directory = nil
        if save_reports
          storage = Storage.new(base_dir: File.join(root, "reports"))
          directory = storage.reserve(evidence.identity)
          report = Runner::Models::TestReport.new(result: result, files_tested: files)
          storage.save_report(report, format: :all, report_dir: directory)
        end
        evidence.publish(result, files: files, report_dir: directory)
        assert_raises(Runner::Error) { evidence.read(pid: Process.pid, save_reports: save_reports) }
      end
    end
  end

  def test_actual_cli_selected_file_without_tests_fails_in_saved_and_no_save_modes
    [true, false].each do |save_reports|
      Dir.mktmpdir do |root|
        File.write(File.join(root, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
        FileUtils.mkdir_p(File.join(root, ".ace/test"))
        FileUtils.mkdir_p(File.join(root, "test"))
        File.write(File.join(root, "test/empty_test.rb"), "require 'minitest/autorun'\n")
        File.write(File.join(root, ".ace/test/runner.yml"), YAML.dump({"version" => 1,
          "patterns" => {"probe" => "test/*_test.rb"}, "targets" => {"all" => ["probe"]}}))
        monitor = Runner::Suite::ProcessMonitor.new
        package = {"name" => "ace-empty", "path" => root}
        final = nil
        monitor.start_package(package, {"target" => "all", "save_reports" => save_reports,
          "report_dir" => File.join(root, "reports")}) { |_pkg, status, _out| final = status if status[:completed] }
        wait_for { monitor.check_processes; !monitor.running? }
        refute final[:success]
        assert_equal 1, final[:exit_code]
        assert_equal 0, final.dig(:results, :tests)
        assert_equal 0, final.dig(:results, :errors)
        completion = JSON.parse(File.read(final.dig(:results, :completion_path)))
        assert_equal ["test/empty_test.rb"], completion["selected_files"]
        assert_equal false, completion["success"]
      ensure
        monitor&.stop_all
      end
    end
  end

end
