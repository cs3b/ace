# frozen_string_literal: true

require "test_helper"

module Ace
  module Search
    module Atoms
      class TestResultParser < AceSearchTestCase
        def test_parse_ripgrep_text_output
          output = <<~OUTPUT
            file.rb:10:def initialize
            file.rb:20:  @name = "test"
            other.rb:5:class Foo
          OUTPUT

          results = ResultParser.parse_ripgrep_output(output, :text)

          assert_equal 3, results.size
          assert_equal "file.rb", results[0][:path]
          assert_equal 10, results[0][:line]
          assert_equal "def initialize", results[0][:text]
        end

        def test_parse_ripgrep_files_only
          output = <<~OUTPUT
            file1.rb
            file2.rb
            file3.rb
          OUTPUT

          results = ResultParser.parse_ripgrep_output(output, :files_only)

          assert_equal 3, results.size
          assert_equal :file, results[0][:type]
          assert_equal "file1.rb", results[0][:path]
        end

        def test_parse_fd_output
          output = <<~OUTPUT
            ./lib/file1.rb
            ./lib/file2.rb
            ./test/test_file.rb
          OUTPUT

          results = ResultParser.parse_fd_output(output)

          assert_equal 3, results.size
          assert_equal :file, results[0][:type]
          assert_equal "./lib/file1.rb", results[0][:path]
          assert_equal "file1.rb", results[0][:basename]
          assert_equal "rb", results[0][:extension]
        end

        def test_parse_empty_output
          assert_empty ResultParser.parse_ripgrep_output("", :text)
          assert_empty ResultParser.parse_fd_output("")
        end

        def test_parse_ripgrep_with_column_numbers
          output = "file.rb:10:5:def initialize"

          results = ResultParser.parse_ripgrep_output(output, :text)

          assert_equal 1, results.size
          assert_equal "file.rb", results[0][:path]
          assert_equal 10, results[0][:line]
          assert_equal 5, results[0][:column]
        end
      end
    end
  end
end
