# frozen_string_literal: true

require_relative "../test_helper"

class ContextIntegrationTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @env = Ace::TestSupport::TestEnvironment.new("context")
    @env.setup
  end

  def teardown
    @env.teardown
  end

  def test_full_context_loading_with_config_cascade
    # Create project config
    @env.write_config(:project, "config.yml", {
      "context" => {
        "presets" => {
          "project_test" => {
            "include" => ["*.md"],
            "format" => "markdown"
          }
        }
      }
    }.to_yaml)

    # Create home config (should be overridden)
    @env.write_config(:home, "config.yml", {
      "context" => {
        "presets" => {
          "project_test" => {
            "include" => ["*.txt"],
            "format" => "yaml"
          }
        }
      }
    }.to_yaml)

    # Create test files
    @env.create_sample_file("README.md", "# Project")
    @env.create_sample_file("test.txt", "Text file")

    # Load using the API
    context = Ace::Context.load_preset("project_test")

    # Should use project config (*.md, not *.txt)
    assert_equal 1, context.file_count
    assert context.content.include?("Project")
    refute context.content.include?("Text file")
  end

  def test_list_presets_from_multiple_sources
    # Create configs at different levels
    @env.write_config(:project, "config.yml", {
      "context" => {
        "presets" => {
          "project_preset" => { "include" => ["*.md"] }
        }
      }
    }.to_yaml)

    @env.write_config(:home, "config.yml", {
      "context" => {
        "presets" => {
          "home_preset" => { "include" => ["*.txt"] }
        }
      }
    }.to_yaml)

    presets = Ace::Context.list_presets

    # Should have both presets (merged)
    names = presets.map { |p| p[:name] }
    assert names.include?("project_preset")
    assert names.include?("home_preset")
  end

  def test_load_file_api
    @env.create_sample_file("test.md", "# Test Content")
    full_path = File.join(@env.project_dir, "test.md")

    context = Ace::Context.load_file(full_path)

    assert_equal 1, context.file_count
    assert_equal "# Test Content", context.files.first[:content]
  end

  def test_handles_large_files
    # Create a file larger than max size
    large_content = "x" * (11 * 1024 * 1024)  # 11MB
    @env.create_sample_file("large.txt", large_content)
    full_path = File.join(@env.project_dir, "large.txt")

    context = Ace::Context.load_file(full_path)

    assert context.metadata[:error]
    assert context.metadata[:error].include?("too large")
  end
end