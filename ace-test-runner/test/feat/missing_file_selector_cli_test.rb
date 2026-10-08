# frozen_string_literal: true
require_relative "../test_helper"
require "open3"
require "tmpdir"

class MissingFileSelectorCliTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)

  def test_missing_explicit_file_refuses_before_any_suite_execution
    Dir.mktmpdir("missing-test-selector") do |package|
      FileUtils.mkdir_p(File.join(package, "test/fast/atoms"))
      File.write(File.join(package, "test/fast/atoms/probe_test.rb"), <<~RUBY_SOURCE)
        require "minitest/autorun"
        class UnwantedSuiteProbe < Minitest::Test
          def test_unwanted_execution
            File.write("executed", "suite started")
            assert true
          end
        end
      RUBY_SOURCE
      File.write(File.join(package, "Gemfile"), "eval_gemfile #{File.join(ROOT, 'Gemfile').inspect}\n")
      report_dir = File.join(package, "reports")
      output, error, status = Open3.capture3({"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile")},
        RbConfig.ruby, File.join(ROOT, "bin/ace-test"), package, "fast", "test/fast/atoms/typo_test.rb",
        "--report-dir", report_dir, chdir: ROOT)
      refute status.success?, output + error
      assert_match(/File not found: test\/fast\/atoms\/typo_test\.rb/, output + error)
      refute_match(/Running tests|Running \d+\/\d+ test files/, output + error)
      refute File.exist?(File.join(package, "executed")), "No suite test may execute"
      refute File.exist?(report_dir), "Orchestrator must not create a run report"
    end
  end
end
