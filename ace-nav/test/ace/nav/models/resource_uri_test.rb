# frozen_string_literal: true

require "test_helper"
require "ace/nav/models/resource_uri"

module Ace
  module Nav
    module Models
      class ResourceUriTest < Minitest::Test
        def test_parses_cascade_search_uri
          uri = ResourceUri.new("wfi://setup")

          assert uri.valid?
          assert_equal "wfi", uri.protocol
          assert_nil uri.source
          assert_equal "setup", uri.path
          assert uri.cascade_search?
          refute uri.source_specific?
        end

        def test_parses_source_specific_uri
          uri = ResourceUri.new("wfi://@ace-git/setup")

          assert uri.valid?
          assert_equal "wfi", uri.protocol
          assert_equal "@ace-git", uri.source
          assert_equal "setup", uri.path
          refute uri.cascade_search?
          assert uri.source_specific?
        end

        def test_parses_source_without_path
          uri = ResourceUri.new("wfi://@ace-git")

          assert uri.valid?
          assert_equal "wfi", uri.protocol
          assert_equal "@ace-git", uri.source
          assert_nil uri.path
        end

        def test_parses_path_with_subdirectories
          uri = ResourceUri.new("wfi://admin/users/setup")

          assert uri.valid?
          assert_equal "wfi", uri.protocol
          assert_nil uri.source
          assert_equal "admin/users/setup", uri.path
        end

        def test_validates_protocol
          uri = ResourceUri.new("xyz://something")

          refute uri.valid?
          assert_equal "xyz", uri.protocol
        end

        def test_handles_task_protocol
          uri = ResourceUri.new("task://018")

          assert uri.valid?
          assert_equal "task", uri.protocol
          assert_nil uri.source
          assert_equal "018", uri.path
        end

        def test_to_h_output
          uri = ResourceUri.new("wfi://@ace-git/setup")
          hash = uri.to_h

          assert_equal "wfi://@ace-git/setup", hash[:raw]
          assert_equal "wfi", hash[:protocol]
          assert_equal "@ace-git", hash[:source]
          assert_equal "setup", hash[:path]
          assert hash[:source_specific]
          refute hash[:cascade_search]
        end
      end
    end
  end
end