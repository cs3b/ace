# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/models/resource_uri"

module Ace
  module Support
    module Nav
      module Models
        class ResourceUriTest < Minitest::Test
          def setup
            @test_dir = setup_test_environment
            @config_loader = create_test_config_loader(@test_dir)

            # Create additional test protocols for compatibility
            create_test_protocol(@test_dir, "wfi", {
              "extensions" => [".wfi.md", ".workflow.md", ".wf.md"]
            })
            create_test_protocol(@test_dir, "task", {
              "extensions" => [".md"]
            })

            # Need to reload config after adding protocols
            @config_loader = create_test_config_loader(@test_dir)
          end

          def teardown
            cleanup_temp_directory(@test_dir)
          end

          def test_parses_cascade_search_uri
            uri = ResourceUri.new("test://setup", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "test", uri.protocol
            assert_nil uri.source
            assert_equal "setup", uri.path
            assert uri.cascade_search?
            refute uri.source_specific?
          end

          def test_parses_source_specific_uri
            uri = ResourceUri.new("test://@local/setup", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "test", uri.protocol
            assert_equal "@local", uri.source
            assert_equal "setup", uri.path
            refute uri.cascade_search?
            assert uri.source_specific?
          end

          def test_parses_source_without_path
            uri = ResourceUri.new("example://@local", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "example", uri.protocol
            assert_equal "@local", uri.source
            assert_nil uri.path
          end

          def test_parses_path_with_subdirectories
            uri = ResourceUri.new("test://admin/users/setup", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "test", uri.protocol
            assert_nil uri.source
            assert_equal "admin/users/setup", uri.path
          end

          def test_validates_protocol
            # Invalid protocol
            uri = ResourceUri.new("xyz://something", config_loader: @config_loader)

            refute uri.valid?
            assert_equal "xyz", uri.protocol
          end

          def test_handles_task_protocol
            uri = ResourceUri.new("task://018", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "task", uri.protocol
            assert_nil uri.source
            assert_equal "018", uri.path
          end

          def test_handles_wfi_protocol
            uri = ResourceUri.new("wfi://setup", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "wfi", uri.protocol
            assert_nil uri.source
            assert_equal "setup", uri.path
          end

          def test_to_h_output
            uri = ResourceUri.new("test://@local/setup", config_loader: @config_loader)
            hash = uri.to_h

            assert_equal "test://@local/setup", hash[:raw]
            assert_equal "test", hash[:protocol]
            assert_equal "@local", hash[:source]
            assert_equal "setup", hash[:path]
            assert hash[:source_specific]
            refute hash[:cascade_search]
          end

          def test_handles_special_source_aliases
            # Test with @project alias
            uri = ResourceUri.new("test://@project/resource", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "@project", uri.source
            assert uri.source_specific?
          end

          def test_handles_complex_paths
            uri = ResourceUri.new("example://deeply/nested/path/to/resource", config_loader: @config_loader)

            assert uri.valid?
            assert_equal "example", uri.protocol
            assert_nil uri.source
            assert_equal "deeply/nested/path/to/resource", uri.path
          end

          def test_raw_uri_preserved
            raw = "test://@local/path/to/resource"
            uri = ResourceUri.new(raw, config_loader: @config_loader)

            assert_equal raw, uri.raw
            assert_equal raw, uri.to_s
          end
        end
      end
    end
  end
end
