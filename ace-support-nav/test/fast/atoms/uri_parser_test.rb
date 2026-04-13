# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/support/nav/atoms/uri_parser"

module Ace
  module Support
    module Nav
      module Atoms
        class UriParserTest < Minitest::Test
          def setup
            @test_dir = setup_test_environment
            @config_loader = create_test_config_loader(@test_dir)
            @parser = UriParser.new(config_loader: @config_loader)
          end

          def teardown
            cleanup_temp_directory(@test_dir)
          end

          def test_parses_simple_uri
            result = @parser.parse("test://setup")

            assert_equal "test", result[:protocol]
            assert_nil result[:source]
            assert_equal "setup", result[:path]
          end

          def test_parses_source_specific_uri
            result = @parser.parse("test://@local/sample")

            assert_equal "test", result[:protocol]
            assert_equal "@local", result[:source]
            assert_equal "sample", result[:path]
          end

          def test_parses_source_only_uri
            result = @parser.parse("example://@project")

            assert_equal "example", result[:protocol]
            assert_equal "@project", result[:source]
            assert_nil result[:path]
          end

          def test_returns_nil_for_invalid_uri
            assert_nil @parser.parse("not-a-uri")
            assert_nil @parser.parse("invalid://something")
          end

          def test_validates_protocols_dynamically
            # Test protocols are created in test environment
            assert @parser.valid_protocol?("test")
            assert @parser.valid_protocol?("example")

            # Non-existent protocol
            refute @parser.valid_protocol?("nonexistent")
          end

          def test_extracts_protocol
            assert_equal "test", @parser.extract_protocol("test://setup")
            assert_equal "example", @parser.extract_protocol("example://demo")
            assert_nil @parser.extract_protocol("not-a-uri")
          end

          def test_handles_path_with_subdirectories
            result = @parser.parse("test://admin/users/setup")

            assert_equal "test", result[:protocol]
            assert_nil result[:source]
            assert_equal "admin/users/setup", result[:path]
          end

          def test_handles_source_with_complex_path
            result = @parser.parse("test://@local/admin/users/setup")

            assert_equal "test", result[:protocol]
            assert_equal "@local", result[:source]
            assert_equal "admin/users/setup", result[:path]
          end

          def test_valid_protocols_returns_dynamic_list
            protocols = @parser.valid_protocols

            # Test protocols should be included (test directory protocols)
            assert_includes protocols, "test"
            assert_includes protocols, "example"
            # At least 2 protocols (test + example), possibly more from gem defaults
            assert protocols.size >= 2, "Expected at least 2 protocols, got #{protocols.size}"
          end

          def test_handles_disabled_protocol
            # Create a disabled protocol
            create_test_protocol(@test_dir, "disabled", {
              "enabled" => false
            })

            # Reload config
            @config_loader = create_test_config_loader(@test_dir)
            @parser = UriParser.new(config_loader: @config_loader)

            # Disabled protocol should still be valid (just not used)
            assert @parser.valid_protocol?("disabled")
          end
        end
      end
    end
  end
end
