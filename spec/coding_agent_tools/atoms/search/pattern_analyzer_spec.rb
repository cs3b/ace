# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Search::PatternAnalyzer do
  describe ".analyze_pattern" do
    context "with file glob patterns" do
      it "identifies simple glob patterns" do
        result = described_class.analyze_pattern("*.rb")

        expect(result[:type]).to eq(:file_glob)
        expect(result[:confidence]).to be > 0.8
        expect(result[:suggested_tool]).to eq("fd")
      end

      it "identifies recursive glob patterns" do
        result = described_class.analyze_pattern("**/*.js")

        expect(result[:type]).to eq(:file_glob)
        expect(result[:confidence]).to be > 0.8
        expect(result[:suggested_tool]).to eq("fd")
      end

      it "identifies directory glob patterns" do
        result = described_class.analyze_pattern("src/**/*.ts")

        expect(result[:type]).to eq(:file_glob)
        expect(result[:confidence]).to be > 0.8
        expect(result[:suggested_tool]).to eq("fd")
      end
    end

    context "with content regex patterns" do
      it "identifies method definition patterns" do
        result = described_class.analyze_pattern("def initialize")

        expect(result[:type]).to eq(:content_regex)
        expect(result[:confidence]).to be > 0.6
        expect(result[:suggested_tool]).to eq("rg")
      end

      it "identifies class definition patterns" do
        result = described_class.analyze_pattern('class \\w+')

        expect(result[:type]).to eq(:content_regex)
        expect(result[:confidence]).to be > 0.6
        expect(result[:suggested_tool]).to eq("rg")
      end

      it "identifies regex metacharacters" do
        result = described_class.analyze_pattern("foo.*bar")

        expect(result[:type]).to eq(:content_regex)
        expect(result[:confidence]).to be > 0.6
        expect(result[:suggested_tool]).to eq("rg")
      end

      it "identifies code annotation patterns" do
        result = described_class.analyze_pattern("TODO: fix this")

        expect(result[:type]).to eq(:content_regex)
        expect(result[:confidence]).to be > 0.6
        expect(result[:suggested_tool]).to eq("rg")
      end
    end

    context "with literal patterns" do
      it "identifies simple word patterns" do
        result = described_class.analyze_pattern("hello")

        expect(result[:type]).to eq(:literal)
        expect(result[:confidence]).to be > 0.6
        expect(result[:suggested_tool]).to eq("rg")
      end

      it "identifies quoted string patterns" do
        result = described_class.analyze_pattern('"hello world"')

        expect(result[:type]).to eq(:literal)
        expect(result[:confidence]).to be > 0.8
        expect(result[:suggested_tool]).to eq("rg")
      end

      it "identifies phrases with spaces" do
        result = described_class.analyze_pattern("hello world")

        expect(result[:type]).to eq(:literal)
        expect(result[:confidence]).to be > 0.6
        expect(result[:suggested_tool]).to eq("rg")
      end
    end

    context "with invalid patterns" do
      it "handles nil pattern" do
        result = described_class.analyze_pattern(nil)

        expect(result[:type]).to eq(:invalid)
        expect(result[:confidence]).to eq(0.0)
        expect(result[:reason]).to include("nil")
      end

      it "handles empty pattern" do
        result = described_class.analyze_pattern("")

        expect(result[:type]).to eq(:invalid)
        expect(result[:confidence]).to eq(0.0)
        expect(result[:reason]).to include("empty")
      end
    end

    context "with hybrid patterns" do
      it "identifies ambiguous patterns as hybrid" do
        result = described_class.analyze_pattern("config")

        # This could be a filename or content search
        expect(result[:type]).to eq(:hybrid)
        expect(result[:confidence]).to eq(0.5)
        expect(result[:suggested_tool]).to eq("both")
      end
    end
  end

  describe ".file_glob_pattern?" do
    it "returns true for glob patterns" do
      expect(described_class.file_glob_pattern?("*.rb")).to be true
      expect(described_class.file_glob_pattern?("**/*.js")).to be true
      expect(described_class.file_glob_pattern?("src/*")).to be true
      expect(described_class.file_glob_pattern?("test.rb")).to be true
    end

    it "returns false for non-glob patterns" do
      expect(described_class.file_glob_pattern?("hello world")).to be false
      expect(described_class.file_glob_pattern?("def initialize")).to be false
    end
  end

  describe ".content_regex_pattern?" do
    it "returns true for regex patterns" do
      expect(described_class.content_regex_pattern?("foo.*bar")).to be true
      expect(described_class.content_regex_pattern?('def \\w+')).to be true
      expect(described_class.content_regex_pattern?("^start")).to be true
      expect(described_class.content_regex_pattern?("end$")).to be true
    end

    it "returns false for simple text patterns" do
      expect(described_class.content_regex_pattern?("hello")).to be false
      expect(described_class.content_regex_pattern?("simple text")).to be false
    end
  end

  describe ".literal_pattern?" do
    it "returns true for literal patterns" do
      expect(described_class.literal_pattern?("hello")).to be true
      expect(described_class.literal_pattern?("hello world")).to be true
      expect(described_class.literal_pattern?('"quoted string"')).to be true
      expect(described_class.literal_pattern?("'single quoted'")).to be true
    end

    it "returns false for complex patterns" do
      expect(described_class.literal_pattern?("*.rb")).to be false
      expect(described_class.literal_pattern?("foo.*bar")).to be false
    end
  end

  describe ".suggest_search_mode" do
    it "respects explicit flags" do
      expect(described_class.suggest_search_mode("anything", files_only: true)).to eq(:files)
      expect(described_class.suggest_search_mode("anything", content_only: true)).to eq(:content)
      expect(described_class.suggest_search_mode("anything", name_only: true)).to eq(:files)
    end

    it "suggests files mode for glob patterns" do
      expect(described_class.suggest_search_mode("*.rb")).to eq(:files)
      expect(described_class.suggest_search_mode("**/*.js")).to eq(:files)
    end

    it "suggests content mode for regex patterns" do
      expect(described_class.suggest_search_mode("def initialize")).to eq(:content)
      expect(described_class.suggest_search_mode("foo.*bar")).to eq(:content)
    end

    it "suggests content mode for literal patterns" do
      expect(described_class.suggest_search_mode("hello world")).to eq(:content)
    end

    it "suggests both mode for hybrid patterns" do
      expect(described_class.suggest_search_mode("config")).to eq(:both)
    end
  end

  describe ".extract_extensions" do
    it "extracts extensions from glob patterns" do
      expect(described_class.extract_extensions("*.rb")).to eq(["rb"])
      expect(described_class.extract_extensions("**/*.js")).to eq(["js"])
      expect(described_class.extract_extensions("src/**/*.{rb,js}")).to eq(["rb"])
    end

    it "extracts extensions from file paths" do
      expect(described_class.extract_extensions("test.rb")).to eq(["rb"])
      expect(described_class.extract_extensions("app/models/user.rb")).to eq(["rb"])
    end

    it "extracts multiple extensions" do
      expect(described_class.extract_extensions("*.{rb,js}")).to eq(["rb"])
    end

    it "returns empty array when no extensions found" do
      expect(described_class.extract_extensions("hello world")).to eq([])
      expect(described_class.extract_extensions("def initialize")).to eq([])
    end
  end
end
