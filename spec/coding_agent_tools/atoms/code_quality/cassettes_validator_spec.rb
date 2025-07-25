# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::CassettesValidator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:cassettes_dir) { File.join(temp_dir, "spec", "cassettes") }
  
  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "uses default threshold" do
      validator = described_class.new
      expect(validator.threshold).to eq(50 * 1024)
    end

    it "uses custom threshold" do
      validator = described_class.new(threshold: 100 * 1024)
      expect(validator.threshold).to eq(100 * 1024)
    end

    it "uses default cassettes directory" do
      validator = described_class.new
      expect(validator.cassettes_dir.to_s).to eq("spec/cassettes")
    end

    it "uses custom cassettes directory" do
      validator = described_class.new(cassettes_dir: "custom/cassettes")
      expect(validator.cassettes_dir.to_s).to eq("custom/cassettes")
    end
  end

  describe "#validate" do
    context "when cassettes directory does not exist" do
      it "returns success with no findings" do
        validator = described_class.new(cassettes_dir: "/nonexistent/path")
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
        expect(result[:message]).to include("No cassettes directory found")
      end
    end

    context "when cassettes directory exists but is empty" do
      before do
        FileUtils.mkdir_p(cassettes_dir)
      end

      it "returns success with no findings" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with cassette files below threshold" do
      before do
        FileUtils.mkdir_p(cassettes_dir)
        create_cassette_file("small.yml", "small content")
        create_cassette_file("tiny.json", "tiny")
      end

      it "returns success with no findings" do
        validator = described_class.new(cassettes_dir: cassettes_dir, threshold: 1024)
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with cassette files above threshold" do
      let(:large_content) { "x" * 60_000 }
      let(:medium_content) { "y" * 55_000 }

      before do
        FileUtils.mkdir_p(cassettes_dir)
        create_cassette_file("large.yml", large_content)
        create_cassette_file("medium.json", medium_content)
        create_cassette_file("small.yml", "small")
      end

      it "identifies large cassettes" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:findings].size).to eq(2)
        expect(result[:warnings].size).to eq(2)
      end

      it "sorts findings by size (largest first)" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        sizes = result[:findings].map { |f| f[:size] }
        expect(sizes).to eq(sizes.sort.reverse)
        expect(result[:findings].first[:size]).to eq(60_000)
        expect(result[:findings][1][:size]).to eq(55_000)
      end

      it "includes file paths, sizes, and formatted sizes" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        finding = result[:findings].first
        expect(finding[:path]).to end_with("large.yml")
        expect(finding[:size]).to eq(60_000)
        expect(finding[:size_formatted]).to eq("58.6KB")
      end

      it "generates appropriate warnings" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        expect(result[:warnings].first).to include("large.yml is 58.6KB (threshold: 50.0KB)")
        expect(result[:warnings][1]).to include("medium.json is 53.7KB (threshold: 50.0KB)")
      end
    end

    context "with nested cassette directories" do
      before do
        FileUtils.mkdir_p(File.join(cassettes_dir, "subdir"))
        create_cassette_file("subdir/nested.yml", "x" * 60_000)
        create_cassette_file("root.json", "y" * 55_000)
      end

      it "finds cassettes in subdirectories" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        expect(result[:findings].size).to eq(2)
        paths = result[:findings].map { |f| f[:path] }
        expect(paths.any? { |p| p.include?("subdir/nested.yml") }).to be true
        expect(paths.any? { |p| p.include?("root.json") }).to be true
      end
    end

    context "with different file extensions" do
      before do
        FileUtils.mkdir_p(cassettes_dir)
        create_cassette_file("test.yml", "x" * 60_000)
        create_cassette_file("test.json", "y" * 55_000)
        create_cassette_file("test.yaml", "z" * 52_000)  # Should be ignored (not .yml)
        create_cassette_file("test.txt", "a" * 70_000)  # Should be ignored
      end

      it "only processes .yml and .json files" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        expect(result[:findings].size).to eq(2)  # Only .yml and .json, not .yaml
        paths = result[:findings].map { |f| f[:path] }
        expect(paths.none? { |p| p.include?("test.txt") }).to be true
        expect(paths.none? { |p| p.include?("test.yaml") }).to be true
      end
    end

    context "with custom threshold" do
      before do
        FileUtils.mkdir_p(cassettes_dir)
        create_cassette_file("medium.yml", "x" * 30_000)
      end

      it "respects custom threshold" do
        validator = described_class.new(cassettes_dir: cassettes_dir, threshold: 25_000)
        result = validator.validate

        expect(result[:findings].size).to eq(1)
        expect(result[:warnings].first).to include("threshold: 24.4KB")
      end

      it "excludes files below custom threshold" do
        validator = described_class.new(cassettes_dir: cassettes_dir, threshold: 35_000)
        result = validator.validate

        expect(result[:findings]).to be_empty
      end
    end

    context "with path resolution" do
      before do
        FileUtils.mkdir_p(cassettes_dir)
        create_cassette_file("test.yml", "x" * 60_000)
        allow(Pathname).to receive(:pwd).and_return(Pathname.new(temp_dir))
      end

      it "creates relative paths from current directory" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        finding = result[:findings].first
        expect(finding[:path]).to start_with("spec/cassettes")
        expect(finding[:path]).not_to start_with("/")
      end
    end

    context "with path resolution errors" do
      before do
        FileUtils.mkdir_p(cassettes_dir)
        create_cassette_file("test.yml", "x" * 60_000)
        allow(Pathname).to receive(:new).and_call_original
        allow_any_instance_of(Pathname).to receive(:relative_path_from).and_raise(ArgumentError)
      end

      it "falls back to absolute path on error" do
        validator = described_class.new(cassettes_dir: cassettes_dir)
        result = validator.validate

        finding = result[:findings].first
        expect(finding[:path]).to be_a(String)
      end
    end
  end

  describe "size formatting" do
    let(:validator) { described_class.new }

    it "formats bytes correctly" do
      expect(validator.send(:format_size, 500)).to eq("500B")
      expect(validator.send(:format_size, 0)).to eq("0B")
      expect(validator.send(:format_size, 1023)).to eq("1023B")
    end

    it "formats kilobytes correctly" do
      expect(validator.send(:format_size, 1024)).to eq("1.0KB")
      expect(validator.send(:format_size, 1536)).to eq("1.5KB")
      expect(validator.send(:format_size, 51200)).to eq("50.0KB")
    end

    it "formats megabytes correctly" do
      expect(validator.send(:format_size, 1_048_576)).to eq("1.0MB")
      expect(validator.send(:format_size, 2_097_152)).to eq("2.0MB")
      expect(validator.send(:format_size, 1_572_864)).to eq("1.5MB")
    end
  end

  describe "warning formatting" do
    let(:validator) { described_class.new(threshold: 50 * 1024) }
    let(:cassette) do
      {
        path: "spec/cassettes/large.yml",
        size: 60_000,
        size_formatted: "58.6KB"
      }
    end

    it "formats warnings correctly" do
      warning = validator.send(:format_warning, cassette)
      expect(warning).to eq("spec/cassettes/large.yml is 58.6KB (threshold: 50.0KB)")
    end
  end

  private

  def create_cassette_file(relative_path, content)
    full_path = File.join(cassettes_dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end