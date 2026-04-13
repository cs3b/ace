# frozen_string_literal: true

require "test_helper"
require "ace/support/config"

class YamlParserTest < Minitest::Test
  def test_parse_valid_yaml
    yaml = <<~YAML
      key: value
      nested:
        inner: data
      array:
        - one
        - two
    YAML

    result = Ace::Support::Config::Atoms::YamlParser.parse(yaml)

    assert_equal "value", result["key"]
    assert_equal "data", result["nested"]["inner"]
    assert_equal ["one", "two"], result["array"]
  end

  def test_parse_empty_yaml
    assert_equal({}, Ace::Support::Config::Atoms::YamlParser.parse(""))
    assert_equal({}, Ace::Support::Config::Atoms::YamlParser.parse(nil))
    assert_equal({}, Ace::Support::Config::Atoms::YamlParser.parse("   "))
  end

  def test_parse_invalid_yaml
    invalid_yaml = "key: value\n bad:\n  indent"

    assert_raises(Ace::Support::Config::YamlParseError) do
      Ace::Support::Config::Atoms::YamlParser.parse(invalid_yaml)
    end
  end

  def test_dump_hash_to_yaml
    data = {
      "key" => "value",
      "nested" => {"inner" => "data"}
    }

    yaml = Ace::Support::Config::Atoms::YamlParser.dump(data)
    parsed = YAML.safe_load(yaml)

    assert_equal data, parsed
  end

  def test_dump_empty_hash
    assert_equal "", Ace::Support::Config::Atoms::YamlParser.dump({})
    assert_equal "", Ace::Support::Config::Atoms::YamlParser.dump(nil)
  end

  def test_valid_check
    assert Ace::Support::Config::Atoms::YamlParser.valid?("key: value")
    refute Ace::Support::Config::Atoms::YamlParser.valid?("key: value\n bad:\n  indent")
  end
end
