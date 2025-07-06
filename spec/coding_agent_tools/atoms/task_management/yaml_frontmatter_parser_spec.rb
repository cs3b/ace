# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::TaskManagement::YamlFrontmatterParser do
  let(:parser) { described_class }

  describe ".parse" do
    context "with valid frontmatter" do
      let(:content_with_frontmatter) do
        <<~CONTENT
          ---
          title: Test Document
          author: John Doe
          tags:
            - ruby
            - testing
          status: published
          ---

          # Main Content

          This is the main content of the document.
          It can contain multiple lines and **markdown**.
        CONTENT
      end

      it "parses frontmatter and content correctly" do
        result = parser.parse(content_with_frontmatter)

        expect(result).to be_a(described_class::ParseResult)
        expect(result.valid?).to be true
        expect(result.has_frontmatter?).to be true
        expect(result.empty_frontmatter?).to be false

        expect(result.frontmatter).to be_a(Hash)
        expect(result.frontmatter["title"]).to eq("Test Document")
        expect(result.frontmatter["author"]).to eq("John Doe")
        expect(result.frontmatter["tags"]).to eq(["ruby", "testing"])
        expect(result.frontmatter["status"]).to eq("published")

        expect(result.content).to include("# Main Content")
        expect(result.content).to include("This is the main content")
        expect(result.raw_frontmatter).to include("title: Test Document")
      end

      it "handles minimal frontmatter" do
        content = "---\ntitle: Simple\n---\nContent here"
        result = parser.parse(content)

        expect(result.frontmatter["title"]).to eq("Simple")
        expect(result.content.strip).to eq("Content here")
      end

      it "handles empty frontmatter" do
        content = "---\n---\nContent here"
        result = parser.parse(content)

        expect(result.frontmatter).to eq({})
        expect(result.has_frontmatter?).to be true
        expect(result.empty_frontmatter?).to be true
        expect(result.content.strip).to eq("Content here")
      end
    end

    context "without frontmatter" do
      let(:content_without_frontmatter) do
        <<~CONTENT
          # Regular Markdown

          This is just regular content without any frontmatter.
          No YAML here.
        CONTENT
      end

      it "handles content without frontmatter" do
        result = parser.parse(content_without_frontmatter)

        expect(result.valid?).to be true
        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq(content_without_frontmatter)
        expect(result.raw_frontmatter).to eq("")
      end

      it "handles content starting with partial delimiter" do
        content = "--incomplete\nContent here"
        result = parser.parse(content)

        expect(result.has_frontmatter?).to be false
        expect(result.content).to eq(content)
      end

      it "handles content with no closing delimiter" do
        content = "---\ntitle: Test\nNo closing delimiter\nContent here"
        result = parser.parse(content)

        expect(result.has_frontmatter?).to be false
        expect(result.content).to eq(content)
      end
    end

    context "with empty or nil content" do
      it "handles empty content" do
        result = parser.parse("")

        expect(result.valid?).to be true
        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq("")
      end

      it "handles whitespace-only content" do
        result = parser.parse("   \n  \n  ")

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
      end

      it "raises ArgumentError for nil content" do
        expect { parser.parse(nil) }.to raise_error(ArgumentError, "content cannot be nil")
      end
    end

    context "with custom delimiters" do
      it "uses custom delimiter" do
        content = "+++\ntitle: Custom\n+++\nContent"
        result = parser.parse(content, delimiter: "+++")

        expect(result.has_frontmatter?).to be true
        expect(result.frontmatter["title"]).to eq("Custom")
        expect(result.content.strip).to eq("Content")
      end

      it "raises ArgumentError for nil delimiter" do
        expect { parser.parse("content", delimiter: nil) }.to raise_error(ArgumentError, "delimiter cannot be nil or empty")
      end

      it "raises ArgumentError for empty delimiter" do
        expect { parser.parse("content", delimiter: "") }.to raise_error(ArgumentError, "delimiter cannot be nil or empty")
      end
    end

    context "with malformed YAML" do
      it "raises ParseError for invalid YAML syntax" do
        content = "---\ntitle: [unclosed\n---\nContent"

        expect { parser.parse(content) }.to raise_error(described_class::ParseError) do |error|
          expect(error.message).to include("Invalid YAML syntax")
          expect(error.yaml_error).to be_a(Psych::SyntaxError)
        end
      end

      it "raises ParseError for non-hash YAML" do
        content = "---\n- not a hash\n---\nContent"

        expect { parser.parse(content) }.to raise_error(described_class::ParseError) do |error|
          expect(error.message).to include("YAML frontmatter must be a hash")
        end
      end
    end

    context "with safe mode disabled" do
      it "allows more permissive YAML parsing" do
        content = "---\ntitle: Test\n---\nContent"
        result = parser.parse(content, safe_mode: false)

        expect(result.frontmatter["title"]).to eq("Test")
      end
    end

    context "with security concerns" do
      it "raises SecurityError for dangerous YAML patterns in safe mode" do
        dangerous_content = "---\n!ruby/object:SomeClass {}\n---\nContent"

        expect { parser.parse(dangerous_content, safe_mode: true) }.to raise_error(described_class::SecurityError) do |error|
          expect(error.message).to include("potentially dangerous pattern")
        end
      end

      it "raises SecurityError for excessive nesting" do
        # Create deeply nested YAML
        nested_yaml = "---\n" + "a: {" * 60 + "value: test" + "}" * 60 + "\n---\nContent"

        expect { parser.parse(nested_yaml, safe_mode: true) }.to raise_error(described_class::SecurityError) do |error|
          expect(error.message).to include("exceeds maximum nesting level")
        end
      end

      it "raises SecurityError for excessively long YAML" do
        long_yaml = "---\ntitle: #{"a" * 100_001}\n---\nContent"

        expect { parser.parse(long_yaml, safe_mode: true) }.to raise_error(described_class::SecurityError) do |error|
          expect(error.message).to include("exceeds maximum length")
        end
      end
    end
  end

  describe ".parse_file" do
    let(:test_dir) { Dir.mktmpdir("yaml_parser_test") }
    let(:test_file) { File.join(test_dir, "test.md") }

    before do
      File.write(test_file, <<~CONTENT)
        ---
        title: File Test
        author: Test Author
        ---

        # File Content

        This content was read from a file.
      CONTENT
    end

    after do
      FileUtils.rm_rf(test_dir)
    end

    it "parses frontmatter from file" do
      result = parser.parse_file(test_file)

      expect(result.valid?).to be true
      expect(result.frontmatter["title"]).to eq("File Test")
      expect(result.frontmatter["author"]).to eq("Test Author")
      expect(result.content).to include("# File Content")
    end

    it "raises ArgumentError for nil file_path" do
      expect { parser.parse_file(nil) }.to raise_error(ArgumentError, "file_path cannot be nil or empty")
    end

    it "raises ArgumentError for empty file_path" do
      expect { parser.parse_file("") }.to raise_error(ArgumentError, "file_path cannot be nil or empty")
    end

    it "raises ArgumentError for non-existent file" do
      expect { parser.parse_file("/non/existent/file.md") }.to raise_error(ArgumentError, /File does not exist/)
    end

    it "raises SecurityError for file paths with null bytes" do
      expect { parser.parse_file("test\0file.md") }.to raise_error(described_class::SecurityError, /invalid characters/)
    end

    context "with encoding issues" do
      let(:binary_file) { File.join(test_dir, "binary.md") }

      before do
        # Create file with binary content but valid UTF-8 frontmatter
        content = "---\ntitle: Binary Test\n---\nContent"
        File.binwrite(binary_file, content.dup.force_encoding("BINARY"))
      end

      it "handles files with encoding issues" do
        result = parser.parse_file(binary_file)
        expect(result.frontmatter["title"]).to eq("Binary Test")
      end
    end
  end

  describe ".has_frontmatter?" do
    it "returns true for content with frontmatter" do
      content = "---\ntitle: Test\n---\nContent"
      expect(parser.has_frontmatter?(content)).to be true
    end

    it "returns false for content without frontmatter" do
      content = "# Regular Content\nNo frontmatter here"
      expect(parser.has_frontmatter?(content)).to be false
    end

    it "returns false for content with only opening delimiter" do
      content = "---\ntitle: Test\nNo closing"
      expect(parser.has_frontmatter?(content)).to be false
    end

    it "returns false for empty content" do
      expect(parser.has_frontmatter?("")).to be false
      expect(parser.has_frontmatter?(nil)).to be false
    end
  end

  describe ".extract_frontmatter" do
    it "extracts only the frontmatter" do
      content = "---\ntitle: Test\nauthor: John\n---\nContent here"
      frontmatter = parser.extract_frontmatter(content)

      expect(frontmatter).to be_a(Hash)
      expect(frontmatter["title"]).to eq("Test")
      expect(frontmatter["author"]).to eq("John")
    end

    it "returns empty hash for content without frontmatter" do
      content = "Regular content without frontmatter"
      frontmatter = parser.extract_frontmatter(content)

      expect(frontmatter).to eq({})
    end
  end

  describe ".extract_content" do
    it "extracts only the content" do
      content = "---\ntitle: Test\n---\n# Main Content\nThis is the body"
      extracted = parser.extract_content(content)

      expect(extracted).to include("# Main Content")
      expect(extracted).to include("This is the body")
      expect(extracted).not_to include("title: Test")
    end

    it "returns full content for content without frontmatter" do
      content = "Regular content without frontmatter"
      extracted = parser.extract_content(content)

      expect(extracted).to eq(content)
    end
  end

  describe ".validate_frontmatter" do
    let(:valid_frontmatter) do
      {
        "title" => "Test Document",
        "author" => "John Doe",
        "status" => "published"
      }
    end

    it "validates frontmatter with no constraints" do
      result = parser.validate_frontmatter(valid_frontmatter)

      expect(result[:valid?]).to be true
      expect(result[:errors]).to be_empty
      expect(result[:warnings]).to be_empty
    end

    it "validates required keys" do
      result = parser.validate_frontmatter(valid_frontmatter, required_keys: ["title", "author"])

      expect(result[:valid?]).to be true
      expect(result[:errors]).to be_empty
    end

    it "reports missing required keys" do
      result = parser.validate_frontmatter(valid_frontmatter, required_keys: ["title", "missing_key"])

      expect(result[:valid?]).to be false
      expect(result[:errors]).to include("Missing required key: missing_key")
    end

    it "validates allowed keys" do
      result = parser.validate_frontmatter(valid_frontmatter, allowed_keys: ["title", "author", "status"])

      expect(result[:valid?]).to be true
      expect(result[:warnings]).to be_empty
    end

    it "reports unknown keys as warnings" do
      result = parser.validate_frontmatter(valid_frontmatter, allowed_keys: ["title", "author"])

      expect(result[:valid?]).to be true
      expect(result[:warnings]).to include("Unknown key: status")
    end

    it "handles empty frontmatter" do
      result = parser.validate_frontmatter({})

      expect(result[:valid?]).to be true
      expect(result[:errors]).to be_empty
    end

    it "handles nil frontmatter" do
      result = parser.validate_frontmatter(nil)

      expect(result[:valid?]).to be true
      expect(result[:errors]).to be_empty
    end
  end
end
