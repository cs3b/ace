# frozen_string_literal: true

require_relative "../test_helper"

class ContextLoaderTest < AceTestCase
  # Setup removed - loader created in each test after config

  def test_loads_default_preset
    with_temp_dir do
      # Create sample files
      File.write("README.md", "# Test Project")
      FileUtils.mkdir_p("docs")
      File.write("docs/blueprint.md", "# Blueprint")

      # Create config
      FileUtils.mkdir_p(".ace")
      File.write(".ace/context.yml", {
        "context" => {
          "presets" => {
            "default" => {
              "include" => ["README.md", "docs/*.md"],
              "format" => "markdown"
            }
          }
        }
      }.to_yaml)

      loader = Ace::Context::Organisms::ContextLoader.new
      context = loader.load_preset("default")

      assert_equal 2, context.file_count
      assert context.content.include?("Test Project")
      assert context.content.include?("Blueprint")
    end
  end

  def test_loads_file_directly
    with_temp_file("Test content") do |path|
      loader = Ace::Context::Organisms::ContextLoader.new
      context = loader.load_file(path)

      assert_equal 1, context.file_count
      assert_equal "Test content", context.files.first[:content]
    end
  end

  def test_handles_missing_preset
    loader = Ace::Context::Organisms::ContextLoader.new
    context = loader.load_preset("nonexistent")

    assert_equal "nonexistent", context.preset_name
    assert_equal "Preset 'nonexistent' not found", context.metadata[:error]
  end

  def test_applies_exclusions
    with_temp_dir do
      # Create files
      File.write("include.md", "Include this")
      FileUtils.mkdir_p("exclude")
      File.write("exclude/skip.md", "Skip this")

      # Create config with exclusions
      FileUtils.mkdir_p(".ace")
      File.write(".ace/context.yml", {
        "context" => {
          "presets" => {
            "test" => {
              "include" => ["**/*.md"],
              "exclude" => ["exclude/**"],
              "format" => "markdown"
            }
          }
        }
      }.to_yaml)

      loader = Ace::Context::Organisms::ContextLoader.new
      context = loader.load_preset("test")

      assert_equal 1, context.file_count
      assert context.content.include?("Include this")
      refute context.content.include?("Skip this")
    end
  end

  def test_formats_as_yaml
    with_temp_dir do
      File.write("test.txt", "Content")

      FileUtils.mkdir_p(".ace")
      File.write(".ace/context.yml", {
        "context" => {
          "presets" => {
            "yaml_test" => {
              "include" => ["test.txt"],
              "format" => "yaml"
            }
          }
        }
      }.to_yaml)

      loader = Ace::Context::Organisms::ContextLoader.new
      context = loader.load_preset("yaml_test")

      assert context.content.include?("preset_name: yaml_test")
      assert context.content.include?("files:")
    end
  end
end