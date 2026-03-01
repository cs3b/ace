# frozen_string_literal: true

require "test_helper"

class RetroConfigLoaderTest < AceRetroTestCase
  def test_loads_default_config
    config = Ace::Retro::Molecules::RetroConfigLoader.load
    assert config.is_a?(Hash)
    assert_equal ".ace-retros", config.dig("retro", "root_dir")
  end

  def test_root_dir_returns_absolute_path
    config = Ace::Retro::Molecules::RetroConfigLoader.load
    root = Ace::Retro::Molecules::RetroConfigLoader.root_dir(config)
    assert root.start_with?("/"), "Expected absolute path, got: #{root}"
    assert root.end_with?(".ace-retros")
  end

  def test_default_root_dir_when_no_config
    root = Ace::Retro::Molecules::RetroConfigLoader.root_dir({})
    assert root.end_with?(".ace-retros")
  end

  def test_default_status_config
    config = Ace::Retro::Molecules::RetroConfigLoader.load
    assert_equal "active", config.dig("retro", "default_status")
  end

  def test_default_type_config
    config = Ace::Retro::Molecules::RetroConfigLoader.load
    assert_equal "standard", config.dig("retro", "default_type")
  end
end
