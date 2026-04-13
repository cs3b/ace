# frozen_string_literal: true

require_relative "../../test_helper"

class TapeMetadataParserTest < AceDemoTestCase
  def test_parses_metadata_comments
    content = <<~TAPE
      # Description: Built-in echo demo
      # Tags: example, getting-started
      # Author: ace

      Output .ace-local/demo/hello.gif
    TAPE

    parsed = Ace::Demo::Atoms::TapeMetadataParser.parse(content)

    assert_equal "Built-in echo demo", parsed["description"]
    assert_equal "example, getting-started", parsed["tags"]
    assert_equal "ace", parsed["author"]
  end

  def test_ignores_non_metadata_lines
    content = <<~TAPE
      # Just a comment
      # Description: Demo
      Output .ace-local/demo/hello.gif
      # Tags: should-not-be-parsed
    TAPE

    parsed = Ace::Demo::Atoms::TapeMetadataParser.parse(content)

    assert_equal "Demo", parsed["description"]
    refute parsed.key?("tags")
  end

  def test_normalizes_keys
    content = <<~TAPE
      # Display Name: Fancy Demo
      # Recording Mode: slow
    TAPE

    parsed = Ace::Demo::Atoms::TapeMetadataParser.parse(content)

    assert_equal "Fancy Demo", parsed["display_name"]
    assert_equal "slow", parsed["recording_mode"]
  end
end
