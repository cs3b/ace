# frozen_string_literal: true
require_relative "../test_helper"
require "open3"
require "tmpdir"
require "yaml"

class DefaultTargetSelectionCliTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  CLI = File.join(ROOT, "bin", "ace-test")
  PATHS = %w[fast/atoms/a fast/authority/b fast/new/nested/c fast/edge/d atoms/e edge/f feat/g e2e/h].freeze

  def with_package(failure: false, narrow: false)
    Dir.mktmpdir("default-target-selection") do |root|
      PATHS.each_with_index do |path, index|
        file = File.join(root, "test", "#{path}_test.rb")
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, <<~SOURCE)
          require "minitest/autorun"
          class SelectionProbe#{index} < Minitest::Test
            def test_selected
              File.open("executed", "a") { |f| f.puts #{path.inspect} }
              assert #{!(failure && index == 1)}
            end
          end
        SOURCE
      end
      File.write(File.join(root, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
      if narrow
        FileUtils.mkdir_p(File.join(root, ".ace", "test"))
        File.write(File.join(root, ".ace/test/runner.yml"), YAML.dump({"targets" => {"all" => ["fast"]}}))
      end
      yield root
    end
  end

  def check(root, target:, expected:, batch: false, success: true)
    args = [target, "--subprocess", "--no-fail-fast", "--no-color", "--report-dir", File.join(root, "reports")]
    args << "--run-in-single-batch" if batch
    stdout, stderr, status = Open3.capture3({"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile")},
      RbConfig.ruby, CLI, root, *args, chdir: ROOT)
    assert_equal success, status.success?, stdout + stderr
    executed = File.readlines(File.join(root, "executed"), chomp: true)
    assert_equal expected.sort, executed.sort
    assert_equal executed.uniq.size, executed.size
    reports = Dir.glob(File.join(root, "reports", "**", "report.json"))
    assert_equal 1, reports.size
    report = JSON.parse(File.read(reports.first))
    assert_equal success, report.dig("result", "success")
    actual = report.fetch("files_tested").map { |file| file.delete_prefix(root + "/").delete_prefix("test/").delete_suffix("_test.rb") }
    assert_equal expected.sort, actual.sort
  end

  def test_complete_selection_once_in_both_execution_modes
    [false, true].each do |batch|
      with_package { |root| check(root, target: "all", expected: PATHS.take(7), batch: batch) }
    end
  end

  def test_narrow_override_and_explicit_category_keep_their_scope
    with_package(narrow: true) { |root| check(root, target: "all", expected: PATHS.take(5)) }
    with_package { |root| check(root, target: "atoms", expected: [PATHS[0], PATHS[4]]) }
  end

  def test_uncategorized_failure_is_an_executed_nonzero_verdict
    with_package(failure: true) { |root| check(root, target: "all", expected: PATHS.take(5), success: false) }
  end
end
