# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/env_reader"
require "tempfile"

RSpec.describe CodingAgentTools::Atoms::EnvReader do
  describe ".load_env_file" do
    let(:temp_env_file) { Tempfile.new([".env", ""]) }

    before do
      temp_env_file.write(<<~ENV)
        TEST_VAR=test_value
        ANOTHER_VAR=another_value
        EMPTY_VAR=
        QUOTED_VAR="quoted value"
        NUMERIC_VAR=12345
      ENV
      temp_env_file.close
    end

    after do
      temp_env_file.unlink
    end

    context "with existing file" do
      it "loads environment variables from file" do
        result = described_class.load_env_file(temp_env_file.path)
        expect(result).to be_a(Hash)
        expect(ENV["TEST_VAR"]).to eq("test_value")
        expect(ENV["ANOTHER_VAR"]).to eq("another_value")
      end

      it "handles empty values" do
        described_class.load_env_file(temp_env_file.path)
        expect(ENV["EMPTY_VAR"]).to eq("")
      end

      it "handles quoted values" do
        described_class.load_env_file(temp_env_file.path)
        expect(ENV["QUOTED_VAR"]).to eq("quoted value")
      end

      it "does not overwrite existing variables by default" do
        ENV["TEST_VAR"] = "original_value"
        described_class.load_env_file(temp_env_file.path)
        expect(ENV["TEST_VAR"]).to eq("original_value")
      end

      it "overwrites existing variables when overload is true" do
        ENV["TEST_VAR"] = "original_value"
        described_class.load_env_file(temp_env_file.path, overload: true)
        expect(ENV["TEST_VAR"]).to eq("test_value")
      end
    end

    context "with non-existent file" do
      it "returns empty hash" do
        result = described_class.load_env_file("non_existent.env")
        expect(result).to eq({})
      end

      it "does not raise error" do
        expect do
          described_class.load_env_file("non_existent.env")
        end.not_to raise_error
      end
    end

    context "with malformed .env file" do
      let(:malformed_env_file) { Tempfile.new([".env", ""]) }

      before do
        malformed_env_file.write(<<~ENV)
          VALID_VAR=valid
          INVALID LINE WITHOUT EQUALS
          =VALUE_WITHOUT_KEY
          KEY_WITH_SPACES = value with spaces
          # COMMENT_LINE=should_be_ignored
          EXPORT_VAR=export_value
        ENV
        malformed_env_file.close
      end

      after do
        malformed_env_file.unlink
      end

      it "loads valid variables and handles invalid lines gracefully" do
        described_class.load_env_file(malformed_env_file.path)
        expect(ENV["VALID_VAR"]).to eq("valid")
        expect(ENV["KEY_WITH_SPACES"]).to eq("value with spaces") # Dotenv should load this
        expect(ENV["COMMENT_LINE"]).to be_nil
      end
    end
  end

  describe ".get" do
    before do
      ENV["PRESENT_VAR"] = "present_value"
      ENV["EMPTY_VAR"] = ""
    end

    it "returns value for present variable" do
      expect(described_class.get("PRESENT_VAR")).to eq("present_value")
    end

    it "returns nil for missing variable without default" do
      expect(described_class.get("MISSING_VAR")).to be_nil
    end

    it "returns default value for missing variable" do
      expect(described_class.get("MISSING_VAR", "default")).to eq("default")
    end

    it "returns empty string for empty variable" do
      expect(described_class.get("EMPTY_VAR")).to eq("")
    end

    it "does not return default for empty variable" do
      expect(described_class.get("EMPTY_VAR", "default")).to eq("")
    end
  end

  describe ".get!" do
    before do
      ENV["PRESENT_VAR"] = "present_value"
      ENV["EMPTY_VAR"] = ""
    end

    it "returns value for present variable" do
      expect(described_class.get!("PRESENT_VAR")).to eq("present_value")
    end

    it "returns empty string for empty variable" do
      expect(described_class.get!("EMPTY_VAR")).to eq("")
    end

    it "raises KeyError for missing variable" do
      expect do
        described_class.get!("MISSING_VAR")
      end.to raise_error(KeyError, "Environment variable 'MISSING_VAR' is not set")
    end
  end

  describe ".set?" do
    before do
      ENV["PRESENT_VAR"] = "value"
      ENV["EMPTY_VAR"] = ""
      ENV.delete("MISSING_VAR")
    end

    it "returns true for present variable" do
      expect(described_class.set?("PRESENT_VAR")).to be true
    end

    it "returns true for empty variable" do
      expect(described_class.set?("EMPTY_VAR")).to be true
    end

    it "returns false for missing variable" do
      expect(described_class.set?("MISSING_VAR")).to be false
    end
  end

  describe ".present?" do
    before do
      ENV["PRESENT_VAR"] = "value"
      ENV["EMPTY_VAR"] = ""
      ENV["WHITESPACE_VAR"] = "   "
      ENV.delete("MISSING_VAR")
    end

    it "returns true for variable with value" do
      expect(described_class.present?("PRESENT_VAR")).to be true
    end

    it "returns false for empty variable" do
      expect(described_class.present?("EMPTY_VAR")).to be false
    end

    it "returns false for whitespace-only variable" do
      expect(described_class.present?("WHITESPACE_VAR")).to be false
    end

    it "returns false for missing variable" do
      expect(described_class.present?("MISSING_VAR")).to be false
    end
  end

  describe ".get_multiple" do
    before do
      ENV["VAR1"] = "value1"
      ENV["VAR2"] = "value2"
      ENV["VAR3"] = ""
      ENV.delete("VAR4")
    end

    context "without prefix" do
      it "returns hash of present variables" do
        result = described_class.get_multiple(["VAR1", "VAR2", "VAR3", "VAR4"])
        expect(result).to eq({
          "VAR1" => "value1",
          "VAR2" => "value2",
          "VAR3" => ""
        })
      end

      it "returns empty hash for all missing variables" do
        result = described_class.get_multiple(["MISSING1", "MISSING2"])
        expect(result).to eq({})
      end
    end

    context "with prefix" do
      before do
        ENV["APP_HOST"] = "localhost"
        ENV["APP_PORT"] = "3000"
        ENV["APP_DEBUG"] = "true"
      end

      it "prepends prefix to keys when looking up" do
        result = described_class.get_multiple(["HOST", "PORT", "DEBUG"], prefix: "APP_")
        expect(result).to eq({
          "HOST" => "localhost",
          "PORT" => "3000",
          "DEBUG" => "true"
        })
      end

      it "excludes missing prefixed variables" do
        result = described_class.get_multiple(["HOST", "PORT", "MISSING"], prefix: "APP_")
        expect(result).to eq({
          "HOST" => "localhost",
          "PORT" => "3000"
        })
      end
    end
  end

  describe ".get_matching" do
    before do
      ENV["APP_HOST"] = "localhost"
      ENV["APP_PORT"] = "3000"
      ENV["APP_DEBUG"] = "true"
      ENV["DATABASE_HOST"] = "db.example.com"
      ENV["DATABASE_PORT"] = "5432"
      ENV["OTHER_VAR"] = "other"
    end

    context "with string pattern (prefix)" do
      it "returns all variables with matching prefix" do
        result = described_class.get_matching("APP_")
        expect(result).to eq({
          "APP_HOST" => "localhost",
          "APP_PORT" => "3000",
          "APP_DEBUG" => "true"
        })
      end

      it "returns empty hash for non-matching prefix" do
        result = described_class.get_matching("NONEXISTENT_")
        expect(result).to eq({})
      end
    end

    context "with regexp pattern" do
      it "returns variables matching regex" do
        result = described_class.get_matching(/^(APP|DATABASE)_HOST$/)
        expect(result).to eq({
          "APP_HOST" => "localhost",
          "DATABASE_HOST" => "db.example.com"
        })
      end

      it "supports complex patterns" do
        result = described_class.get_matching(/_PORT$/)
        expect(result).to eq({
          "APP_PORT" => "3000",
          "DATABASE_PORT" => "5432"
        })
      end
    end
  end

  describe ".with_env" do
    before do
      ENV["EXISTING_VAR"] = "original_value"
      ENV["TO_BE_DELETED"] = "will_be_removed"
    end

    it "temporarily sets environment variables" do
      result = described_class.with_env({"TEMP_VAR" => "temp_value"}) do
        ENV["TEMP_VAR"]
      end
      expect(result).to eq("temp_value")
      expect(ENV["TEMP_VAR"]).to be_nil
    end

    it "temporarily overrides existing variables" do
      described_class.with_env({"EXISTING_VAR" => "temporary_value"}) do
        expect(ENV["EXISTING_VAR"]).to eq("temporary_value")
      end
      expect(ENV["EXISTING_VAR"]).to eq("original_value")
    end

    it "handles nil values by deleting variables" do
      described_class.with_env({"TO_BE_DELETED" => nil}) do
        expect(ENV["TO_BE_DELETED"]).to be_nil
      end
      expect(ENV["TO_BE_DELETED"]).to eq("will_be_removed")
    end

    it "restores original state even if block raises" do
      expect do
        described_class.with_env({"EXISTING_VAR" => "temp_value"}) do
          expect(ENV["EXISTING_VAR"]).to eq("temp_value")
          raise "Test error"
        end
      end.to raise_error("Test error")
      expect(ENV["EXISTING_VAR"]).to eq("original_value")
    end

    it "handles multiple variables" do
      vars = {
        "VAR1" => "value1",
        "VAR2" => "value2",
        "VAR3" => "value3"
      }

      described_class.with_env(vars) do
        expect(ENV["VAR1"]).to eq("value1")
        expect(ENV["VAR2"]).to eq("value2")
        expect(ENV["VAR3"]).to eq("value3")
      end

      expect(ENV["VAR1"]).to be_nil
      expect(ENV["VAR2"]).to be_nil
      expect(ENV["VAR3"]).to be_nil
    end

    it "converts non-string values to strings" do
      described_class.with_env({"NUMERIC" => 123, "BOOLEAN" => true}) do
        expect(ENV["NUMERIC"]).to eq("123")
        expect(ENV["BOOLEAN"]).to eq("true")
      end
    end

    it "returns the block's return value" do
      result = described_class.with_env({"TEMP" => "value"}) do
        "block result"
      end
      expect(result).to eq("block result")
    end

    context "with nested calls" do
      it "properly handles nested with_env calls" do
        ENV["NESTED_VAR"] = "original"

        described_class.with_env({"NESTED_VAR" => "outer"}) do
          expect(ENV["NESTED_VAR"]).to eq("outer")

          described_class.with_env({"NESTED_VAR" => "inner"}) do
            expect(ENV["NESTED_VAR"]).to eq("inner")
          end

          expect(ENV["NESTED_VAR"]).to eq("outer")
        end

        expect(ENV["NESTED_VAR"]).to eq("original")
      end
    end
  end
end
