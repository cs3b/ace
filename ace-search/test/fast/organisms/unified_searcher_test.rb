# frozen_string_literal: true

require "test_helper"

module Ace
  module Search
    module Organisms
      class UnifiedSearcherTest < AceSearchTestCase
        class FakeRipgrepExecutor
          def initialize(stdout)
            @stdout = stdout
          end

          def execute(_pattern, _options)
            {
              success: true,
              stdout: @stdout,
              stderr: "",
              exit_code: 0
            }
          end
        end

        def test_search_content_with_files_with_matches_returns_file_results
          searcher = UnifiedSearcher.new
          searcher.instance_variable_set(:@rg_executor, FakeRipgrepExecutor.new(<<~OUTPUT))
            lib/file_one.rb
            lib/file_two.rb
            test/example_test.rb
          OUTPUT

          results = searcher.search("TODO", files_with_matches: true)

          assert results[:success]
          assert_equal 3, results[:count]
          assert_equal :file, results[:results].first[:type]
          assert_equal "lib/file_one.rb", results[:results].first[:path]
        end
      end
    end
  end
end
