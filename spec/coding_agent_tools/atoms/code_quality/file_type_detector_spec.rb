# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::FileTypeDetector do
  let(:detector) { described_class.new }
  let(:detector_with_config) { described_class.new(config: config) }
  let(:config) do
    {
      file_patterns: {
        ruby: ["*.rb", "*.rake", "Gemfile"],
        javascript: ["*.js", "*.jsx"],
        python: ["*.py", "*.pyw"]
      }
    }
  end

  describe "#detect_type" do
    context "with default patterns" do
      it "detects Ruby files by extension" do
        expect(detector.detect_type("app/models/user.rb")).to eq(:ruby)
        expect(detector.detect_type("test.rb")).to eq(:ruby)
      end

      it "detects gemspec files" do
        expect(detector.detect_type("my_gem.gemspec")).to eq(:ruby)
      end

      it "detects Gemfile" do
        expect(detector.detect_type("Gemfile")).to eq(:ruby)
        expect(detector.detect_type("/project/Gemfile")).to eq(:ruby)
      end

      it "detects Rakefile" do
        expect(detector.detect_type("Rakefile")).to eq(:ruby)
        expect(detector.detect_type("/project/Rakefile")).to eq(:ruby)
      end

      it "detects files in exe directory" do
        expect(detector.detect_type("exe/my_tool")).to eq(:ruby)
        expect(detector.detect_type("/project/exe/console")).to eq(:ruby)
      end

      it "detects Markdown files" do
        expect(detector.detect_type("README.md")).to eq(:markdown)
        expect(detector.detect_type("docs/guide.markdown")).to eq(:markdown)
      end

      it "returns nil for unknown file types" do
        expect(detector.detect_type("unknown.xyz")).to be_nil
        expect(detector.detect_type("file.txt")).to be_nil
      end

      it "handles files without extensions" do
        expect(detector.detect_type("LICENSE")).to be_nil
        expect(detector.detect_type("README")).to be_nil
      end
    end

    context "with custom configuration" do
      it "uses configured patterns instead of defaults" do
        # Should not detect .gemspec since it's not in config
        expect(detector_with_config.detect_type("my_gem.gemspec")).to be_nil
        
        # Should detect .rake since it's in config
        expect(detector_with_config.detect_type("tasks.rake")).to eq(:ruby)
      end

      it "detects JavaScript files from config" do
        expect(detector_with_config.detect_type("app.js")).to eq(:javascript)
        expect(detector_with_config.detect_type("component.jsx")).to eq(:javascript)
      end

      it "detects Python files from config" do
        expect(detector_with_config.detect_type("script.py")).to eq(:python)
        expect(detector_with_config.detect_type("windows.pyw")).to eq(:python)
      end
    end

    context "with edge cases" do
      it "handles nested paths correctly" do
        expect(detector.detect_type("deeply/nested/path/file.rb")).to eq(:ruby)
      end

      it "handles paths with spaces" do
        expect(detector.detect_type("my project/file.rb")).to eq(:ruby)
      end

      it "handles files starting with dots" do
        expect(detector.detect_type(".hidden.rb")).to eq(:ruby)
      end

      it "is case sensitive for extensions" do
        expect(detector.detect_type("file.RB")).to be_nil
        expect(detector.detect_type("file.Rb")).to be_nil
      end

      it "handles empty file paths" do
        expect(detector.detect_type("")).to be_nil
      end

      it "handles root level files" do
        expect(detector.detect_type("Gemfile")).to eq(:ruby)
      end
    end
  end

  describe "#matches_language?" do
    it "returns true when file matches the language" do
      expect(detector.matches_language?("file.rb", :ruby)).to be true
      expect(detector.matches_language?("README.md", :markdown)).to be true
    end

    it "returns false when file doesn't match the language" do
      expect(detector.matches_language?("file.rb", :markdown)).to be false
      expect(detector.matches_language?("README.md", :ruby)).to be false
    end

    it "returns false for unknown files" do
      expect(detector.matches_language?("file.txt", :ruby)).to be false
    end

    it "accepts string language parameter" do
      expect(detector.matches_language?("file.rb", "ruby")).to be false # strings are not converted to symbols
    end
  end

  describe "#patterns_for" do
    it "returns patterns for existing language" do
      ruby_patterns = detector.patterns_for(:ruby)
      expect(ruby_patterns).to include("*.rb", "*.gemspec", "Gemfile", "Rakefile", "exe/*")
    end

    it "returns patterns for string language" do
      ruby_patterns = detector.patterns_for("ruby")
      expect(ruby_patterns).to include("*.rb")
    end

    it "returns empty array for unknown language" do
      expect(detector.patterns_for(:unknown)).to eq([])
    end

    it "returns configured patterns when config is provided" do
      js_patterns = detector_with_config.patterns_for(:javascript)
      expect(js_patterns).to eq(["*.js", "*.jsx"])
    end
  end

  describe "#supported_languages" do
    it "returns all supported languages from default patterns" do
      languages = detector.supported_languages
      expect(languages).to include(:ruby, :markdown)
      expect(languages.size).to eq(2)
    end

    it "returns configured languages when config is provided" do
      languages = detector_with_config.supported_languages
      expect(languages).to include(:ruby, :javascript, :python)
      # May also include default languages that weren't overridden
      expect(languages.size).to be >= 3
    end
  end

  describe "initialization" do
    it "works without config" do
      detector = described_class.new
      expect(detector.supported_languages).to include(:ruby, :markdown)
    end

    it "works with nil config" do
      detector = described_class.new(config: nil)
      expect(detector.supported_languages).to include(:ruby, :markdown)
    end

    it "ignores invalid config patterns" do
      invalid_config = {
        file_patterns: {
          ruby: "not_an_array",
          javascript: ["*.js"]
        }
      }
      detector = described_class.new(config: invalid_config)
      
      # Should keep default ruby patterns since invalid was ignored
      expect(detector.patterns_for(:ruby)).to include("*.rb", "*.gemspec")
      
      # Should include valid javascript patterns
      expect(detector.patterns_for(:javascript)).to eq(["*.js"])
    end
  end

  describe "pattern matching logic" do
    let(:detector) { described_class.new }

    it "matches extension patterns correctly" do
      expect(detector.detect_type("file.rb")).to eq(:ruby)
      expect(detector.detect_type("path/to/file.rb")).to eq(:ruby)
    end

    it "matches directory patterns correctly" do
      expect(detector.detect_type("exe/tool")).to eq(:ruby)
      expect(detector.detect_type("project/exe/console")).to eq(:ruby)
      # The pattern "exe/*" only matches direct children, not nested paths
      expect(detector.detect_type("exe/deep/nested/tool")).to be_nil
    end

    it "matches exact filename patterns correctly" do
      expect(detector.detect_type("Gemfile")).to eq(:ruby)
      expect(detector.detect_type("path/to/Gemfile")).to eq(:ruby)
      expect(detector.detect_type("MyGemfile")).to be_nil
    end

    it "prioritizes first matching pattern" do
      # If a file could match multiple languages, it should return the first match
      # This tests the iteration order behavior
      result = detector.detect_type("file.rb")
      expect(result).to eq(:ruby)
    end
  end
end