# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "ace/docs/molecules/document_loader"

module Ace
  module Docs
    class DocumentTest < AceTestCase
      def test_multi_subject_detection_returns_true_for_array
        # Create document with multi-subject configuration (array)
        content = <<~MARKDOWN
          ---
          doc-type: reference
          purpose: Test document with multi-subject
          ace-docs:
            subject:
              - code:
                  diff:
                    filters:
                      - "**/*.rb"
              - docs:
                  diff:
                    filters:
                      - "**/*.md"
          ---

          # Test Document
          Content here
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)

        assert doc.multi_subject?, "Document should detect multi-subject configuration"
      ensure
        file&.close
        file&.unlink
      end

      def test_multi_subject_detection_returns_false_for_hash
        # Create document with single-subject configuration (hash)
        content = <<~MARKDOWN
          ---
          doc-type: reference
          purpose: Test document with single subject
          ace-docs:
            subject:
              diff:
                filters:
                  - "**/*.rb"
                  - "**/*.md"
          ---

          # Test Document
          Content here
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)

        refute doc.multi_subject?, "Document should not detect multi-subject for hash configuration"
      ensure
        file&.close
        file&.unlink
      end

      def test_subject_configurations_returns_empty_for_single_subject_hash
        content = <<~MARKDOWN
          ---
          doc-type: reference
          purpose: Test single-subject hash configuration
          ace-docs:
            subject:
              diff:
                filters:
                  - "**/*.rb"
                  - "**/*.md"
          ---

          # Test Document
          Content here
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)

        assert_empty doc.subject_configurations
      ensure
        file&.close
        file&.unlink
      end

      def test_subject_configurations_multi_subject
        # Create document with multi-subject configuration
        content = <<~MARKDOWN
          ---
          doc-type: reference
          purpose: Test multi-subject configurations
          ace-docs:
            subject:
              - code:
                  diff:
                    filters:
                      - "lib/**/*.rb"
                      - "test/**/*.rb"
              - config:
                  diff:
                    filters:
                      - "**/*.yml"
                      - "**/*.yaml"
              - docs:
                  diff:
                    filters:
                      - "**/*.md"
          ---

          # Test Document
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)
        configs = doc.subject_configurations

        assert_equal 3, configs.length, "Should have 3 subject configurations"

        # Check first subject (code)
        assert_equal "code", configs[0][:name]
        assert_equal ["lib/**/*.rb", "test/**/*.rb"], configs[0][:filters]

        # Check second subject (config)
        assert_equal "config", configs[1][:name]
        assert_equal ["**/*.yml", "**/*.yaml"], configs[1][:filters]

        # Check third subject (docs)
        assert_equal "docs", configs[2][:name]
        assert_equal ["**/*.md"], configs[2][:filters]
      ensure
        file&.close
        file&.unlink
      end

      def test_subject_configurations_with_empty_filters
        # Create document with empty filter arrays
        content = <<~MARKDOWN
          ---
          doc-type: reference
          purpose: Test empty filters handling
          ace-docs:
            subject:
              - code:
                  diff:
                    filters:
                      - "**/*.rb"
              - config:
                  diff:
                    filters: []
              - docs:
                  diff:
                    filters:
                      - "**/*.md"
          ---

          # Test Document
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)
        configs = doc.subject_configurations

        # Should only include subjects with non-empty filters (design decision)
        assert_equal 2, configs.length, "Should have 2 subjects with filters"

        # Verify config subject with empty filters is excluded
        config_subject = configs.find { |c| c[:name] == "config" }
        assert_nil config_subject, "Config subject with empty filters should be excluded"

        # Verify the remaining subjects
        assert configs.any? { |c| c[:name] == "code" }
        assert configs.any? { |c| c[:name] == "docs" }
      ensure
        file&.close
        file&.unlink
      end

      def test_last_updated_with_date_only_format
        # Test that date-only timestamps return Date objects
        content = <<~MARKDOWN
          ---
          doc-type: guide
          purpose: Test date-only timestamp
          ace-docs:
            last-updated: 2025-11-01
          ---

          # Test Document
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)
        last_updated = doc.last_updated

        assert_instance_of Date, last_updated, "Date-only timestamp should return Date object"
        assert_equal 2025, last_updated.year
        assert_equal 11, last_updated.month
        assert_equal 1, last_updated.day
      ensure
        file&.close
        file&.unlink
      end

      def test_last_updated_with_datetime_format
        # Test that date+time timestamps return Time objects
        content = <<~MARKDOWN
          ---
          doc-type: guide
          purpose: Test date+time timestamp
          ace-docs:
            last-updated: 2025-11-01T14:30:00Z
          ---

          # Test Document
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)
        last_updated = doc.last_updated

        assert_instance_of Time, last_updated, "Date+time timestamp should return Time object"
        assert_equal 2025, last_updated.year
        assert_equal 11, last_updated.month
        assert_equal 1, last_updated.day
        assert_equal 14, last_updated.hour
        assert_equal 30, last_updated.min
      ensure
        file&.close
        file&.unlink
      end

      def test_last_checked_with_iso8601_format
        # Test that last-checked supports ISO 8601 UTC format
        content = <<~MARKDOWN
          ---
          doc-type: guide
          purpose: Test last-checked timestamp
          update:
            last-checked: 2025-11-01T09:15:00Z
          ---

          # Test Document
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)
        last_checked = doc.last_checked

        assert_instance_of Time, last_checked, "last-checked should support ISO 8601 UTC format"
        assert_equal 9, last_checked.hour
        assert_equal 15, last_checked.min
      ensure
        file&.close
        file&.unlink
      end

      def test_last_updated_returns_nil_for_missing_field
        # Test nil handling
        content = <<~MARKDOWN
          ---
          doc-type: guide
          purpose: Test missing timestamp
          ---

          # Test Document
        MARKDOWN

        file = Tempfile.new(["test", ".md"])
        file.write(content)
        file.rewind

        doc = Molecules::DocumentLoader.load_file(file.path)
        last_updated = doc.last_updated

        assert_nil last_updated, "Missing timestamp should return nil"
      ensure
        file&.close
        file&.unlink
      end
    end
  end
end
