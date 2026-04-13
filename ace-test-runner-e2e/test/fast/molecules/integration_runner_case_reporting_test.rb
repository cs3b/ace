# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"

class IntegrationRunnerCaseReportingTest < Minitest::Test
  Status = Struct.new(:success?, :exitstatus)

  def test_returns_synthetic_integration_result_for_passing_file
    Dir.mktmpdir do |tmpdir|
      file = File.join(tmpdir, "ace-demo", "test", "integration", "sample_test.rb")
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, "# test")

      package_copy = Object.new
      package_copy.define_singleton_method(:prepare) do |package_name:, sandbox_root:|
        FileUtils.mkdir_p(File.join(sandbox_root, package_name))
        {env: {"PROJECT_ROOT_PATH" => File.join(sandbox_root, package_name)}}
      end

      runner = Ace::Test::EndToEndRunner::Molecules::IntegrationRunner.new(
        base_dir: tmpdir,
        package_copy: package_copy
      )

      Open3.stub(:capture3, ["ok", "", Status.new(true, 0)]) do
        result = runner.run(package: "ace-demo", files: [file], timestamp: "abc123", output: StringIO.new)

        assert_equal "INTEGRATION", result.test_id
        assert_equal "pass", result.status
        assert_equal "integration", result.metadata[:phase]
        assert_equal "test/integration/sample_test.rb", result.test_cases.first[:id]
        assert_equal "pass", result.test_cases.first[:status]
      end
    end
  end

  def test_marks_failed_files_when_ace_test_fails
    Dir.mktmpdir do |tmpdir|
      file = File.join(tmpdir, "ace-demo", "test", "integration", "broken_test.rb")
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, "# test")

      package_copy = Object.new
      package_copy.define_singleton_method(:prepare) do |package_name:, sandbox_root:|
        FileUtils.mkdir_p(File.join(sandbox_root, package_name))
        {env: {"PROJECT_ROOT_PATH" => File.join(sandbox_root, package_name)}}
      end

      runner = Ace::Test::EndToEndRunner::Molecules::IntegrationRunner.new(
        base_dir: tmpdir,
        package_copy: package_copy
      )

      Open3.stub(:capture3, ["", "failure", Status.new(false, 1)]) do
        result = runner.run(package: "ace-demo", files: [file], timestamp: "abc123", output: StringIO.new)

        assert_equal "fail", result.status
        assert_equal "fail", result.test_cases.first[:status]
        assert_equal 1, result.test_cases.first[:metadata][:exit_status]
      end
    end
  end
end
