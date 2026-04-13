# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class CastFileParserTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_cast_parser")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_parses_valid_cast_header_and_events
    cast_path = File.join(@tmp, "demo.cast")
    File.write(cast_path, <<~CAST)
      {"version":2,"width":80,"height":24}
      [0.10,"i","echo hi\\r"]
      [0.20,"o","hi\\n"]
    CAST

    result = Ace::Demo::Atoms::CastFileParser.parse(cast_path)

    assert_equal 2, result.header["version"]
    assert_equal 2, result.events.length
    assert_equal "i", result.events[0].type
    assert_equal "echo hi\r", result.events[0].data
  end

  def test_raises_on_malformed_json
    cast_path = File.join(@tmp, "broken.cast")
    File.write(cast_path, <<~CAST)
      {"version":2,"width":80,"height":24}
      [0.10,"i","echo hi"
    CAST

    error = assert_raises(Ace::Demo::CastParseError) do
      Ace::Demo::Atoms::CastFileParser.parse(cast_path)
    end

    assert_includes error.message, "Invalid JSON"
  end

  def test_raises_when_header_is_missing
    cast_path = File.join(@tmp, "missing-header.cast")
    File.write(cast_path, "")

    error = assert_raises(Ace::Demo::CastParseError) do
      Ace::Demo::Atoms::CastFileParser.parse(cast_path)
    end

    assert_includes error.message, "Missing cast header"
  end
end
