# frozen_string_literal: true

require "simplecov" if ENV["COVERAGE"]

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/review"

require "minitest/autorun"
require "minitest/pride"

# Base test class
class AceReviewTest < Minitest::Test
  def setup
    @original_pwd = Dir.pwd
    @test_dir = Dir.mktmpdir("ace-review-test")
    Dir.chdir(@test_dir)
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.remove_entry(@test_dir)
  end

  # Helper to create a test configuration file
  def create_test_config(content = nil)
    FileUtils.mkdir_p(".ace/review")
    config_content = content || default_test_config
    File.write(".ace/review/code.yml", config_content)
  end

  # Helper to create a test preset file
  def create_test_preset(name, content)
    FileUtils.mkdir_p(".ace/review/presets")
    File.write(".ace/review/presets/#{name}.yml", content)
  end

  private

  def default_test_config
    <<~YAML
      defaults:
        model: "test-model"
        output_format: "markdown"
        context: "none"

      presets:
        test:
          description: "Test preset"
          prompt_composition:
            base: "prompt://base/system"
            format: "prompt://format/standard"
          context: "none"
          subject:
            commands:
              - "echo 'test diff'"
    YAML
  end
end