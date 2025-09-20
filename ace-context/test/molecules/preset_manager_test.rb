# frozen_string_literal: true

require_relative "../test_helper"

class PresetManagerTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def test_loads_default_preset
    manager = Ace::Context::Molecules::PresetManager.new

    preset = manager.get_preset("default")

    assert preset
    assert_equal "default", preset[:name]
    assert preset[:include].include?("README.md")
  end

  def test_lists_presets
    with_temp_dir do
      config = {
        "context" => {
          "presets" => {
            "test1" => { "include" => ["*.md"] },
            "test2" => { "include" => ["*.rb"] }
          }
        }
      }

      FileUtils.mkdir_p(".ace/context/config")
      File.write(".ace/context/config/context.yml", config.to_yaml)

      manager = Ace::Context::Molecules::PresetManager.new
      presets = manager.list_presets

      assert_equal 2, presets.size
      assert presets.any? { |p| p[:name] == "test1" }
      assert presets.any? { |p| p[:name] == "test2" }
    end
  end

  def test_preset_exists_check
    manager = Ace::Context::Molecules::PresetManager.new

    assert manager.preset_exists?("default")
    refute manager.preset_exists?("nonexistent")
  end

  def test_handles_missing_config_gracefully
    with_temp_dir do
      # No config files exist
      manager = Ace::Context::Molecules::PresetManager.new

      # Should fall back to default config
      preset = manager.get_preset("default")
      assert preset
    end
  end

  def test_preset_with_metadata
    with_temp_dir do
      config = {
        "context" => {
          "presets" => {
            "meta_test" => {
              "include" => ["*.md"],
              "metadata" => {
                "author" => "Test",
                "version" => "1.0"
              }
            }
          }
        }
      }

      FileUtils.mkdir_p(".ace/context/config")
      File.write(".ace/context/config/context.yml", config.to_yaml)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("meta_test")

      assert_equal "Test", preset[:metadata]["author"]
      assert_equal "1.0", preset[:metadata]["version"]
    end
  end
end