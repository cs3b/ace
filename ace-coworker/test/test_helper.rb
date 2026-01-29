# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/coworker"

require "minitest/autorun"
require "ace/test_support"
require "fileutils"
require "tmpdir"

class AceCoworkerTestCase < AceTestCase
  # Create a temporary directory for test sessions
  def with_temp_cache
    Dir.mktmpdir("ace-coworker-test") do |dir|
      yield dir
    end
  end

  # Create a test job config
  def create_test_config(dir, steps: nil)
    steps ||= [
      { "name" => "init", "instructions" => "Initialize project" },
      { "name" => "build", "instructions" => "Build the project" },
      { "name" => "test", "instructions" => "Run tests" }
    ]

    config = {
      "session" => {
        "name" => "test-session",
        "description" => "Test workflow"
      },
      "steps" => steps
    }

    config_path = File.join(dir, "job.yaml")
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
