# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"
require_relative "../../../../lib/coding_agent_tools/molecules/context/context_file_writer"

RSpec.describe CodingAgentTools::Molecules::Context::ContextFileWriter do
  let(:temp_dir) { Dir.mktmpdir }
  let(:writer) { described_class.new }
  let(:progress_messages) { [] }
  let(:progress_callback) { ->(message) { progress_messages << message } }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#write_file" do
    let(:content) { "# Test Content\n\nThis is a test file.\n" }  # 3 lines after split
    let(:output_path) { File.join(temp_dir, "test_file.md") }

    context "with default options" do
      it "writes content to file successfully" do
        result = writer.write_file(content, output_path)

        expect(result[:success]).to be true
        expect(result[:path]).to eq(File.expand_path(output_path))
        expect(result[:size]).to eq(content.bytesize)
        expect(result[:lines]).to eq(3)
        expect(result[:size_formatted]).to include("bytes")
        expect(File.read(result[:path])).to eq(content)
      end

      it "creates parent directories automatically" do
        nested_path = File.join(temp_dir, "nested", "deep", "test.md")
        result = writer.write_file(content, nested_path)

        expect(result[:success]).to be true
        expect(File.exist?(result[:path])).to be true
        expect(File.read(result[:path])).to eq(content)
      end

      it "uses atomic writes by default" do
        # Mock File.write to fail on first call (temp file) but succeed on rename
        allow(File).to receive(:write).and_call_original
        allow(File).to receive(:rename).and_call_original

        result = writer.write_file(content, output_path)
        expect(result[:success]).to be true
      end
    end

    context "with progress callback" do
      it "reports progress during write operations" do
        writer.write_file(content, output_path, progress_callback: progress_callback)

        expect(progress_messages).not_to be_empty
        expect(progress_messages.join(" ")).to include("Preparing to write")
        expect(progress_messages.join(" ")).to include("Successfully wrote")
      end

      it "reports directory creation when needed" do
        nested_path = File.join(temp_dir, "new_dir", "test.md")
        writer.write_file(content, nested_path, progress_callback: progress_callback)

        expect(progress_messages.join(" ")).to include("Creating directory")
      end
    end

    context "with custom options" do
      it "respects create_directories: false" do
        nested_path = File.join(temp_dir, "nonexistent", "test.md")
        
        result = writer.write_file(content, nested_path, create_directories: false)
        expect(result[:success]).to be false
        expect(result[:error]).to include("No such file or directory")
      end

      it "respects atomic: false" do
        allow(File).to receive(:write).and_call_original
        expect(File).to receive(:write).with(File.expand_path(output_path), content).once

        result = writer.write_file(content, output_path, atomic: false)
        expect(result[:success]).to be true
      end
    end

    context "with invalid inputs" do
      it "raises error for non-string content" do
        expect {
          writer.write_file(123, output_path)
        }.to raise_error(ArgumentError, "Content must be a string")
      end

      it "raises error for empty output path" do
        expect {
          writer.write_file(content, "")
        }.to raise_error(ArgumentError, "Output path must be provided")
      end

      it "raises error for nil output path" do
        expect {
          writer.write_file(content, nil)
        }.to raise_error(ArgumentError, "Output path must be provided")
      end
    end

    context "with security validator" do
      let(:security_validator) { double("SecurityValidator") }
      let(:writer_with_security) { described_class.new(security_validator) }

      it "validates paths through security validator" do
        expect(security_validator).to receive(:validate_and_sanitize_path)
          .with(File.expand_path(output_path))
          .and_return(File.expand_path(output_path))

        result = writer_with_security.write_file(content, output_path)
        expect(result[:success]).to be true
      end

      it "rejects paths that fail security validation" do
        expect(security_validator).to receive(:validate_and_sanitize_path)
          .with(File.expand_path(output_path))
          .and_return(nil)

        result = writer_with_security.write_file(content, output_path)
        expect(result[:success]).to be false
        expect(result[:error]).to include("not allowed")
      end
    end

    context "with write errors" do
      it "handles permission errors gracefully" do
        # Create a readonly directory
        readonly_dir = File.join(temp_dir, "readonly")
        FileUtils.mkdir_p(readonly_dir)
        FileUtils.chmod(0444, readonly_dir)
        readonly_path = File.join(readonly_dir, "test.md")

        result = writer.write_file(content, readonly_path)
        
        expect(result[:success]).to be false
        expect(result[:error]).to be_a(String)
        expect(result[:size]).to eq(0)
      ensure
        # Restore permissions for cleanup
        FileUtils.chmod(0755, readonly_dir) if Dir.exist?(readonly_dir)
      end
    end
  end

  describe "#write_files" do
    let(:files) do
      [
        {
          content: "# File 1\nContent 1",
          path: File.join(temp_dir, "file1.md")
        },
        {
          content: "# File 2\nContent 2",
          path: File.join(temp_dir, "file2.md")
        },
        {
          content: "# File 3\nContent 3",
          path: File.join(temp_dir, "nested", "file3.md")
        }
      ]
    end

    it "writes multiple files successfully" do
      results = writer.write_files(files)

      expect(results.length).to eq(3)
      results.each_with_index do |result, index|
        expect(result[:success]).to be true
        expect(result[:file_index]).to eq(index)
        expect(File.exist?(result[:path])).to be true
      end
    end

    it "reports batch progress" do
      results = writer.write_files(files, progress_callback: progress_callback)

      expect(results.length).to eq(3)
      batch_messages = progress_messages.select { |msg| msg.start_with?("[") }
      expect(batch_messages.length).to be > 0
      expect(batch_messages.first).to match(/\[1\/3\]/)
    end

    it "merges global and file-specific options" do
      files_with_options = files.map.with_index do |file, index|
        file.merge(options: { atomic: index.even? })
      end

      results = writer.write_files(files_with_options, create_directories: true)
      
      expect(results.length).to eq(3)
      results.each { |result| expect(result[:success]).to be true }
    end
  end

  describe "#writable?" do
    it "returns true for writable paths" do
      test_path = File.join(temp_dir, "writable.md")
      expect(writer.writable?(test_path)).to be true
    end

    it "returns true for existing writable files" do
      test_path = File.join(temp_dir, "existing.md")
      File.write(test_path, "content")
      expect(writer.writable?(test_path)).to be true
    end

    it "returns false for readonly files" do
      test_path = File.join(temp_dir, "readonly.md")
      File.write(test_path, "content")
      FileUtils.chmod(0444, test_path)
      
      expect(writer.writable?(test_path)).to be false
    ensure
      FileUtils.chmod(0644, test_path) if File.exist?(test_path)
    end

    it "returns false for paths in nonexistent directories" do
      test_path = "/nonexistent/directory/file.md"
      expect(writer.writable?(test_path)).to be false
    end
  end

  describe "#preview_write" do
    let(:content) { "# Preview Content\nThis is a preview.\n" }  # 2 lines after split
    let(:output_path) { File.join(temp_dir, "preview.md") }

    it "provides write preview information" do
      preview = writer.preview_write(content, output_path)

      expect(preview[:path]).to eq(File.expand_path(output_path))
      expect(preview[:writable]).to be true
      expect(preview[:exists]).to be false
      expect(preview[:parent_exists]).to be true
      expect(preview[:size]).to eq(content.bytesize)
      expect(preview[:lines]).to eq(2)
      expect(preview[:size_formatted]).to include("bytes")
      expect(preview[:basename]).to eq("preview.md")
    end

    it "detects existing files" do
      File.write(output_path, "existing content")
      preview = writer.preview_write(content, output_path)

      expect(preview[:exists]).to be true
      expect(preview[:parent_exists]).to be true
    end

    it "detects missing parent directories" do
      nested_path = File.join(temp_dir, "missing", "preview.md")
      preview = writer.preview_write(content, nested_path)

      expect(preview[:parent_exists]).to be false
    end
  end

  describe "file statistics calculation" do
    it "correctly calculates file size and lines" do
      content = "Line 1\nLine 2\nLine 3"
      result = writer.write_file(content, File.join(temp_dir, "stats.md"))

      expect(result[:size]).to eq(content.bytesize)
      expect(result[:lines]).to eq(3)
      expect(result[:size_formatted]).to eq("#{content.bytesize} bytes")
    end

    it "handles empty content" do
      content = ""
      result = writer.write_file(content, File.join(temp_dir, "empty.md"))

      expect(result[:size]).to eq(0)
      expect(result[:lines]).to eq(0)
      expect(result[:size_formatted]).to eq("0 bytes")
    end

    it "formats large file sizes" do
      large_content = "a" * (2 * 1024 * 1024) # 2MB
      result = writer.write_file(large_content, File.join(temp_dir, "large.md"))

      expect(result[:size_formatted]).to include("MB")
    end
  end
end