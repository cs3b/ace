# frozen_string_literal: true

require "test_helper"
require "ace/bundle/atoms/boundary_finder"

class BoundaryFinderTest < AceTestCase
  # parse_blocks tests

  def test_parse_blocks_empty_content
    assert_equal [], Ace::Bundle::Atoms::BoundaryFinder.parse_blocks("")
    assert_equal [], Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(nil)
  end

  def test_parse_blocks_plain_text_only
    content = "# Header\n\nSome plain text content."
    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 1, blocks.size
    assert_equal :text, blocks[0][:type]
    assert_equal content, blocks[0][:content]
  end

  def test_parse_blocks_single_file_element
    content = '<file path="test.rb" language="ruby">puts "hello"</file>'
    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 1, blocks.size
    assert_equal :file, blocks[0][:type]
    assert_equal content, blocks[0][:content]
  end

  def test_parse_blocks_single_output_element
    content = '<output command="git status">On branch main</output>'
    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 1, blocks.size
    assert_equal :output, blocks[0][:type]
    assert_equal content, blocks[0][:content]
  end

  def test_parse_blocks_multiple_file_elements
    content = <<~XML
      <file path="a.rb" language="ruby">code a</file>
      <file path="b.rb" language="ruby">code b</file>
    XML

    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 2, blocks.size
    assert_equal :file, blocks[0][:type]
    assert_includes blocks[0][:content], "a.rb"
    assert_equal :file, blocks[1][:type]
    assert_includes blocks[1][:content], "b.rb"
  end

  def test_parse_blocks_mixed_file_and_output
    content = <<~XML
      <file path="test.rb" language="ruby">code</file>
      <output command="ruby test.rb">output</output>
    XML

    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 2, blocks.size
    assert_equal :file, blocks[0][:type]
    assert_equal :output, blocks[1][:type]
  end

  def test_parse_blocks_text_before_and_after_elements
    content = <<~XML
      # Files
      <file path="test.rb" language="ruby">code</file>
      # Commands
    XML

    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 3, blocks.size
    assert_equal :text, blocks[0][:type]
    assert_includes blocks[0][:content], "# Files"
    assert_equal :file, blocks[1][:type]
    assert_equal :text, blocks[2][:type]
    assert_includes blocks[2][:content], "# Commands"
  end

  def test_parse_blocks_multiline_file_element
    content = <<~XML
      <file path="test.rb" language="ruby">
        def hello
          puts "world"
        end
      </file>
    XML

    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 1, blocks.size
    assert_equal :file, blocks[0][:type]
    assert_includes blocks[0][:content], "def hello"
    assert_includes blocks[0][:content], "puts"
  end

  def test_parse_blocks_multiline_output_element
    content = <<~XML
      <output command="git log">
        commit abc123
        Author: Test
        Date: Today

        Message here
      </output>
    XML

    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 1, blocks.size
    assert_equal :output, blocks[0][:type]
    assert_includes blocks[0][:content], "commit abc123"
  end

  def test_parse_blocks_counts_lines_correctly
    content = "line1\nline2\nline3"
    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    assert_equal 3, blocks[0][:lines]
  end

  def test_parse_blocks_realistic_context_output
    content = <<~XML
      # Project Context

      You are working on a project.

      # Files
      <files>
        <file path="lib/app.rb" language="ruby">
          class App
            def run
              puts "Running"
            end
          end
        </file>
        <file path="test/app_test.rb" language="ruby">
          require 'test_helper'

          class AppTest < Minitest::Test
            def test_run
              assert true
            end
          end
        </file>
      </files>

      # Commands
      <commands>
        <output command="git status">
          On branch main
          nothing to commit
        </output>
      </commands>
    XML

    blocks = Ace::Bundle::Atoms::BoundaryFinder.parse_blocks(content)

    # Should have: header text, file 1, file 2, middle text with </files> and <commands>, output, trailing text
    file_blocks = blocks.select { |b| b[:type] == :file }
    output_blocks = blocks.select { |b| b[:type] == :output }

    assert_equal 2, file_blocks.size
    assert_equal 1, output_blocks.size
  end

  # has_semantic_elements? tests

  def test_has_semantic_elements_with_file
    content = '<file path="test.rb" language="ruby">code</file>'
    assert Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?(content)
  end

  def test_has_semantic_elements_with_output
    content = '<output command="ls">files</output>'
    assert Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?(content)
  end

  def test_has_semantic_elements_plain_text
    content = "# Header\n\nJust plain markdown text."
    refute Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?(content)
  end

  def test_has_semantic_elements_empty
    refute Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?("")
    refute Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?(nil)
  end

  def test_has_semantic_elements_partial_tags
    # Incomplete tags should not match
    refute Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?("<file>no closing")
    refute Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?("<file incomplete")
    refute Ace::Bundle::Atoms::BoundaryFinder.has_semantic_elements?("</file> orphan closing")
  end
end
