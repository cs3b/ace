# frozen_string_literal: true

require_relative "test_helper"

class Ace::CoreTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ace::Core::VERSION
  end

  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+/, ::Ace::Core::VERSION)
  end

  def test_config_method_exists
    assert_respond_to Ace::Core, :config
  end

  def test_get_method_exists
    assert_respond_to Ace::Core, :get
  end

  def test_environment_method_exists
    assert_respond_to Ace::Core, :environment
  end

  def test_resolve_defaults_dir_prefers_ace_defaults
    # Reset config to ensure fresh state
    Ace::Core.reset_config!

    Dir.mktmpdir do |temp_dir|
      # Create both directories
      ace_defaults = File.join(temp_dir, ".ace-defaults")
      ace_example = File.join(temp_dir, ".ace.example")
      Dir.mkdir(ace_defaults)
      Dir.mkdir(ace_example)

      # Stub gem_root_path to return temp_dir
      Ace::Core.stub(:gem_root_path, temp_dir) do
        result = Ace::Core.send(:resolve_defaults_dir)
        assert_equal ".ace-defaults", result
      end
    end
  ensure
    Ace::Core.reset_config!
  end

  def test_resolve_defaults_dir_falls_back_to_ace_example
    # Reset config to ensure fresh state
    Ace::Core.reset_config!

    Dir.mktmpdir do |temp_dir|
      # Create only .ace.example (legacy)
      ace_example = File.join(temp_dir, ".ace.example")
      Dir.mkdir(ace_example)

      # Stub gem_root_path to return temp_dir
      Ace::Core.stub(:gem_root_path, temp_dir) do
        result = Ace::Core.send(:resolve_defaults_dir)
        assert_equal ".ace.example", result
      end
    end
  ensure
    Ace::Core.reset_config!
  end

  def test_resolve_defaults_dir_defaults_to_ace_defaults_when_neither_exists
    # Reset config to ensure fresh state
    Ace::Core.reset_config!

    Dir.mktmpdir do |temp_dir|
      # Neither directory exists

      # Stub gem_root_path to return temp_dir
      Ace::Core.stub(:gem_root_path, temp_dir) do
        result = Ace::Core.send(:resolve_defaults_dir)
        assert_equal ".ace-defaults", result
      end
    end
  ensure
    Ace::Core.reset_config!
  end
end
