# frozen_string_literal: true

require "test_helper"

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
end
