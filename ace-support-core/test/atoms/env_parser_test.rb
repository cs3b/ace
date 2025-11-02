# frozen_string_literal: true

require 'test_helper'
require 'ace/core/atoms/env_parser'

class EnvParserTest < AceTestCase
  def test_parses_basic_env_content
    content = <<~ENV
      SIMPLE_VAR=value
      ANOTHER_VAR=another value
      NUMBER_VAR=42
      EMPTY_VAR=
    ENV

    result = Ace::Core::Atoms::EnvParser.parse(content)

    assert_equal 'value', result['SIMPLE_VAR']
    assert_equal 'another value', result['ANOTHER_VAR']
    assert_equal '42', result['NUMBER_VAR']
    assert_equal '', result['EMPTY_VAR']
  end

  def test_handles_quoted_values
    content = <<~ENV
      DOUBLE_QUOTED="quoted value"
      SINGLE_QUOTED='single quoted'
      MIXED_QUOTES="can't stop"
      ESCAPED_QUOTES="\\"escaped\\""
    ENV

    result = Ace::Core::Atoms::EnvParser.parse(content)

    assert_equal 'quoted value', result['DOUBLE_QUOTED']
    assert_equal 'single quoted', result['SINGLE_QUOTED']
    assert_equal "can't stop", result['MIXED_QUOTES']
    assert_equal '"escaped"', result['ESCAPED_QUOTES']
  end

  def test_handles_special_characters
    content = <<~ENV
      WITH_NEWLINE="line1\\nline2"
      WITH_BACKSLASH="path\\\\to\\\\file"
      WITH_EQUALS=key=value
      WITH_SPACES=   trimmed
    ENV

    result = Ace::Core::Atoms::EnvParser.parse(content)

    assert_equal "line1\nline2", result['WITH_NEWLINE']
    assert_equal 'path\\to\\file', result['WITH_BACKSLASH']
    assert_equal 'key=value', result['WITH_EQUALS']
    assert_equal 'trimmed', result['WITH_SPACES']
  end

  def test_skips_comments_and_empty_lines
    content = <<~ENV
      # This is a comment
      VAR1=value1

      # Another comment
      VAR2=value2

      # VAR3=commented_out
    ENV

    result = Ace::Core::Atoms::EnvParser.parse(content)

    assert_equal 2, result.size
    assert_equal 'value1', result['VAR1']
    assert_equal 'value2', result['VAR2']
    refute result.key?('VAR3')
  end

  def test_handles_empty_and_nil_content
    assert_equal({}, Ace::Core::Atoms::EnvParser.parse(nil))
    assert_equal({}, Ace::Core::Atoms::EnvParser.parse(''))
    assert_equal({}, Ace::Core::Atoms::EnvParser.parse("   \n  \n  "))
  end

  def test_ignores_invalid_lines
    content = <<~ENV
      VALID_VAR=value
      =no_key
      NO_EQUALS_SIGN
      123_INVALID_START=value
      ANOTHER_VALID=yes
    ENV

    result = Ace::Core::Atoms::EnvParser.parse(content)

    assert_equal 2, result.size
    assert_equal 'value', result['VALID_VAR']
    assert_equal 'yes', result['ANOTHER_VALID']
    refute result.key?('')
    refute result.key?('NO_EQUALS_SIGN')
    refute result.key?('123_INVALID_START')
  end

  def test_formats_hash_to_env_content
    env_hash = {
      'SIMPLE' => 'value',
      'WITH_SPACES' => 'has spaces',
      'NUMBER' => 42,
      'EMPTY' => ''
    }

    content = Ace::Core::Atoms::EnvParser.format(env_hash)
    lines = content.split("\n")

    assert lines.include?('SIMPLE=value')
    assert lines.include?('WITH_SPACES="has spaces"')
    assert lines.include?('NUMBER=42')
    assert lines.include?('EMPTY=')
  end

  def test_formats_empty_hash
    assert_equal '', Ace::Core::Atoms::EnvParser.format({})
    assert_equal '', Ace::Core::Atoms::EnvParser.format(nil)
  end

  def test_valid_key_validation
    # Valid keys
    assert Ace::Core::Atoms::EnvParser.valid_key?('VALID_KEY')
    assert Ace::Core::Atoms::EnvParser.valid_key?('_STARTS_WITH_UNDERSCORE')
    assert Ace::Core::Atoms::EnvParser.valid_key?('has_lowercase')
    assert Ace::Core::Atoms::EnvParser.valid_key?('MIX3D_w1th_NUMB3RS')

    # Invalid keys
    refute Ace::Core::Atoms::EnvParser.valid_key?('123_STARTS_WITH_NUMBER')
    refute Ace::Core::Atoms::EnvParser.valid_key?('HAS-DASHES')
    refute Ace::Core::Atoms::EnvParser.valid_key?('HAS SPACES')
    refute Ace::Core::Atoms::EnvParser.valid_key?('')
    refute Ace::Core::Atoms::EnvParser.valid_key?(nil)
  end

  def test_unquote_handles_various_formats
    parser = Ace::Core::Atoms::EnvParser

    # Double quotes
    assert_equal 'value', parser.unquote('"value"')
    assert_equal 'with spaces', parser.unquote('"with spaces"')
    assert_equal '"escaped"', parser.unquote('"\\"escaped\\""')
    assert_equal "line1\nline2", parser.unquote('"line1\\nline2"')

    # Single quotes
    assert_equal 'value', parser.unquote("'value'")
    assert_equal 'no escaping\\n', parser.unquote("'no escaping\\n'")

    # No quotes
    assert_equal 'plain', parser.unquote('plain')
    assert_equal 'partial"quote', parser.unquote('partial"quote')

    # Edge cases
    assert_equal '', parser.unquote('""')
    assert_equal '', parser.unquote("''")
    assert_nil parser.unquote(nil)
  end

  def test_roundtrip_parse_and_format
    original = {
      'SIMPLE' => 'value',
      'QUOTED' => 'has spaces here',
      'EMPTY' => '',
      'NUMBER' => '123'
    }

    formatted = Ace::Core::Atoms::EnvParser.format(original)
    parsed = Ace::Core::Atoms::EnvParser.parse(formatted)

    assert_equal original['SIMPLE'], parsed['SIMPLE']
    assert_equal original['QUOTED'], parsed['QUOTED']
    assert_equal original['EMPTY'], parsed['EMPTY']
    assert_equal original['NUMBER'], parsed['NUMBER']
  end
end
