# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/ace/bundle'
require_relative '../../lib/ace/bundle/molecules/section_processor'

module Ace
  module Bundle
    class SectionDiffNormalizationTest < Minitest::Test
      def setup
        @processor = Molecules::SectionProcessor.new
      end

      # Test simple diffs format (legacy)
      def test_normalizes_simple_diffs_array
        section = {
          'title' => 'Changes',
          'diffs' => ['origin/main...HEAD', 'HEAD~5...HEAD']
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD', 'HEAD~5...HEAD'], normalized[:ranges]
        refute normalized.key?(:diffs), "diffs key should be removed after normalization"
      end

      # Test complex diff format with ranges
      def test_normalizes_complex_diff_with_ranges
        section = {
          'title' => 'Changes',
          'diff' => {
            'ranges' => ['origin/main...HEAD', 'HEAD~5...HEAD']
          }
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD', 'HEAD~5...HEAD'], normalized[:ranges]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test complex diff format with symbol keys
      def test_normalizes_complex_diff_with_symbol_keys
        section = {
          title: 'Changes',
          diff: {
            ranges: ['origin/main...HEAD']
          }
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD'], normalized[:ranges]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test complex diff format with 'since'
      def test_normalizes_complex_diff_with_since
        section = {
          'title' => 'Changes',
          'diff' => {
            'since' => 'origin/main'
          }
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD'], normalized[:ranges]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test complex diff format with since (symbol keys)
      def test_normalizes_complex_diff_with_since_symbol_keys
        section = {
          title: 'Changes',
          diff: {
            since: 'origin/main'
          }
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD'], normalized[:ranges]
      end

      # Test diff as string (single range)
      def test_normalizes_diff_as_string
        section = {
          'title' => 'Changes',
          'diff' => 'origin/main...HEAD'
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD'], normalized[:ranges]
        refute normalized.key?(:diff), "diff key should be removed after normalization"
      end

      # Test diff as array (multiple ranges)
      def test_normalizes_diff_as_array
        section = {
          'title' => 'Changes',
          'diff' => ['origin/main...HEAD', 'HEAD~5...HEAD']
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD', 'HEAD~5...HEAD'], normalized[:ranges]
      end

      # Test legacy ranges format (backward compatibility)
      def test_preserves_ranges_format
        section = {
          'title' => 'Changes',
          'ranges' => ['origin/main...HEAD']
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        assert_equal ['origin/main...HEAD'], normalized[:ranges]
      end

      # Test that diff takes precedence over diffs
      def test_diff_takes_precedence_over_diffs
        section = {
          'title' => 'Changes',
          'diff' => {
            'ranges' => ['origin/main...HEAD']
          },
          'diffs' => ['old-format...HEAD']
        }

        normalized = @processor.send(:normalize_section, 'changes', section)

        # Should use diff, not diffs
        assert_equal ['origin/main...HEAD'], normalized[:ranges]
      end

      # Test legacy content collection with diff format
      def test_collect_legacy_content_with_diff_hash
        context = {
          'diff' => {
            'ranges' => ['origin/main...HEAD']
          }
        }

        legacy = @processor.send(:collect_legacy_content, context)

        assert_equal ['origin/main...HEAD'], legacy[:ranges]
      end

      # Test legacy content collection with diff string
      def test_collect_legacy_content_with_diff_string
        context = {
          'diff' => 'origin/main...HEAD'
        }

        legacy = @processor.send(:collect_legacy_content, context)

        assert_equal ['origin/main...HEAD'], legacy[:ranges]
      end

      # Test legacy content collection with since
      def test_collect_legacy_content_with_since
        context = {
          'diff' => {
            'since' => 'origin/main'
          }
        }

        legacy = @processor.send(:collect_legacy_content, context)

        assert_equal ['origin/main...HEAD'], legacy[:ranges]
      end

      # Test legacy content collection with diffs (backward compat)
      def test_collect_legacy_content_with_diffs
        context = {
          'diffs' => ['origin/main...HEAD']
        }

        legacy = @processor.send(:collect_legacy_content, context)

        assert_equal ['origin/main...HEAD'], legacy[:ranges]
      end

      # Test create legacy sections with diff format
      def test_create_legacy_sections_with_diff_hash
        config = {
          'context' => {
            'diff' => {
              'ranges' => ['origin/main...HEAD']
            }
          }
        }

        sections = @processor.send(:create_legacy_sections, config)

        assert sections.key?('diffs')
        assert_equal ['origin/main...HEAD'], sections['diffs'][:ranges]
      end

      # Test create legacy sections with since
      def test_create_legacy_sections_with_since
        config = {
          'context' => {
            'diff' => {
              'since' => 'origin/main'
            }
          }
        }

        sections = @processor.send(:create_legacy_sections, config)

        assert sections.key?('diffs')
        assert_equal ['origin/main...HEAD'], sections['diffs'][:ranges]
      end

      # Test that section without diff/diffs doesn't have ranges
      def test_section_without_diffs_has_no_ranges
        section = {
          'title' => 'Files Only',
          'files' => ['src/**/*.rb']
        }

        normalized = @processor.send(:normalize_section, 'files', section)

        refute normalized.key?(:ranges)
        refute normalized.key?(:diffs)
        refute normalized.key?(:diff)
      end
    end
  end
end
