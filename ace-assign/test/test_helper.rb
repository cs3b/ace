# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/assign"

require "minitest/autorun"
require "ace/test_support"
require "fileutils"
require "tmpdir"

class AceAssignTestCase < AceTestCase
  # Create a temporary directory for test assignments
  def with_temp_cache
    Dir.mktmpdir("ace-assign-test") do |dir|
      yield dir
    end
  end

  # Create a test assignment config
  def create_test_config(dir, steps: nil, name: "test-session")
    steps ||= [
      { "name" => "init", "instructions" => "Initialize project" },
      { "name" => "build", "instructions" => "Build the project" },
      { "name" => "test", "instructions" => "Run tests" }
    ]

    config = {
      "session" => {
        "name" => name,
        "description" => "Test workflow"
      },
      "steps" => steps
    }

    config_path = File.join(dir, "job-#{name}.yaml")
    File.write(config_path, config.to_yaml)
    config_path
  end

  # Create a test report file
  def create_report(dir, content = "Test report")
    report_path = File.join(dir, "report.md")
    File.write(report_path, content)
    report_path
  end
end
