# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/atoms/taskflow_management/yaml_frontmatter_parser"

RSpec.describe CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser do
  describe "ParseResult" do
    let(:frontmatter) { { "title" => "Test", "status" => "draft" } }
    let(:content) { "This is the content" }
    let(:raw_frontmatter) { "title: Test\nstatus: draft" }
    let(:parse_result) { described_class::ParseResult.new(frontmatter, content, raw_frontmatter, true) }

    describe "#valid?" do
      it "returns true when frontmatter is not nil" do
        expect(parse_result.valid?).to be true
      end

      it "returns false when frontmatter is nil" do
        result = described_class::ParseResult.new(nil, content, raw_frontmatter, false)
        expect(result.valid?).to be false
      end
    end

    describe "#empty_frontmatter?" do
      it "returns false when frontmatter has content" do
        expect(parse_result.empty_frontmatter?).to be false
      end

      it "returns true when frontmatter is nil" do
        result = described_class::ParseResult.new(nil, content, raw_frontmatter, false)
        expect(result.empty_frontmatter?).to be true
      end

      it "returns true when frontmatter is empty hash" do
        result = described_class::ParseResult.new({}, content, raw_frontmatter, true)
        expect(result.empty_frontmatter?).to be true
      end
    end
  end

  describe "ParseError" do
    let(:error) { described_class::ParseError.new("Test error", line_number: 5, column: 10, yaml_error: StandardError.new("YAML issue")) }

    it "stores line number, column, and yaml_error" do
      expect(error.line_number).to eq(5)
      expect(error.column).to eq(10)
      expect(error.yaml_error).to be_a(StandardError)
    end

    it "inherits from StandardError" do
      expect(error).to be_a(StandardError)
    end
  end

  describe "SecurityError" do
    let(:error) { described_class::SecurityError.new("Security issue") }

    it "inherits from StandardError" do
      expect(error).to be_a(StandardError)
    end
  end

  describe ".parse" do
    context "with valid frontmatter" do
      let(:content_with_frontmatter) do
        <<~CONTENT
          ---
          title: Test Document
          status: draft
          tags:
            - test
            - example
          ---
          
          This is the main content of the document.
          It can span multiple lines.
        CONTENT
      end

      it "parses frontmatter and content correctly" do
        result = described_class.parse(content_with_frontmatter)

        expect(result.valid?).to be true
        expect(result.has_frontmatter?).to be true
        expect(result.frontmatter["title"]).to eq("Test Document")
        expect(result.frontmatter["status"]).to eq("draft")
        expect(result.frontmatter["tags"]).to eq(["test", "example"])
        expect(result.content.strip).to start_with("This is the main content")
        expect(result.raw_frontmatter).to include("title: Test Document")
      end

      it "handles frontmatter with different delimiters" do
        content = "+++\ntitle: Test\n+++\nContent here"
        result = described_class.parse(content, delimiter: "+++")

        expect(result.valid?).to be true
        expect(result.frontmatter["title"]).to eq("Test")
        expect(result.content.strip).to eq("Content here")
      end

      it "handles empty frontmatter" do
        content = "---\n---\nContent only"
        result = described_class.parse(content)

        expect(result.valid?).to be true
        expect(result.empty_frontmatter?).to be true
        expect(result.content.strip).to eq("Content only")
      end
    end

    context "without frontmatter" do
      it "returns content without frontmatter extraction" do
        content = "This is just regular content without frontmatter"
        result = described_class.parse(content)

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq(content)
        expect(result.raw_frontmatter).to eq("")
      end

      it "handles content that starts with delimiter but has no closing delimiter" do
        content = "---\nThis looks like frontmatter but never closes\nMore content"
        result = described_class.parse(content)

        expect(result.has_frontmatter?).to be false
        expect(result.content).to eq(content)
      end
    end

    context "with empty or nil content" do
      it "handles empty content" do
        result = described_class.parse("")

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq("")
      end

      it "handles whitespace-only content" do
        result = described_class.parse("   \n\t  ")

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
      end

      it "raises ArgumentError for nil content" do
        expect { described_class.parse(nil) }.to raise_error(ArgumentError, /content cannot be nil/)
      end
    end

    context "with invalid parameters" do
      it "raises ArgumentError for nil delimiter" do
        expect { described_class.parse("content", delimiter: nil) }.to raise_error(ArgumentError, /delimiter cannot be nil/)
      end

      it "raises ArgumentError for empty delimiter" do
        expect { described_class.parse("content", delimiter: "") }.to raise_error(ArgumentError, /delimiter cannot be nil/)
      end
    end

    context "with malformed YAML" do
      it "raises ParseError for invalid YAML syntax" do
        content = "---\ntitle: Test\nstatus: [invalid yaml\n---\nContent"

        expect { described_class.parse(content) }.to raise_error(described_class::ParseError) do |error|
          expect(error.message).to include("Invalid YAML syntax")
          expect(error.yaml_error).to be_a(Psych::SyntaxError)
        end
      end

      it "raises ParseError when frontmatter is not a hash" do
        content = "---\n- item1\n- item2\n---\nContent"

        expect { described_class.parse(content) }.to raise_error(described_class::ParseError, /must be a hash/)
      end
    end

    context "with safe mode enabled" do
      it "raises SecurityError for dangerous YAML patterns" do
        dangerous_content = "---\n!ruby/object:User name: evil\n---\nContent"

        expect { described_class.parse(dangerous_content, safe_mode: true) }.to raise_error(described_class::SecurityError, /dangerous pattern/)
      end

      it "raises SecurityError for excessive nesting" do
        nested_yaml = "a: " + "{ b: " * 60 + "value" + " }" * 60
        content = "---\n#{nested_yaml}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /maximum nesting level/)
      end

      it "raises SecurityError for excessive length" do
        long_yaml = "key: " + "a" * 100_001
        content = "---\n#{long_yaml}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /maximum length/)
      end
    end

    context "with safe mode disabled" do
      it "allows more permissive YAML parsing" do
        content = "---\ntitle: Test\n---\nContent"
        result = described_class.parse(content, safe_mode: false)

        expect(result.valid?).to be true
        expect(result.frontmatter["title"]).to eq("Test")
      end
    end
  end

  describe ".parse_file" do
    let(:test_dir) { Dir.mktmpdir("yaml_parser_test") }
    let(:test_file) { File.join(test_dir, "test.md") }

    after do
      FileUtils.rm_rf(test_dir)
    end

    context "with valid file" do
      before do
        File.write(test_file, <<~CONTENT)
          ---
          title: File Test
          author: Test Author
          ---
          
          File content here.
        CONTENT
      end

      it "parses file content correctly" do
        result = described_class.parse_file(test_file)

        expect(result.valid?).to be true
        expect(result.frontmatter["title"]).to eq("File Test")
        expect(result.frontmatter["author"]).to eq("Test Author")
        expect(result.content.strip).to eq("File content here.")
      end

      it "respects delimiter parameter" do
        File.write(test_file, "+++\ntitle: Test\n+++\nContent")
        result = described_class.parse_file(test_file, delimiter: "+++")

        expect(result.frontmatter["title"]).to eq("Test")
      end

      it "respects safe_mode parameter" do
        File.write(test_file, "---\ntitle: Test\n---\nContent")
        result = described_class.parse_file(test_file, safe_mode: false)

        expect(result.valid?).to be true
      end
    end

    context "with invalid file parameters" do
      it "raises ArgumentError for nil file_path" do
        expect { described_class.parse_file(nil) }.to raise_error(ArgumentError, /file_path cannot be nil/)
      end

      it "raises ArgumentError for empty file_path" do
        expect { described_class.parse_file("") }.to raise_error(ArgumentError, /file_path cannot be nil/)
      end

      it "raises ArgumentError for non-existent file" do
        expect { described_class.parse_file("/nonexistent/file.md") }.to raise_error(ArgumentError, /File does not exist/)
      end

      it "raises SecurityError for file path with null bytes" do
        expect { described_class.parse_file("file\0path") }.to raise_error(described_class::SecurityError, /invalid characters/)
      end

      it "raises SecurityError for file path with control characters" do
        expect { described_class.parse_file("file\x01path") }.to raise_error(described_class::SecurityError, /invalid characters/)
      end
    end

    context "with file access issues" do
      let(:unreadable_file) { File.join(test_dir, "unreadable.md") }

      before do
        File.write(unreadable_file, "content")
        FileUtils.chmod(0000, unreadable_file)
      end

      after do
        FileUtils.chmod(0644, unreadable_file)
      end

      it "raises ArgumentError for unreadable file" do
        expect { described_class.parse_file(unreadable_file) }.to raise_error(ArgumentError, /not readable/)
      end
    end

    context "with encoding issues" do
      let(:binary_file) { File.join(test_dir, "binary.md") }

      before do
        File.open(binary_file, "wb") { |f| f.write("\xFF\xFE\x00\x01") }
      end

      it "handles invalid UTF-8 content gracefully" do
        expect { described_class.parse_file(binary_file) }.to raise_error(ArgumentError, /invalid byte sequence|invalid UTF-8 content/)
      end
    end
  end

  describe ".has_frontmatter?" do
    it "returns true for content with valid frontmatter" do
      content = "---\ntitle: Test\n---\nContent"
      expect(described_class.has_frontmatter?(content)).to be true
    end

    it "returns false for content without frontmatter" do
      content = "Just regular content"
      expect(described_class.has_frontmatter?(content)).to be false
    end

    it "returns false for content with opening delimiter but no closing" do
      content = "---\ntitle: Test\nNo closing delimiter"
      expect(described_class.has_frontmatter?(content)).to be false
    end

    it "returns false for nil content" do
      expect(described_class.has_frontmatter?(nil)).to be false
    end

    it "returns false for empty content" do
      expect(described_class.has_frontmatter?("")).to be false
    end

    it "supports custom delimiters" do
      content = "+++\ntitle: Test\n+++\nContent"
      expect(described_class.has_frontmatter?(content, delimiter: "+++")).to be true
    end
  end

  describe ".extract_frontmatter" do
    it "extracts only the frontmatter hash" do
      content = "---\ntitle: Test\nstatus: draft\n---\nContent here"
      frontmatter = described_class.extract_frontmatter(content)

      expect(frontmatter).to eq({ "title" => "Test", "status" => "draft" })
    end

    it "returns empty hash when no frontmatter exists" do
      content = "Just content"
      frontmatter = described_class.extract_frontmatter(content)

      expect(frontmatter).to eq({})
    end

    it "supports custom delimiters" do
      content = "+++\ntitle: Test\n+++\nContent"
      frontmatter = described_class.extract_frontmatter(content, delimiter: "+++")

      expect(frontmatter["title"]).to eq("Test")
    end

    it "respects safe_mode parameter" do
      content = "---\ntitle: Test\n---\nContent"
      frontmatter = described_class.extract_frontmatter(content, safe_mode: false)

      expect(frontmatter["title"]).to eq("Test")
    end
  end

  describe ".extract_content" do
    it "extracts only the content without frontmatter" do
      content = "---\ntitle: Test\n---\nThis is the content"
      extracted = described_class.extract_content(content)

      expect(extracted.strip).to eq("This is the content")
    end

    it "returns full content when no frontmatter exists" do
      content = "This is just content"
      extracted = described_class.extract_content(content)

      expect(extracted).to eq(content)
    end

    it "supports custom delimiters" do
      content = "+++\ntitle: Test\n+++\nContent here"
      extracted = described_class.extract_content(content, delimiter: "+++")

      expect(extracted.strip).to eq("Content here")
    end
  end

  describe ".validate_frontmatter" do
    let(:valid_frontmatter) { { "title" => "Test", "status" => "draft", "tags" => ["test"] } }

    context "with valid frontmatter" do
      it "returns valid result for complete frontmatter" do
        result = described_class.validate_frontmatter(valid_frontmatter)

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:warnings]).to be_empty
      end

      it "validates required keys" do
        result = described_class.validate_frontmatter(valid_frontmatter, required_keys: ["title", "status"])

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end

      it "validates allowed keys" do
        result = described_class.validate_frontmatter(valid_frontmatter, allowed_keys: ["title", "status", "tags", "author"])

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to be_empty
      end
    end

    context "with missing required keys" do
      it "reports missing required keys" do
        result = described_class.validate_frontmatter(valid_frontmatter, required_keys: ["title", "author"])

        expect(result[:valid?]).to be false
        expect(result[:errors]).to include("Missing required key: author")
      end

      it "handles symbol keys in frontmatter" do
        frontmatter_with_symbols = { title: "Test", status: "draft" }
        result = described_class.validate_frontmatter(frontmatter_with_symbols, required_keys: ["title", "status"])

        expect(result[:valid?]).to be true
      end
    end

    context "with unknown keys" do
      it "warns about unknown keys when allowed_keys is specified" do
        result = described_class.validate_frontmatter(valid_frontmatter, allowed_keys: ["title", "status"])

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to include("Unknown key: tags")
      end

      it "allows all keys when allowed_keys is nil" do
        result = described_class.validate_frontmatter(valid_frontmatter, allowed_keys: nil)

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to be_empty
      end
    end

    context "with nil or empty frontmatter" do
      it "returns valid result for nil frontmatter" do
        result = described_class.validate_frontmatter(nil)

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end

      it "returns valid result for empty frontmatter" do
        result = described_class.validate_frontmatter({})

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "security features" do
    describe "dangerous pattern detection" do
      let(:dangerous_patterns) do
        [
          "!ruby/object:User",
          "!ruby/class:String", 
          "!!ruby/object",
          "!!python/object",
          "<%=",
          "{{variable}}",
          "${variable}",
          "eval(",
          "system(",
          "`command`",
          "require 'file'",
          "load 'file'",
          "send :method",
          "define_method",
          "class_eval",
          "module_eval",
          "instance_eval"
        ]
      end

      it "detects various dangerous patterns" do
        # Test specific dangerous patterns from the implementation
        dangerous_content_examples = [
          "---\nkey: !ruby/object:User\n---\nContent",
          "---\nkey: !ruby/class:String\n---\nContent", 
          "---\nkey: !!ruby/object\n---\nContent",
          "---\nkey: !!python/object\n---\nContent",
          "---\nkey: <% code %>\n---\nContent",
          "---\nkey: {{ variable }}\n---\nContent",
          "---\nkey: ${variable}\n---\nContent",
          "---\nkey: `command`\n---\nContent",
          "---\nkey: eval(code)\n---\nContent",
          "---\nkey: system('command')\n---\nContent"
        ]
        
        dangerous_content_examples.each do |content|
          expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /dangerous pattern/)
        end
      end
    end

    describe "nesting limits" do
      it "prevents YAML bombs through excessive nesting" do
        # Create deeply nested structure
        nested = "a: " + ("{ b: " * 60) + "value" + (" }" * 60)
        content = "---\n#{nested}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /nesting level/)
      end
    end

    describe "length limits" do
      it "prevents processing of excessively long YAML" do
        long_value = "a" * 100_001
        content = "---\nkey: #{long_value}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /maximum length/)
      end
    end
  end

  describe "private methods" do
    describe ".find_closing_delimiter" do
      it "finds closing delimiter correctly" do
        lines = ["---", "title: Test", "status: draft", "---", "Content line"]
        index = described_class.send(:find_closing_delimiter, lines, "---")

        expect(index).to eq(3)
      end

      it "returns nil when closing delimiter not found" do
        lines = ["---", "title: Test", "status: draft", "Content line"]
        index = described_class.send(:find_closing_delimiter, lines, "---")

        expect(index).to be_nil
      end
    end

    describe ".parse_yaml_safely" do
      it "parses valid YAML in safe mode" do
        yaml_content = "title: Test\nstatus: draft"
        result = described_class.send(:parse_yaml_safely, yaml_content, true)

        expect(result).to eq({ "title" => "Test", "status" => "draft" })
      end

      it "returns empty hash for empty YAML" do
        result = described_class.send(:parse_yaml_safely, "", true)

        expect(result).to eq({})
      end

      it "raises ParseError for malformed YAML" do
        yaml_content = "title: Test\nstatus: [invalid"

        expect { described_class.send(:parse_yaml_safely, yaml_content, true) }.to raise_error(described_class::ParseError)
      end
    end

    describe ".perform_security_checks" do
      it "allows safe YAML content" do
        safe_yaml = "title: Test\nstatus: draft\ntags:\n  - test\n  - example"

        expect { described_class.send(:perform_security_checks, safe_yaml) }.not_to raise_error
      end

      it "rejects dangerous patterns" do
        dangerous_yaml = "content: !ruby/object:User"

        expect { described_class.send(:perform_security_checks, dangerous_yaml) }.to raise_error(described_class::SecurityError)
      end
    end
  end
end