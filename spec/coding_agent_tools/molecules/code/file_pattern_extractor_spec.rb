# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Molecules::Code::FilePatternExtractor do
  let(:extractor) { described_class.new }
  let(:file_reader_mock) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }
  let(:file_scanner_mock) { class_double(CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner) }

  before do
    # Mock the atoms dependencies
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(file_reader_mock)
    allow(CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner).to receive(:find_files_with_pattern).and_return(file_scanner_mock)

    # Set up the instance variable mock
    extractor.instance_variable_set(:@file_reader, file_reader_mock)
    extractor.instance_variable_set(:@file_scanner, file_scanner_mock)
  end

  describe "#extract_files" do
    context "when extracting a single file" do
      let(:file_path) { "/path/to/test.rb" }
      let(:file_content) { "puts 'Hello World'" }

      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:directory?).with(file_path).and_return(false)
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: true,
          content: file_content
        )
      end

      it "returns successful result with XML content for single file" do
        result = extractor.extract_files(file_path)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq([file_path])
        expect(result[:xml_content]).to include("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        expect(result[:xml_content]).to include("<document path='#{file_path}'>")
        expect(result[:xml_content]).to include(file_content)
        expect(result[:error]).to be_nil
      end

      it "handles file read errors" do
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: false,
          error: "Permission denied"
        )

        result = extractor.extract_files(file_path)

        expect(result[:success]).to be false
        expect(result[:file_list]).to eq([])
        expect(result[:xml_content]).to be_nil
        expect(result[:error]).to eq("Permission denied")
      end
    end

    context "when extracting files with glob pattern" do
      let(:pattern) { "*.rb" }
      let(:matching_files) { ["/path/test1.rb", "/path/test2.rb"] }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(Dir).to receive(:glob).with(pattern).and_return(matching_files)
        allow(File).to receive(:file?).and_return(true)

        matching_files.each do |file|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "# Content of #{File.basename(file)}"
          )
        end
      end

      it "returns XML with multiple documents" do
        result = extractor.extract_files(pattern)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq(matching_files)
        expect(result[:xml_content]).to include("test1.rb")
        expect(result[:xml_content]).to include("test2.rb")
      end
    end

    context "when extracting files with file scanner" do
      let(:pattern) { "ruby_files" }
      let(:matching_files) { ["/src/main.rb", "/src/helper.rb"] }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(file_scanner_mock).to receive(:find_files_with_pattern).with(".", pattern).and_return(
          files: matching_files
        )

        matching_files.each do |file|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "# Content of #{File.basename(file)}"
          )
        end
      end

      it "uses file scanner for non-glob patterns" do
        result = extractor.extract_files(pattern)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq(matching_files)
        expect(file_scanner_mock).to have_received(:find_files_with_pattern).with(".", pattern)
      end
    end

    context "when no files match pattern" do
      let(:pattern) { "*.xyz" }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(Dir).to receive(:glob).with(pattern).and_return([])
      end

      it "returns failure with appropriate error message" do
        result = extractor.extract_files(pattern)

        expect(result[:success]).to be false
        expect(result[:file_list]).to eq([])
        expect(result[:xml_content]).to be_nil
        expect(result[:error]).to eq("No files found matching pattern: #{pattern}")
      end
    end
  end

  describe "#extract_and_save" do
    let(:pattern) { "/path/to/test.rb" }
    let(:session_dir) { "/tmp/session" }
    let(:file_content) { "puts 'Hello World'" }

    before do
      allow(File).to receive(:exist?).with(pattern).and_return(true)
      allow(File).to receive(:directory?).with(pattern).and_return(false)
      allow(file_reader_mock).to receive(:read).with(pattern).and_return(
        success: true,
        content: file_content
      )
      allow(File).to receive(:write)
      allow(File).to receive(:readlines).with(pattern).and_return(["line1\n", "line2\n"])
    end

    it "saves XML and metadata files" do
      xml_file = File.join(session_dir, "input.xml")
      meta_file = File.join(session_dir, "input.meta")

      result = extractor.extract_and_save(pattern, session_dir)

      expect(result[:success]).to be true
      expect(result[:xml_file]).to eq(xml_file)
      expect(result[:meta_file]).to eq(meta_file)

      expect(File).to have_received(:write).with(xml_file, anything)
      expect(File).to have_received(:write).with(meta_file, anything)
    end

    it "includes line count for single file in metadata" do
      meta_content = "target: #{pattern}\ntype: single_file\nfiles: 1\nsize: 2 lines\n"

      extractor.extract_and_save(pattern, session_dir)

      expect(File).to have_received(:write).with(
        File.join(session_dir, "input.meta"),
        meta_content
      )
    end

    it "handles file write errors" do
      allow(File).to receive(:write).and_raise(StandardError.new("Disk full"))

      result = extractor.extract_and_save(pattern, session_dir)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Failed to save files: Disk full")
    end
  end

  describe "private methods" do
    describe "#build_xml_content" do
      let(:files) { ["/path/test1.rb", "/path/test2.rb"] }

      before do
        files.each_with_index do |file, index|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "Content #{index + 1}"
          )
        end
      end

      it "builds valid XML with CDATA sections" do
        xml_content = extractor.send(:build_xml_content, files)

        expect(xml_content).to include("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        expect(xml_content).to include("<documents>")
        expect(xml_content).to include("Content 1")
        expect(xml_content).to include("Content 2")
        expect(xml_content).to include("CDATA")
      end

      it "skips files that fail to read" do
        allow(file_reader_mock).to receive(:read).with(files.first).and_return(success: false)

        xml_content = extractor.send(:build_xml_content, files)

        expect(xml_content).to include("Content 2")
        expect(xml_content).not_to include("Content 1")
      end
    end

    describe "#find_matching_files" do
      context "with glob patterns" do
        it "uses Dir.glob for wildcard patterns" do
          allow(Dir).to receive(:glob).with("*.rb").and_return(["/test.rb"])
          allow(File).to receive(:file?).and_return(true)

          result = extractor.send(:find_matching_files, "*.rb")

          expect(result).to eq(["/test.rb"])
          expect(Dir).to have_received(:glob).with("*.rb")
        end
      end

      context "with non-glob patterns" do
        it "uses file scanner for directory traversal" do
          allow(file_scanner_mock).to receive(:find_files_with_pattern).and_return(files: ["/found.rb"])

          result = extractor.send(:find_matching_files, "ruby_files")

          expect(result).to eq(["/found.rb"])
          expect(file_scanner_mock).to have_received(:find_files_with_pattern)
        end
      end
    end
  end
end
