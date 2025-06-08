# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/json_formatter"

RSpec.describe CodingAgentTools::Atoms::JSONFormatter do
  describe ".pretty_print" do
    context "with hash input" do
      let(:hash) { {name: "John", age: 30, city: "New York"} }

      it "formats hash with default indentation" do
        result = described_class.pretty_print(hash)
        expect(result).to eq(<<~JSON.chomp)
          {
            "name": "John",
            "age": 30,
            "city": "New York"
          }
        JSON
      end

      it "formats hash with custom indentation" do
        result = described_class.pretty_print(hash, indent: "    ")
        expect(result).to include('"name": "John"')
        expect(result).to include('    "name"')
      end
    end

    context "with array input" do
      let(:array) { [1, 2, {key: "value"}] }

      it "formats array correctly" do
        result = described_class.pretty_print(array)
        expect(result).to eq(<<~JSON.chomp)
          [
            1,
            2,
            {
              "key": "value"
            }
          ]
        JSON
      end
    end

    context "with string input" do
      let(:json_string) { '{"compact":true,"formatted":false}' }

      it "parses and formats JSON string" do
        result = described_class.pretty_print(json_string)
        expect(result).to eq(<<~JSON.chomp)
          {
            "compact": true,
            "formatted": false
          }
        JSON
      end

      it "raises error for invalid JSON string" do
        expect {
          described_class.pretty_print("not json")
        }.to raise_error(JSON::ParserError)
      end
    end

    context "with nested structures" do
      let(:nested) do
        {
          user: {
            name: "Jane",
            preferences: {
              theme: "dark",
              notifications: {
                email: true,
                push: false
              }
            }
          },
          metadata: {
            version: 1,
            timestamp: "2024-01-01"
          }
        }
      end

      it "formats deeply nested structures" do
        result = described_class.pretty_print(nested)
        expect(result).to include('"theme": "dark"')
        expect(result).to include('"email": true')
        expect(result.scan("  ").count).to be > 10 # Multiple levels of indentation
      end
    end
  end

  describe ".pretty_format" do
    it "is an alias for pretty_print" do
      data = {test: "value"}
      expect(described_class.pretty_format(data)).to eq(described_class.pretty_print(data))
    end
  end

  describe ".compact" do
    context "with hash input" do
      let(:hash) { {name: "John", age: 30, nested: {key: "value"}} }

      it "generates compact JSON without extra whitespace" do
        result = described_class.compact(hash)
        expect(result).to eq('{"name":"John","age":30,"nested":{"key":"value"}}')
      end
    end

    context "with array input" do
      let(:array) { [1, 2, 3, {key: "value"}] }

      it "generates compact JSON array" do
        result = described_class.compact(array)
        expect(result).to eq('[1,2,3,{"key":"value"}]')
      end
    end

    context "with string input" do
      let(:pretty_json) do
        <<~JSON
          {
            "formatted": true,
            "spaces": "everywhere"
          }
        JSON
      end

      it "parses and compacts formatted JSON string" do
        result = described_class.compact(pretty_json)
        expect(result).to eq('{"formatted":true,"spaces":"everywhere"}')
      end

      it "raises error for invalid JSON string" do
        expect {
          described_class.compact("not json")
        }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe ".safe_parse" do
    context "with valid JSON" do
      it "parses valid JSON string" do
        result = described_class.safe_parse('{"key":"value"}')
        expect(result).to eq({"key" => "value"})
      end

      it "parses JSON array" do
        result = described_class.safe_parse("[1,2,3]")
        expect(result).to eq([1, 2, 3])
      end

      it "parses with symbolized names when requested" do
        result = described_class.safe_parse('{"key":"value"}', symbolize_names: true)
        expect(result).to eq({key: "value"})
      end
    end

    context "with invalid input" do
      it "returns nil for invalid JSON" do
        expect(described_class.safe_parse("not json")).to be_nil
      end

      it "returns nil for non-string input" do
        expect(described_class.safe_parse(123)).to be_nil
        expect(described_class.safe_parse(nil)).to be_nil
        expect(described_class.safe_parse([])).to be_nil
      end

      it "returns nil for empty string" do
        expect(described_class.safe_parse("")).to be_nil
      end
    end

    context "with edge cases" do
      it "parses JSON primitives" do
        expect(described_class.safe_parse('"string"')).to eq("string")
        expect(described_class.safe_parse("123")).to eq(123)
        expect(described_class.safe_parse("true")).to eq(true)
        expect(described_class.safe_parse("null")).to be_nil
      end
    end
  end

  describe ".valid_json?" do
    context "with valid JSON" do
      it "returns true for valid JSON object" do
        expect(described_class.valid_json?('{"valid":true}')).to be true
      end

      it "returns true for valid JSON array" do
        expect(described_class.valid_json?("[1,2,3]")).to be true
      end

      it "returns true for JSON primitives" do
        expect(described_class.valid_json?("123")).to be true
        expect(described_class.valid_json?('"string"')).to be true
        expect(described_class.valid_json?("true")).to be true
        expect(described_class.valid_json?("null")).to be true
      end
    end

    context "with invalid input" do
      it "returns false for invalid JSON" do
        expect(described_class.valid_json?("not json")).to be false
        expect(described_class.valid_json?("{incomplete")).to be false
        expect(described_class.valid_json?('{"key": undefined}')).to be false
      end

      it "returns false for non-string input" do
        expect(described_class.valid_json?(123)).to be false
        expect(described_class.valid_json?(nil)).to be false
        expect(described_class.valid_json?({})).to be false
      end

      it "returns false for empty string" do
        expect(described_class.valid_json?("")).to be false
      end
    end
  end

  describe ".extract_path" do
    let(:data) do
      {
        "user" => {
          "name" => {
            "first" => "John",
            "last" => "Doe"
          },
          "email" => "john@example.com",
          "tags" => ["admin", "user"]
        },
        "metadata" => {
          "version" => 1
        }
      }
    end

    context "with hash navigation" do
      it "extracts nested values using dot notation" do
        expect(described_class.extract_path(data, "user.name.first")).to eq("John")
        expect(described_class.extract_path(data, "user.email")).to eq("john@example.com")
        expect(described_class.extract_path(data, "metadata.version")).to eq(1)
      end

      it "returns nil for non-existent paths" do
        expect(described_class.extract_path(data, "user.phone")).to be_nil
        expect(described_class.extract_path(data, "user.name.middle")).to be_nil
        expect(described_class.extract_path(data, "nonexistent.path")).to be_nil
      end
    end

    context "with array navigation" do
      it "extracts array elements by index" do
        expect(described_class.extract_path(data, "user.tags.0")).to eq("admin")
        expect(described_class.extract_path(data, "user.tags.1")).to eq("user")
      end

      it "returns nil for out-of-bounds array access" do
        expect(described_class.extract_path(data, "user.tags.5")).to be_nil
      end
    end

    context "with symbol keys" do
      let(:symbol_data) do
        {
          user: {
            name: "Jane",
            roles: [:admin, :editor]
          }
        }
      end

      it "handles symbol keys" do
        expect(described_class.extract_path(symbol_data, "user.name")).to eq("Jane")
        expect(described_class.extract_path(symbol_data, "user.roles.0")).to eq(:admin)
      end
    end

    context "with edge cases" do
      it "returns nil for nil data" do
        expect(described_class.extract_path(nil, "any.path")).to be_nil
      end

      it "returns nil for nil path" do
        expect(described_class.extract_path(data, nil)).to be_nil
      end

      it "returns the data itself for empty path" do
        expect(described_class.extract_path(data, "")).to eq(data)
      end

      it "handles paths that traverse through non-objects" do
        expect(described_class.extract_path(data, "user.email.length")).to be_nil
      end
    end
  end

  describe ".sanitize" do
    context "with sensitive data in hash" do
      let(:sensitive_data) do
        {
          "api_key" => "secret123",
          "user" => {
            "name" => "John",
            "password" => "hidden",
            "email" => "john@example.com"
          },
          "token" => "bearer-xyz"
        }
      end

      it "redacts default sensitive keys" do
        result = described_class.sanitize(sensitive_data)
        expect(result["api_key"]).to eq("[REDACTED]")
        expect(result["user"]["password"]).to eq("[REDACTED]")
        expect(result["token"]).to eq("[REDACTED]")
        expect(result["user"]["email"]).to eq("john@example.com")
      end

      it "uses custom redact value" do
        result = described_class.sanitize(sensitive_data, redact_value: "***")
        expect(result["api_key"]).to eq("***")
        expect(result["token"]).to eq("***")
      end

      it "handles custom sensitive keys" do
        result = described_class.sanitize(
          sensitive_data,
          sensitive_keys: ["email", "name"]
        )
        expect(result["user"]["email"]).to eq("[REDACTED]")
        expect(result["user"]["name"]).to eq("[REDACTED]")
        expect(result["api_key"]).to eq("secret123") # Not in custom list
      end
    end

    context "with sensitive data in arrays" do
      let(:array_data) do
        [
          {"api_key" => "key1", "data" => "value1"},
          {"token" => "key2", "data" => "value2"},
          "plain string"
        ]
      end

      it "sanitizes arrays of hashes" do
        result = described_class.sanitize(array_data)
        expect(result[0]["api_key"]).to eq("[REDACTED]")
        expect(result[0]["data"]).to eq("value1")
        expect(result[1]["token"]).to eq("[REDACTED]")
        expect(result[2]).to eq("plain string")
      end
    end

    context "with nested structures" do
      let(:nested_data) do
        {
          "config" => {
            "database" => {
              "password" => "db-secret",
              "host" => "localhost"
            },
            "api" => {
              "secret" => "api-secret",
              "endpoint" => "https://api.example.com"
            }
          }
        }
      end

      it "sanitizes deeply nested sensitive data" do
        result = described_class.sanitize(nested_data)
        expect(result["config"]["database"]["password"]).to eq("[REDACTED]")
        expect(result["config"]["database"]["host"]).to eq("localhost")
        expect(result["config"]["api"]["secret"]).to eq("[REDACTED]")
        expect(result["config"]["api"]["endpoint"]).to eq("https://api.example.com")
      end
    end

    context "with string input" do
      let(:json_string) { '{"api_key":"secret","public":"data"}' }

      it "parses and sanitizes JSON string" do
        result = described_class.sanitize(json_string)
        expect(result["api_key"]).to eq("[REDACTED]")
        expect(result["public"]).to eq("data")
      end
    end

    context "with symbol keys" do
      let(:symbol_data) do
        {
          api_key: "secret",
          token: "xyz",
          public_data: "visible"
        }
      end

      it "handles symbol keys correctly" do
        result = described_class.sanitize(symbol_data)
        expect(result[:api_key]).to eq("[REDACTED]")
        expect(result[:token]).to eq("[REDACTED]")
        expect(result[:public_data]).to eq("visible")
      end
    end

    context "with non-hash/array data" do
      it "returns primitives as-is" do
        expect(described_class.sanitize("string")).to eq("string")
        expect(described_class.sanitize(123)).to eq(123)
        expect(described_class.sanitize(true)).to eq(true)
        expect(described_class.sanitize(nil)).to be_nil
      end
    end
  end
end
