# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Support
    module Nav
      class NavTest < Minitest::Test
        def test_module_exists
          assert_kind_of Module, ::Ace::Support::Nav
        end

        def test_version_format
          assert_match(/\A\d+\.\d+\.\d+\z/, ::Ace::Support::Nav::VERSION)
          refute_empty ::Ace::Support::Nav::VERSION
        end

        def test_version_is_frozen_string
          assert ::Ace::Support::Nav::VERSION.frozen?
        end

        def test_config_method_exists
          assert_respond_to ::Ace::Support::Nav, :config
        end

        def test_cli_module_exists
          assert_kind_of Module, ::Ace::Support::Nav::CLI
        end

        def test_navigation_engine_class_exists
          assert_kind_of Class, ::Ace::Support::Nav::Organisms::NavigationEngine
        end
      end
    end
  end
end
