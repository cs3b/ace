# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Atoms
        class YamlParserTest < TestCase
          def test_parse_simple_yaml
            yaml = <<~YAML
              key: value
              number: 42
            YAML

            result = YamlParser.parse(yaml)

            assert_equal({"key" => "value", "number" => 42}, result)
          end

          def test_parse_nested_yaml
            yaml = <<~YAML
              parent:
                child: value
                nested:
                  deep: true
            YAML

            result = YamlParser.parse(yaml)

            expected = {
              "parent" => {
                "child" => "value",
                "nested" => {"deep" => true}
              }
            }
            assert_equal(expected, result)
          end

          def test_parse_empty_string_returns_empty_hash
            assert_equal({}, YamlParser.parse(""))
            assert_equal({}, YamlParser.parse("   "))
            assert_equal({}, YamlParser.parse(nil))
          end

          def test_parse_invalid_yaml_raises_error
            invalid_yaml = "key: value\n  invalid: indentation"

            assert_raises(YamlParseError) do
              YamlParser.parse(invalid_yaml)
            end
          end

          def test_dump_hash
            data = {"key" => "value", "number" => 42}

            result = YamlParser.dump(data)

            assert_includes result, "key: value"
            assert_includes result, "number: 42"
          end

          def test_dump_empty_hash_returns_empty_string
            assert_equal "", YamlParser.dump({})
            assert_equal "", YamlParser.dump(nil)
          end

          def test_valid_yaml
            assert YamlParser.valid?("key: value")
            refute YamlParser.valid?("key: value\n  bad: indent")
          end
        end
      end
    end
  end
end
