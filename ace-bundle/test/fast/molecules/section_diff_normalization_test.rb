# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../../lib/ace/bundle"
require_relative "../../../lib/ace/bundle/molecules/section_processor"

module Ace
  module Bundle
    class SectionDiffNormalizationTest < Minitest::Test
      def setup
        @processor = Molecules::SectionProcessor.new
      end

      # Test simple diffs format
      def test_normalizes_simple_diffs_array
        section = {
          "title" => "Changes",
          "diffs" => ["origin/main...HEAD", "HEAD~5...HEAD"]
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD", "HEAD~5...HEAD"], normalized[:ranges]
        refute normalized.key?(:diffs), "diffs key should be removed after normalization"
      end

      # Test complex diff format with ranges
      def test_normalizes_complex_diff_with_ranges
        section = {
          "title" => "Changes",
          "diff" => {
            "ranges" => ["origin/main...HEAD", "HEAD~5...HEAD"],
            "paths" => ["ace-review/**/*", "ace-bundle/docs/configuration.md"]
          }
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD", "HEAD~5...HEAD"], normalized[:ranges]
        assert_equal ["ace-review/**/*", "ace-bundle/docs/configuration.md"], normalized[:paths]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test complex diff format with symbol keys
      def test_normalizes_complex_diff_with_symbol_keys
        section = {
          title: "Changes",
          diff: {
            ranges: ["origin/main...HEAD"],
            paths: ["ace-review/**/*"]
          }
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD"], normalized[:ranges]
        assert_equal ["ace-review/**/*"], normalized[:paths]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      def test_merge_section_data_merges_paths
        existing = {
          title: "Changes",
          ranges: ["origin/main...HEAD"],
          paths: ["ace-review/**/*"]
        }
        incoming = {
          title: "Changes",
          ranges: ["HEAD~3...HEAD"],
          paths: ["ace-bundle/**/*", "ace-review/**/*"]
        }

        merged = @processor.send(:merge_section_data, existing, incoming)

        assert_equal ["origin/main...HEAD", "HEAD~3...HEAD"], merged[:ranges]
        assert_equal ["ace-review/**/*", "ace-bundle/**/*"], merged[:paths]
      end

      # Test complex diff format with 'since'
      def test_normalizes_complex_diff_with_since
        section = {
          "title" => "Changes",
          "diff" => {
            "since" => "origin/main"
          }
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD"], normalized[:ranges]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test complex diff format with since (symbol keys)
      def test_normalizes_complex_diff_with_since_symbol_keys
        section = {
          title: "Changes",
          diff: {
            since: "origin/main"
          }
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD"], normalized[:ranges]
      end

      # Test diff as string (single range)
      def test_normalizes_diff_as_string
        section = {
          "title" => "Changes",
          "diff" => "origin/main...HEAD"
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD"], normalized[:ranges]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test diff as array (multiple ranges)
      def test_normalizes_diff_as_array
        section = {
          "title" => "Changes",
          "diff" => ["origin/main...HEAD", "HEAD~5...HEAD"]
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD", "HEAD~5...HEAD"], normalized[:ranges]
      end

      # Test ranges format
      def test_preserves_ranges_format
        section = {
          "title" => "Changes",
          "ranges" => ["origin/main...HEAD"]
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        assert_equal ["origin/main...HEAD"], normalized[:ranges]
      end

      # Test that diff takes precedence over diffs
      def test_diff_takes_precedence_over_diffs
        section = {
          "title" => "Changes",
          "diff" => {
            "ranges" => ["origin/main...HEAD"]
          },
          "diffs" => ["old-format...HEAD"]
        }

        normalized = @processor.send(:normalize_section, "changes", section)

        # Should use diff, not diffs
        assert_equal ["origin/main...HEAD"], normalized[:ranges]
      end

      # Test that section without diff/diffs doesn't have ranges
      def test_section_without_diffs_has_no_ranges
        section = {
          "title" => "Files Only",
          "files" => ["src/**/*.rb"]
        }

        normalized = @processor.send(:normalize_section, "files", section)

        refute normalized.key?(:ranges)
        refute normalized.key?(:diffs)
        refute normalized.key?(:diff)
      end
    end
  end
end
