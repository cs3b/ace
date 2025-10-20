# frozen_string_literal: true

require "test_helper"
require "tempfile"

class DocumentTest < AceTestCase
  def setup
    @registry = Ace::Docs::DocumentRegistry.new
  end

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

    file = Tempfile.new(['test', '.md'])
    file.write(content)
    file.rewind

    doc = @registry.load_document(file.path)

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

    file = Tempfile.new(['test', '.md'])
    file.write(content)
    file.rewind

    doc = @registry.load_document(file.path)

    refute doc.multi_subject?, "Document should not detect multi-subject for hash configuration"
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

    file = Tempfile.new(['test', '.md'])
    file.write(content)
    file.rewind

    doc = @registry.load_document(file.path)
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

  def test_subject_configurations_single_subject_backward_compat
    # Create document with single-subject configuration
    content = <<~MARKDOWN
      ---
      doc-type: reference
      purpose: Test single subject backward compatibility
      ace-docs:
        subject:
          diff:
            filters:
              - "**/*.rb"
              - "**/*.md"
      ---

      # Test Document
    MARKDOWN

    file = Tempfile.new(['test', '.md'])
    file.write(content)
    file.rewind

    doc = @registry.load_document(file.path)
    configs = doc.subject_configurations

    assert_equal 1, configs.length, "Should have 1 subject configuration"
    assert_equal "default", configs[0][:name], "Single subject should have 'default' name"
    assert_equal ["**/*.rb", "**/*.md"], configs[0][:filters]
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

    file = Tempfile.new(['test', '.md'])
    file.write(content)
    file.rewind

    doc = @registry.load_document(file.path)
    configs = doc.subject_configurations

    # Should include all subjects, even with empty filters
    assert_equal 3, configs.length, "Should have all 3 subjects"

    # Check that config subject has empty filters
    config_subject = configs.find { |c| c[:name] == "config" }
    assert_equal [], config_subject[:filters], "Config subject should have empty filters array"
  ensure
    file&.close
    file&.unlink
  end
end