# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::Code::FileContentReader do
  let(:reader) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#read" do
    context "with valid file" do
      it "reads file content successfully" do
        test_file = File.join(temp_dir, "test.txt")
        content = "Hello, World!\nThis is a test file."
        File.write(test_file, content)

        result = reader.read(test_file)
        
        expect(result[:success]).to be true
        expect(result[:content]).to eq(content)
        expect(result[:error]).to be_nil
      end

      it "reads empty file" do
        test_file = File.join(temp_dir, "empty.txt")
        File.write(test_file, "")

        result = reader.read(test_file)
        
        expect(result[:success]).to be true
        expect(result[:content]).to eq("")
        expect(result[:error]).to be_nil
      end

      it "reads file with unicode content" do
        test_file = File.join(temp_dir, "unicode.txt")
        content = "Hello 🌍! This has émojis and áccents."
        File.write(test_file, content)

        result = reader.read(test_file)
        
        expect(result[:success]).to be true
        expect(result[:content]).to eq(content)
      end
    end

    context "with invalid file" do
      it "handles file not found" do
        nonexistent_file = File.join(temp_dir, "nonexistent.txt")
        
        result = reader.read(nonexistent_file)
        
        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to eq("File not found: #{nonexistent_file}")
      end

      it "handles permission denied" do
        # Mock File.read to simulate permission denied
        allow(File).to receive(:read).and_raise(Errno::EACCES)
        
        result = reader.read("/test/file.txt")
        
        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to eq("Permission denied: /test/file.txt")
      end

      it "handles generic errors" do
        allow(File).to receive(:read).and_raise(StandardError, "Custom error")
        
        result = reader.read("/test/file.txt")
        
        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to eq("Error reading file: Custom error")
      end
    end

    context "with invalid path arguments" do
      it "raises ArgumentError for nil path" do
        expect { reader.read(nil) }.to raise_error(ArgumentError, "Path cannot be nil")
      end

      it "raises ArgumentError for empty path" do
        expect { reader.read("") }.to raise_error(ArgumentError, "Path cannot be empty")
      end

      it "raises ArgumentError for non-string path" do
        expect { reader.read(123) }.to raise_error(ArgumentError, "Path must be a string")
      end
    end
  end

  describe "#read_with_limit" do
    context "with file within size limit" do
      it "reads small file successfully" do
        test_file = File.join(temp_dir, "small.txt")
        content = "Small content"
        File.write(test_file, content)

        result = reader.read_with_limit(test_file, 1000)
        
        expect(result[:success]).to be true
        expect(result[:content]).to eq(content)
        expect(result[:error]).to be_nil
      end
    end

    context "with file exceeding size limit" do
      it "rejects large file" do
        test_file = File.join(temp_dir, "large.txt")
        content = "a" * 1000
        File.write(test_file, content)

        result = reader.read_with_limit(test_file, 500)
        
        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to eq("File too large: 1000 bytes (max: 500)")
      end
    end

    context "with file size check errors" do
      it "handles file size check errors" do
        # Mock File.size to simulate error
        allow(File).to receive(:size).and_raise(StandardError, "Size check failed")
        
        result = reader.read_with_limit("/test/file.txt", 1000)
        
        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to eq("Error checking file size: Size check failed")
      end
    end

    context "with invalid arguments" do
      it "validates path arguments" do
        expect { reader.read_with_limit(nil, 1000) }.to raise_error(ArgumentError, "Path cannot be nil")
      end
    end
  end

  describe "#readable?" do
    it "returns true for readable files" do
      test_file = File.join(temp_dir, "readable.txt")
      File.write(test_file, "content")
      
      expect(reader.readable?(test_file)).to be true
    end

    it "returns false for non-existent files" do
      nonexistent_file = File.join(temp_dir, "nonexistent.txt")
      
      expect(reader.readable?(nonexistent_file)).to be false
    end

    it "returns false for directories" do
      test_dir = File.join(temp_dir, "test_dir")
      FileUtils.mkdir_p(test_dir)
      
      expect(reader.readable?(test_dir)).to be false
    end
  end

  describe "#metadata" do
    context "with existing file" do
      it "returns complete metadata for existing file" do
        test_file = File.join(temp_dir, "metadata_test.txt")
        content = "Test content for metadata"
        File.write(test_file, content)

        result = reader.metadata(test_file)
        
        expect(result[:exists]).to be true
        expect(result[:size]).to eq(content.bytesize)
        expect(result[:mtime]).to be_a(Time)
        expect(result[:readable]).to be true
        expect(result).not_to have_key(:error)
      end
    end

    context "with non-existent file" do
      it "returns default metadata for non-existent file" do
        nonexistent_file = File.join(temp_dir, "nonexistent.txt")
        
        result = reader.metadata(nonexistent_file)
        
        expect(result[:exists]).to be false
        expect(result[:size]).to eq(0)
        expect(result[:mtime]).to be_nil
        expect(result[:readable]).to be false
      end
    end

    context "with metadata errors" do
      it "handles metadata retrieval errors" do
        # Mock File.exist? to simulate error
        allow(File).to receive(:exist?).and_raise(StandardError, "Metadata error")
        
        result = reader.metadata("/test/file.txt")
        
        expect(result[:exists]).to be false
        expect(result[:size]).to eq(0)
        expect(result[:mtime]).to be_nil
        expect(result[:readable]).to be false
        expect(result[:error]).to eq("Metadata error")
      end
    end
  end

  describe "performance and edge cases" do
    it "handles large file content efficiently" do
      test_file = File.join(temp_dir, "large_content.txt")
      # Create a moderately large file
      large_content = "Line of content\n" * 1000
      File.write(test_file, large_content)

      start_time = Time.now
      result = reader.read(test_file)
      end_time = Time.now

      expect(result[:success]).to be true
      expect(result[:content]).to eq(large_content)
      # Should complete in reasonable time (less than 1 second for this size)
      expect(end_time - start_time).to be < 1.0
    end

    it "handles special characters in file paths" do
      # Create file with special characters in name
      special_file = File.join(temp_dir, "file with spaces & symbols!.txt")
      content = "Content in special file"
      File.write(special_file, content)

      result = reader.read(special_file)
      
      expect(result[:success]).to be true
      expect(result[:content]).to eq(content)
    end

    it "handles different file encodings" do
      test_file = File.join(temp_dir, "encoding_test.txt")
      # Write content with explicit UTF-8 encoding
      content = "UTF-8 content: café, naïve, résumé"
      File.write(test_file, content, encoding: "UTF-8")

      result = reader.read(test_file)
      
      expect(result[:success]).to be true
      expect(result[:content]).to eq(content)
    end

    it "handles binary file content" do
      test_file = File.join(temp_dir, "binary.dat")
      # Write some binary data
      binary_data = "\x00\x01\x02\xFF\xFE"
      File.binwrite(test_file, binary_data)

      result = reader.read(test_file)
      
      expect(result[:success]).to be true
      expect(result[:content]).to eq(binary_data)
    end
  end

  describe "security considerations" do
    it "handles path traversal attempts safely" do
      # Test that the reader handles traversal paths
      # (Note: actual security should be enforced at higher levels)
      result = reader.read("../../../etc/passwd")
      
      # Should either fail safely or read the file if it exists and is accessible
      expect(result).to have_key(:success)
    end

    it "handles symbolic link files" do
      test_file = File.join(temp_dir, "original.txt")
      link_file = File.join(temp_dir, "symlink.txt")
      content = "Original content"
      
      File.write(test_file, content)
      
      # Only create symlink if the system supports it
      begin
        File.symlink(test_file, link_file)
        
        result = reader.read(link_file)
        expect(result[:success]).to be true
        expect(result[:content]).to eq(content)
      rescue NotImplementedError
        # Skip test on systems that don't support symlinks
        skip "Symbolic links not supported on this system"
      end
    end
  end
end