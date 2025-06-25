# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "coding_agent_tools/molecules/file_io_handler"

RSpec.describe CodingAgentTools::Molecules::FileIoHandler do
  let(:temp_dir) { Dir.mktmpdir }

  # Create a test-only path validator that allows all paths for testing
  let(:test_path_validator) do
    # For tests, we'll create a validator that allows all paths by overriding validate_path
    validator_class = Class.new(CodingAgentTools::Molecules::SecurePathValidator) do
      def validate_path(path, context = {})
        # For tests, just return a successful validation with the path as-is
        CodingAgentTools::Molecules::SecurePathValidator::ValidationResult.new(true, path, nil, nil)
      end
    end
    validator_class.new
  end

  let(:handler) { described_class.new(path_validator: test_path_validator) }

  after do
    FileUtils.remove_entry(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#file_path?" do
    context "with existing files" do
      let(:temp_file) { Tempfile.new("test") }

      after { temp_file.close! }

      it "returns true for existing file paths" do
        expect(handler.file_path?(temp_file.path)).to be true
      end

      it "returns true for existing file paths with whitespace" do
        expect(handler.file_path?("  #{temp_file.path}  ")).to be true
      end
    end

    context "with non-existing files" do
      it "returns false for non-existing file paths with extensions" do
        expect(handler.file_path?("/nonexistent/file.txt")).to be false
      end

      it "returns false for simple non-existing filenames with extensions" do
        expect(handler.file_path?("nonexistent_file.txt")).to be false
      end

      it "returns false for non-existing paths without extensions" do
        expect(handler.file_path?("/nonexistent/path")).to be false
      end
    end

    context "with inline content" do
      it "returns false for regular text content" do
        expect(handler.file_path?("Hello, world!")).to be false
      end

      it "returns false for multi-line content" do
        content = "Line 1\nLine 2\nLine 3"
        expect(handler.file_path?(content)).to be false
      end

      it "returns false for content with newlines" do
        expect(handler.file_path?("Hello\nWorld")).to be false
      end

      it "returns false for content with carriage returns" do
        expect(handler.file_path?("Hello\rWorld")).to be false
      end
    end

    context "with edge cases" do
      it "returns false for nil input" do
        expect(handler.file_path?(nil)).to be false
      end

      it "returns false for empty string" do
        expect(handler.file_path?("")).to be false
      end

      it "returns false for whitespace only" do
        expect(handler.file_path?("   ")).to be false
      end
    end
  end

  describe "#read_content" do
    context "with file paths" do
      let(:temp_file) { Tempfile.new("test") }
      let(:content) { "Test file content" }

      before do
        temp_file.write(content)
        temp_file.close
      end

      after { temp_file.unlink }

      it "reads content from existing files" do
        expect(handler.read_content(temp_file.path)).to eq content
      end

      it "reads content from files with auto-detection" do
        expect(handler.read_content(temp_file.path, auto_detect: true)).to eq content
      end

      it "treats as inline content when auto-detection is disabled" do
        expect(handler.read_content(temp_file.path, auto_detect: false)).to eq temp_file.path
      end
    end

    context "with inline content" do
      it "returns inline content as-is" do
        content = "Hello, world!"
        expect(handler.read_content(content)).to eq content
      end

      it "strips whitespace from inline content" do
        content = "  Hello, world!  "
        expect(handler.read_content(content)).to eq "Hello, world!"
      end
    end

    context "with empty content" do
      it "raises error for empty inline content" do
        expect {
          handler.read_content("")
        }.to raise_error(CodingAgentTools::Error, /Content cannot be empty/)
      end

      it "raises error for nil content" do
        expect {
          handler.read_content(nil)
        }.to raise_error(CodingAgentTools::Error, /Content cannot be empty/)
      end
    end
  end

  describe "#write_content" do
    let(:content) { "Test output content" }
    let(:output_path) { File.join(temp_dir, "output.txt") }

    it "writes content to file" do
      format = handler.write_content(content, output_path)

      expect(File.exist?(output_path)).to be true
      expect(File.read(output_path)).to eq content
      expect(format).to eq "text"
    end

    it "creates output directory if it doesn't exist" do
      nested_path = File.join(temp_dir, "nested", "dir", "output.txt")

      format = handler.write_content(content, nested_path)

      expect(File.exist?(nested_path)).to be true
      expect(File.read(nested_path)).to eq content
      expect(format).to eq "text"
    end

    it "respects format override" do
      format = handler.write_content(content, output_path, format: "json")

      expect(File.exist?(output_path)).to be true
      expect(format).to eq "json"
    end

    it "handles write errors gracefully" do
      invalid_path = "/root/cannot_write.txt"

      expect {
        handler.write_content(content, invalid_path)
      }.to raise_error(CodingAgentTools::Error, /Failed to write file/)
    end
  end

  describe "#infer_format_from_path" do
    it "infers json format from .json extension" do
      expect(handler.infer_format_from_path("output.json")).to eq "json"
    end

    it "infers markdown format from .md extension" do
      expect(handler.infer_format_from_path("output.md")).to eq "markdown"
    end

    it "infers markdown format from .markdown extension" do
      expect(handler.infer_format_from_path("output.markdown")).to eq "markdown"
    end

    it "infers text format from .txt extension" do
      expect(handler.infer_format_from_path("output.txt")).to eq "text"
    end

    it "infers text format from .text extension" do
      expect(handler.infer_format_from_path("output.text")).to eq "text"
    end

    it "defaults to text format for unknown extensions" do
      expect(handler.infer_format_from_path("output.xyz")).to eq "text"
    end

    it "defaults to text format for files without extensions" do
      expect(handler.infer_format_from_path("output")).to eq "text"
    end

    it "handles case-insensitive extensions" do
      expect(handler.infer_format_from_path("output.JSON")).to eq "json"
      expect(handler.infer_format_from_path("output.MD")).to eq "markdown"
    end

    it "defaults to text for nil or empty paths" do
      expect(handler.infer_format_from_path(nil)).to eq "text"
      expect(handler.infer_format_from_path("")).to eq "text"
      expect(handler.infer_format_from_path("   ")).to eq "text"
    end
  end

  describe "#supported_format?" do
    it "returns true for supported extensions" do
      expect(handler.supported_format?("file.json")).to be true
      expect(handler.supported_format?("file.md")).to be true
      expect(handler.supported_format?("file.markdown")).to be true
      expect(handler.supported_format?("file.txt")).to be true
      expect(handler.supported_format?("file.text")).to be true
    end

    it "returns false for unsupported extensions" do
      expect(handler.supported_format?("file.xyz")).to be false
      expect(handler.supported_format?("file.doc")).to be false
    end

    it "returns false for files without extensions" do
      expect(handler.supported_format?("file")).to be false
    end

    it "handles case-insensitive extensions" do
      expect(handler.supported_format?("file.JSON")).to be true
      expect(handler.supported_format?("file.MD")).to be true
    end

    it "returns false for nil or empty paths" do
      expect(handler.supported_format?(nil)).to be false
      expect(handler.supported_format?("")).to be false
      expect(handler.supported_format?("   ")).to be false
    end
  end

  describe "#supported_extensions" do
    it "returns array of supported extensions" do
      extensions = handler.supported_extensions
      expect(extensions).to include(".json", ".md", ".markdown", ".txt", ".text")
      expect(extensions).to be_an(Array)
    end
  end

  describe "#writable_path?" do
    it "returns true for writable paths in existing directories" do
      writable_path = File.join(temp_dir, "writable.txt")
      expect(handler.writable_path?(writable_path)).to be true
    end

    it "returns true for paths in non-existing but creatable directories" do
      nested_path = File.join(temp_dir, "new_dir", "writable.txt")
      expect(handler.writable_path?(nested_path)).to be true
    end

    it "returns false for paths in non-writable directories" do
      non_writable_path = "/root/cannot_write.txt"
      # This test might be platform-specific, so we'll skip if running as root
      skip "Running as root" if Process.uid == 0
      expect(handler.writable_path?(non_writable_path)).to be false
    end

    it "returns false for nil or empty paths" do
      expect(handler.writable_path?(nil)).to be false
      expect(handler.writable_path?("")).to be false
      expect(handler.writable_path?("   ")).to be false
    end
  end

  describe "file size limits" do
    context "with custom max file size" do
      let(:small_handler) { described_class.new(max_file_size: 10, path_validator: test_path_validator) }
      let(:temp_file) { Tempfile.new("large_test") }

      before do
        temp_file.write("This is a large content that exceeds the limit")
        temp_file.close
      end

      after { temp_file.unlink }

      it "raises error for files exceeding size limit" do
        expect {
          small_handler.read_content(temp_file.path)
        }.to raise_error(CodingAgentTools::Error, /File too large/)
      end
    end
  end
end
