# frozen_string_literal: true

require "test_helper"

module Ace
  module Search
    module Models
      class TestSearchResult < AceSearchTestCase
        def test_create_file_result
          result = SearchResult.file("lib/test.rb")

          assert result.file?
          refute result.match?
          refute result.directory?
          assert_equal "lib/test.rb", result.path
          assert_equal "test.rb", result.basename
          assert_equal "lib", result.dirname
          assert_equal "rb", result.extension
        end

        def test_create_match_result
          result = SearchResult.match("lib/test.rb", 10, "def initialize", column: 2)

          refute result.file?
          assert result.match?
          refute result.directory?
          assert_equal "lib/test.rb", result.path
          assert_equal 10, result.line_number
          assert_equal "def initialize", result.content
          assert_equal 2, result.column
        end

        def test_create_directory_result
          result = SearchResult.directory("lib/")

          refute result.file?
          refute result.match?
          assert result.directory?
          assert_equal "lib/", result.path
        end

        def test_to_h_conversion
          result = SearchResult.match("file.rb", 5, "code", column: 10)
          hash = result.to_h

          assert_equal :match, hash[:type]
          assert_equal "file.rb", hash[:path]
          assert_equal 5, hash[:line_number]
          assert_equal "code", hash[:content]
          assert_equal 10, hash[:column]
        end

        def test_equality
          result1 = SearchResult.file("test.rb")
          result2 = SearchResult.file("test.rb")
          result3 = SearchResult.file("other.rb")

          assert_equal result1, result2
          refute_equal result1, result3
        end

        def test_extension_without_dot
          result = SearchResult.file("test.rb")
          assert_equal "rb", result.extension

          result = SearchResult.file("Makefile")
          assert_equal "", result.extension
        end
      end
    end
  end
end
