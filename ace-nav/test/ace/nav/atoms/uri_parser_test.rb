# frozen_string_literal: true

require "test_helper"
require "ace/nav/atoms/uri_parser"

module Ace
  module Nav
    module Atoms
      class UriParserTest < Minitest::Test
        def setup
          @parser = UriParser.new
        end

        def test_parses_simple_uri
          result = @parser.parse("wfi://setup")

          assert_equal "wfi", result[:protocol]
          assert_nil result[:source]
          assert_equal "setup", result[:path]
        end

        def test_parses_source_specific_uri
          result = @parser.parse("tmpl://@ace-test/minitest")

          assert_equal "tmpl", result[:protocol]
          assert_equal "@ace-test", result[:source]
          assert_equal "minitest", result[:path]
        end

        def test_parses_source_only_uri
          result = @parser.parse("guide://@project")

          assert_equal "guide", result[:protocol]
          assert_equal "@project", result[:source]
          assert_nil result[:path]
        end

        def test_returns_nil_for_invalid_uri
          assert_nil @parser.parse("not-a-uri")
          assert_nil @parser.parse("invalid://something")
        end

        def test_validates_protocols
          assert @parser.valid_protocol?("wfi")
          assert @parser.valid_protocol?("tmpl")
          assert @parser.valid_protocol?("guide")
          assert @parser.valid_protocol?("sample")
          assert @parser.valid_protocol?("task")
          refute @parser.valid_protocol?("invalid")
        end

        def test_extracts_protocol
          assert_equal "wfi", @parser.extract_protocol("wfi://setup")
          assert_equal "task", @parser.extract_protocol("task://018")
          assert_nil @parser.extract_protocol("not-a-uri")
        end
      end
    end
  end
end