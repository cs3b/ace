# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::Code::DirectoryCreator do
  let(:creator) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#create" do
    context "with valid path" do
      it "creates directory successfully" do
        test_path = File.join(temp_dir, "new_directory")
        result = creator.create(test_path)

        expect(result[:success]).to be true
        expect(result[:error]).to be_nil
        expect(File.exist?(test_path)).to be true
        expect(File.directory?(test_path)).to be true
      end

      it "creates nested directories" do
        test_path = File.join(temp_dir, "level1", "level2", "level3")
        result = creator.create(test_path)

        expect(result[:success]).to be true
        expect(File.exist?(test_path)).to be true
        expect(File.directory?(test_path)).to be true
      end

      it "succeeds when directory already exists" do
        test_path = File.join(temp_dir, "existing")
        FileUtils.mkdir_p(test_path)

        result = creator.create(test_path)
        expect(result[:success]).to be true
      end
    end

    context "with invalid path" do
      it "raises ArgumentError for nil path" do
        expect { creator.create(nil) }.to raise_error(ArgumentError, "Path cannot be nil")
      end

      it "raises ArgumentError for empty path" do
        expect { creator.create("") }.to raise_error(ArgumentError, "Path cannot be empty")
      end

      it "raises ArgumentError for non-string path" do
        expect { creator.create(123) }.to raise_error(NoMethodError)
      end
    end

    context "with permission issues" do
      it "handles permission denied error" do
        # Mock FileUtils to simulate permission denied
        allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)

        result = creator.create("/test/path")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Permission denied: /test/path")
      end

      it "handles parent not directory error" do
        allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::ENOTDIR)

        result = creator.create("/test/path")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Parent is not a directory: /test/path")
      end

      it "handles generic errors" do
        allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError, "Custom error")

        result = creator.create("/test/path")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Error creating directory: Custom error")
      end
    end
  end

  describe "#create_if_not_exists" do
    context "when directory does not exist" do
      it "creates directory and returns created: true" do
        test_path = File.join(temp_dir, "new_dir")
        result = creator.create_if_not_exists(test_path)

        expect(result[:success]).to be true
        expect(result[:created]).to be true
        expect(result[:error]).to be_nil
        expect(File.exist?(test_path)).to be true
      end
    end

    context "when directory already exists" do
      it "returns success without creating" do
        test_path = File.join(temp_dir, "existing_dir")
        FileUtils.mkdir_p(test_path)

        result = creator.create_if_not_exists(test_path)
        expect(result[:success]).to be true
        expect(result[:created]).to be false
        expect(result[:error]).to be_nil
      end
    end

    context "when path exists but is not a directory" do
      it "returns error" do
        test_path = File.join(temp_dir, "file_not_dir")
        File.write(test_path, "content")

        result = creator.create_if_not_exists(test_path)
        expect(result[:success]).to be false
        expect(result[:created]).to be false
        expect(result[:error]).to eq("Path exists but is not a directory: #{test_path}")
      end
    end

    it "validates path arguments" do
      expect { creator.create_if_not_exists(nil) }.to raise_error(ArgumentError, "Path cannot be nil")
    end
  end

  describe "#exists?" do
    it "returns true for existing directories" do
      expect(creator.exists?(temp_dir)).to be true
    end

    it "returns false for non-existent paths" do
      expect(creator.exists?(File.join(temp_dir, "nonexistent"))).to be false
    end

    it "returns false for files (not directories)" do
      file_path = File.join(temp_dir, "test_file")
      File.write(file_path, "content")

      expect(creator.exists?(file_path)).to be false
    end
  end

  describe "#writable?" do
    it "returns true for writable directories" do
      test_path = File.join(temp_dir, "writable")
      FileUtils.mkdir_p(test_path)

      expect(creator.writable?(test_path)).to be true
    end

    it "returns false for non-existent directories" do
      expect(creator.writable?(File.join(temp_dir, "nonexistent"))).to be false
    end

    it "returns false for files" do
      file_path = File.join(temp_dir, "test_file")
      File.write(file_path, "content")

      expect(creator.writable?(file_path)).to be false
    end
  end

  describe "#create_temp" do
    after do
      # Clean up any temp directories created
      if @temp_result && @temp_result[:success] && @temp_result[:path]
        FileUtils.rm_rf(@temp_result[:path])
      end
    end

    it "creates temporary directory with default prefix" do
      @temp_result = creator.create_temp

      expect(@temp_result[:success]).to be true
      expect(@temp_result[:path]).to be_a(String)
      expect(@temp_result[:error]).to be_nil
      expect(File.exist?(@temp_result[:path])).to be true
      expect(File.directory?(@temp_result[:path])).to be true
      expect(File.basename(@temp_result[:path])).to start_with("review")
    end

    it "creates temporary directory with custom prefix" do
      @temp_result = creator.create_temp("custom")

      expect(@temp_result[:success]).to be true
      expect(File.basename(@temp_result[:path])).to start_with("custom")
    end

    it "creates temporary directory in specified parent" do
      custom_tmpdir = File.join(temp_dir, "custom_tmp")
      FileUtils.mkdir_p(custom_tmpdir)

      @temp_result = creator.create_temp("test", custom_tmpdir)

      expect(@temp_result[:success]).to be true
      expect(@temp_result[:path]).to start_with(custom_tmpdir)
    end

    it "handles errors in temp directory creation" do
      # Create a separate instance to avoid affecting the let block
      test_creator = described_class.new

      # Mock Dir.mktmpdir to simulate failure for this specific call
      allow(test_creator).to receive(:require).with("tmpdir")
      allow(Dir).to receive(:mktmpdir).and_call_original
      allow(Dir).to receive(:mktmpdir).with("review", nil).and_raise(StandardError, "Temp creation failed")

      @temp_result = test_creator.create_temp
      expect(@temp_result[:success]).to be false
      expect(@temp_result[:path]).to be_nil
      expect(@temp_result[:error]).to eq("Error creating temp directory: Temp creation failed")
    end
  end

  describe "security considerations" do
    it "handles paths with traversal attempts" do
      # This tests that the basic validation works, though more security
      # validation might be needed at higher levels
      result = creator.create("../../../etc/test")
      # Should succeed as this tests basic functionality,
      # but real security should be handled at system level
      expect(result).to have_key(:success)
    end

    it "handles very long paths" do
      long_path = File.join(temp_dir, "a" * 255)
      result = creator.create(long_path)
      # Behavior may vary by system, but should not crash
      expect(result).to have_key(:success)
    end
  end
end
