# frozen_string_literal: true

require "test_helper"

module Ace
  module Search
    module Atoms
      class TestPatternAnalyzer < AceSearchTestCase
        def test_analyze_file_glob_pattern
          result = PatternAnalyzer.analyze_pattern("*.rb")

          assert_equal :file_glob, result[:type]
          assert result[:confidence] > 0.5
          assert_equal "fd", result[:suggested_tool]
        end

        def test_analyze_content_regex_pattern
          result = PatternAnalyzer.analyze_pattern("def\\s+initialize")

          assert_includes [:content_regex, :hybrid], result[:type]
          assert result[:confidence] > 0.5
          assert_equal "rg", result[:suggested_tool]
        end

        def test_analyze_literal_pattern
          result = PatternAnalyzer.analyze_pattern("function_name")

          assert_includes [:literal, :content_regex], result[:type]
          assert result[:confidence] > 0.5
        end

        def test_analyze_hybrid_pattern
          result = PatternAnalyzer.analyze_pattern("controller")

          assert_includes [:hybrid, :literal], result[:type]
        end

        def test_file_glob_pattern_detection
          assert PatternAnalyzer.file_glob_pattern?("*.rb")
          assert PatternAnalyzer.file_glob_pattern?("**/*.js")
          refute PatternAnalyzer.file_glob_pattern?("class Foo")
        end

        def test_content_regex_pattern_detection
          assert PatternAnalyzer.content_regex_pattern?("def\\s+initialize")
          assert PatternAnalyzer.content_regex_pattern?("class\\s+\\w+")
          assert PatternAnalyzer.content_regex_pattern?("(foo|bar)")
          refute PatternAnalyzer.content_regex_pattern?("*.rb")
        end

        def test_suggest_search_mode
          assert_equal :files, PatternAnalyzer.suggest_search_mode("*.rb", {})
          assert_equal :content, PatternAnalyzer.suggest_search_mode("TODO", {})
          assert_equal :files, PatternAnalyzer.suggest_search_mode("foo", {files_only: true})
          assert_equal :content, PatternAnalyzer.suggest_search_mode("*.rb", {content_only: true})
        end

        def test_extract_extensions
          extensions = PatternAnalyzer.extract_extensions("*.rb")
          assert_includes extensions, "rb"

          # Note: The simple regex doesn't parse {js,ts} syntax
          extensions = PatternAnalyzer.extract_extensions("**/*.js")
          assert_includes extensions, "js"
        end
      end
    end
  end
end
