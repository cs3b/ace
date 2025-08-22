# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"
require_relative "../../../../lib/coding_agent_tools/molecules/context/context_chunker"

RSpec.describe CodingAgentTools::Molecules::Context::ContextChunker do
  let(:chunk_limit) { 5 } # Small limit for testing
  let(:chunker) { described_class.new(chunk_limit) }
  let(:temp_dir) { Dir.mktmpdir }
  let(:base_path) { File.join(temp_dir, "test_context") }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "uses default chunk limit when not specified" do
      default_chunker = described_class.new
      expect(default_chunker.instance_variable_get(:@chunk_limit)).to eq(150_000)
    end

    it "uses custom chunk limit when specified" do
      expect(chunker.instance_variable_get(:@chunk_limit)).to eq(chunk_limit)
    end
  end

  describe "#needs_chunking?" do
    it "returns false for content within limit" do
      small_content = "Line 1\nLine 2\nLine 3"
      expect(chunker.needs_chunking?(small_content)).to be false
    end

    it "returns true for content exceeding limit" do
      large_content = (1..10).map { |i| "Line #{i}" }.join("\n")
      expect(chunker.needs_chunking?(large_content)).to be true
    end

    it "returns false for empty content" do
      expect(chunker.needs_chunking?("")).to be false
      expect(chunker.needs_chunking?(nil)).to be false
    end

    it "handles content exactly at limit" do
      exact_content = (1..chunk_limit).map { |i| "Line #{i}" }.join("\n")
      expect(chunker.needs_chunking?(exact_content)).to be false
    end

    it "handles content just over limit" do
      over_content = (1..(chunk_limit + 1)).map { |i| "Line #{i}" }.join("\n")
      expect(chunker.needs_chunking?(over_content)).to be true
    end
  end

  describe "#chunk_content" do
    context "with small content" do
      let(:small_content) { "Line 1\nLine 2\nLine 3" }

      it "returns single file result" do
        result = chunker.chunk_content(small_content, base_path)

        expect(result[:chunked]).to be false
        expect(result[:total_chunks]).to eq(1)
        expect(result[:total_lines]).to eq(3)
        expect(result[:single_file]).to eq("#{base_path}.md")
        expect(result[:single_content]).to eq(small_content)
      end
    end

    context "with large content" do
      let(:large_content) { (1..12).map { |i| "Line #{i}" }.join("\n") }

      it "chunks content correctly" do
        result = chunker.chunk_content(large_content, base_path)

        expect(result[:chunked]).to be true
        expect(result[:total_chunks]).to eq(3) # 5 + 5 + 2 lines
        expect(result[:total_lines]).to eq(12)
        expect(result[:chunk_limit]).to eq(chunk_limit)
        expect(result[:index_file]).to eq("#{base_path}.md")
        expect(result[:chunk_files]).to be_an(Array)
        expect(result[:chunk_files].length).to eq(3)
      end

      it "creates correct chunk file paths" do
        result = chunker.chunk_content(large_content, base_path)

        chunk_paths = result[:chunk_files].map { |chunk| chunk[:path] }
        expect(chunk_paths).to eq([
          "#{base_path}_chunk1.md",
          "#{base_path}_chunk2.md",
          "#{base_path}_chunk3.md"
        ])
      end

      it "distributes lines correctly across chunks" do
        result = chunker.chunk_content(large_content, base_path)

        line_counts = result[:chunk_files].map { |chunk| chunk[:lines] }
        expect(line_counts).to eq([5, 5, 2])
      end

      it "generates index content" do
        result = chunker.chunk_content(large_content, base_path)

        expect(result[:index_content]).to include("Context Index")
        expect(result[:index_content]).to include("Total chunks**: 3")
        expect(result[:index_content]).to include("Total lines**: 12")
        expect(result[:index_content]).to include("_chunk1.md")
        expect(result[:index_content]).to include("_chunk2.md")
        expect(result[:index_content]).to include("_chunk3.md")
      end

      it "includes metadata in chunks by default" do
        result = chunker.chunk_content(large_content, base_path)

        first_chunk = result[:chunk_files].first
        expect(first_chunk[:content]).to include("<!-- Chunk 1 of 3 -->")
        expect(first_chunk[:content]).to include("<!-- Lines: 5 -->")
      end

      it "respects custom chunk suffix" do
        result = chunker.chunk_content(large_content, base_path, chunk_suffix: "_part")

        chunk_paths = result[:chunk_files].map { |chunk| chunk[:path] }
        expect(chunk_paths.first).to include("_part1.md")
      end

      it "can exclude metadata when requested" do
        result = chunker.chunk_content(large_content, base_path, include_metadata: false)

        first_chunk = result[:chunk_files].first
        expect(first_chunk[:content]).not_to include("<!-- Chunk")
        expect(first_chunk[:content]).to start_with("Line 1")
      end
    end
  end

  describe "#generate_chunk_paths" do
    it "generates correct paths for multiple chunks" do
      paths = chunker.generate_chunk_paths(base_path, 3)

      expect(paths).to eq([
        "#{base_path}_chunk1.md",
        "#{base_path}_chunk2.md",
        "#{base_path}_chunk3.md"
      ])
    end

    it "uses custom suffix when provided" do
      paths = chunker.generate_chunk_paths(base_path, 2, "_section")

      expect(paths).to eq([
        "#{base_path}_section1.md",
        "#{base_path}_section2.md"
      ])
    end
  end

  describe "#analyze_chunking_strategy" do
    context "with small content" do
      let(:small_content) { "Line 1\nLine 2\nLine 3" }

      it "indicates no chunking needed" do
        analysis = chunker.analyze_chunking_strategy(small_content)
        expect(analysis[:chunking_needed]).to be false
      end
    end

    context "with large content" do
      let(:large_content) { (1..12).map { |i| "Line #{i}" }.join("\n") }

      it "provides detailed chunking analysis" do
        analysis = chunker.analyze_chunking_strategy(large_content)

        expect(analysis[:chunking_needed]).to be true
        expect(analysis[:total_lines]).to eq(12)
        expect(analysis[:chunk_limit]).to eq(chunk_limit)
        expect(analysis[:chunks_needed]).to eq(3)
        expect(analysis[:avg_chunk_size]).to eq(4) # 12 / 3
        expect(analysis[:last_chunk_size]).to eq(2) # 12 - (2 * 5)
        expect(analysis[:estimated_files]).to eq(4) # 3 chunks + 1 index
      end
    end
  end

  describe "#chunk_and_write" do
    let(:mock_file_writer) { double("FileWriter") }

    context "with small content that doesn't need chunking" do
      let(:small_content) { "Line 1\nLine 2\nLine 3" }

      it "writes single file" do
        expect(mock_file_writer).to receive(:write_file)
          .with(small_content, "#{base_path}.md", {})
          .and_return({success: true, path: "#{base_path}.md"})

        result = chunker.chunk_and_write(small_content, base_path, mock_file_writer)

        expect(result[:chunked]).to be false
        expect(result[:files_written]).to eq(1)
        expect(result[:results].length).to eq(1)
      end
    end

    context "with large content that needs chunking" do
      let(:large_content) { (1..12).map { |i| "Line #{i}" }.join("\n") }

      it "writes index file and all chunks" do
        # Expect calls for index file + 3 chunk files
        expect(mock_file_writer).to receive(:write_file).exactly(4).times.and_return(
          {success: true, path: "some_path.md"}
        )

        result = chunker.chunk_and_write(large_content, base_path, mock_file_writer)

        expect(result[:chunked]).to be true
        expect(result[:files_written]).to eq(4) # 1 index + 3 chunks
        expect(result[:total_chunks]).to eq(3)
        expect(result[:results].length).to eq(4)
      end

      it "marks file types correctly" do
        allow(mock_file_writer).to receive(:write_file).and_return(
          {success: true, path: "some_path.md"}
        )

        result = chunker.chunk_and_write(large_content, base_path, mock_file_writer)

        file_types = result[:results].map { |r| r[:file_type] }
        expect(file_types).to eq(["index", "chunk", "chunk", "chunk"])
      end

      it "includes chunk numbers for chunk files" do
        allow(mock_file_writer).to receive(:write_file).and_return(
          {success: true, path: "some_path.md"}
        )

        result = chunker.chunk_and_write(large_content, base_path, mock_file_writer)

        chunk_results = result[:results].select { |r| r[:file_type] == "chunk" }
        chunk_numbers = chunk_results.map { |r| r[:chunk_number] }
        expect(chunk_numbers).to eq([1, 2, 3])
      end
    end
  end

  describe "content integrity" do
    let(:test_content) do
      lines = []
      lines << "# Test Document"
      lines << ""
      lines << "## Section 1"
      (1..8).each { |i| lines << "Content line #{i}" }
      lines << ""
      lines << "## Section 2"
      lines << "Final content"
      lines.join("\n")
    end

    it "preserves all content across chunks" do
      result = chunker.chunk_content(test_content, base_path)

      # Reconstruct content from chunks
      reconstructed_lines = []
      result[:chunk_files].each do |chunk|
        chunk_lines = chunk[:content].split("\n")

        # Skip metadata lines if present
        chunk_lines = chunk_lines.drop_while { |line| line.start_with?("<!--") || line.empty? }

        reconstructed_lines.concat(chunk_lines)
      end

      original_lines = test_content.split("\n")
      expect(reconstructed_lines).to eq(original_lines)
    end

    it "maintains line count across all chunks" do
      result = chunker.chunk_content(test_content, base_path)

      total_content_lines = result[:chunk_files].sum do |chunk|
        # Count only non-metadata lines
        content_lines = chunk[:content].split("\n")
        # Skip metadata comments at start, but count empty lines that are part of content
        in_metadata = true
        content_lines.count do |line|
          if in_metadata && (line.start_with?("<!--") || line.empty?)
            false  # Skip metadata and leading empty lines
          else
            in_metadata = false
            true   # Count all content lines
          end
        end
      end

      original_line_count = test_content.split("\n").length
      expect(total_content_lines).to eq(original_line_count)
    end
  end

  describe "edge cases" do
    it "handles content with exactly chunk_limit lines" do
      exact_content = (1..chunk_limit).map { |i| "Line #{i}" }.join("\n")
      result = chunker.chunk_content(exact_content, base_path)

      expect(result[:chunked]).to be false
      expect(result[:total_chunks]).to eq(1)
    end

    it "handles content with one line over limit" do
      over_content = (1..(chunk_limit + 1)).map { |i| "Line #{i}" }.join("\n")
      result = chunker.chunk_content(over_content, base_path)

      expect(result[:chunked]).to be true
      expect(result[:total_chunks]).to eq(2)
      expect(result[:chunk_files][0][:lines]).to eq(chunk_limit)
      expect(result[:chunk_files][1][:lines]).to eq(1)
    end

    it "handles empty lines in content" do
      content_with_empty = ["Line 1", "", "Line 3", "", "", "Line 6"].join("\n")
      result = chunker.chunk_content(content_with_empty, base_path)

      expect(result[:total_lines]).to eq(6)
    end
  end
end
