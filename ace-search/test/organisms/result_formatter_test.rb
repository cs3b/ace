# frozen_string_literal: true

require "test_helper"

module Ace
  module Search
    module Organisms
      class TestResultFormatter < AceSearchTestCase
        def test_format_text_with_file_results
          results = [
            {type: :file, path: "lib/test.rb"},
            {type: :file, path: "lib/other.rb"}
          ]

          output = ResultFormatter.format(results, format: :text)

          assert_match(/lib\/test\.rb/, output)
          assert_match(/lib\/other\.rb/, output)
        end

        def test_format_text_with_match_results
          results = [
            {type: :match, path: "lib/test.rb", line: 10, column: 0, text: "def initialize"},
            {type: :match, path: "lib/test.rb", line: 20, column: 2, text: "  @name = value"}
          ]

          output = ResultFormatter.format(results, format: :text)

          assert_match(/lib\/test\.rb:10:0:/, output)
          assert_match(/def initialize/, output)
          assert_match(/lib\/test\.rb:20:2:/, output)
          assert_match(/@name = value/, output)
        end

        def test_format_json
          results = [
            {type: :file, path: "test.rb"},
            {type: :match, path: "other.rb", line: 5, text: "code"}
          ]

          output = ResultFormatter.format(results, format: :json)
          json = JSON.parse(output)

          assert_equal 2, json["count"]
          assert_equal 2, json["results"].size
          assert_equal "test.rb", json["results"][0]["path"]
        end

        def test_format_yaml
          results = [
            {type: :file, path: "test.rb"}
          ]

          output = ResultFormatter.format(results, format: :yaml)

          assert_match(/count: 1/, output)
          assert_match(/test\.rb/, output)
        end

        def test_format_empty_results
          output = ResultFormatter.format([], format: :text)

          assert_equal "No results found", output
        end

        def test_format_summary
          results = [{type: :file, path: "test.rb"}]
          options = {mode: :file, pattern: "*.rb", glob: "lib/**"}

          summary = ResultFormatter.format_summary(results, options)

          assert_match(/Found 1 results/, summary)
          assert_match(/mode: file/, summary)
          assert_match(/pattern: "\*\.rb"/, summary)
          assert_match(/glob: lib\/\*\*/, summary)
        end
      end
    end
  end
end
