# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/code/review_target"

RSpec.describe CodingAgentTools::Models::Code::ReviewTarget do
  let(:git_diff_attributes) do
    {
      type: "git_diff",
      target_spec: "HEAD~1..HEAD",
      resolved_paths: nil,
      content_type: "diff",
      size_info: {lines: 42, words: 156, files: 3}
    }
  end

  let(:file_pattern_attributes) do
    {
      type: "file_pattern",
      target_spec: "src/**/*.rb",
      resolved_paths: ["src/model.rb", "src/controller.rb"],
      content_type: "xml",
      size_info: {lines: 200, words: 800, files: 2}
    }
  end

  let(:single_file_attributes) do
    {
      type: "single_file",
      target_spec: "lib/important.rb",
      resolved_paths: ["lib/important.rb"],
      content_type: "xml",
      size_info: {lines: 50, words: 200, files: 1}
    }
  end

  describe "#initialize" do
    it "creates a new review target with git_diff type" do
      target = described_class.new(git_diff_attributes)

      expect(target.type).to eq("git_diff")
      expect(target.target_spec).to eq("HEAD~1..HEAD")
      expect(target.resolved_paths).to be_nil
      expect(target.content_type).to eq("diff")
      expect(target.size_info).to eq({lines: 42, words: 156, files: 3})
    end

    it "creates a new review target with file_pattern type" do
      target = described_class.new(file_pattern_attributes)

      expect(target.type).to eq("file_pattern")
      expect(target.target_spec).to eq("src/**/*.rb")
      expect(target.resolved_paths).to eq(["src/model.rb", "src/controller.rb"])
      expect(target.content_type).to eq("xml")
      expect(target.size_info).to eq({lines: 200, words: 800, files: 2})
    end

    it "creates a new review target with single_file type" do
      target = described_class.new(single_file_attributes)

      expect(target.type).to eq("single_file")
      expect(target.target_spec).to eq("lib/important.rb")
      expect(target.resolved_paths).to eq(["lib/important.rb"])
      expect(target.content_type).to eq("xml")
      expect(target.size_info).to eq({lines: 50, words: 200, files: 1})
    end
  end

  describe "#validate!" do
    it "validates successfully with git_diff type" do
      target = described_class.new(git_diff_attributes)
      expect { target.validate! }.not_to raise_error
    end

    it "validates successfully with file_pattern type" do
      target = described_class.new(file_pattern_attributes)
      expect { target.validate! }.not_to raise_error
    end

    it "validates successfully with single_file type" do
      target = described_class.new(single_file_attributes)
      expect { target.validate! }.not_to raise_error
    end

    it "raises error when type is nil" do
      target = described_class.new(git_diff_attributes.merge(type: nil))
      expect { target.validate! }.to raise_error(ArgumentError, "type is required")
    end

    it "raises error when type is empty" do
      target = described_class.new(git_diff_attributes.merge(type: ""))
      expect { target.validate! }.to raise_error(ArgumentError, "type is required")
    end

    it "raises error when type is invalid" do
      target = described_class.new(git_diff_attributes.merge(type: "invalid_type"))
      expect { target.validate! }.to raise_error(ArgumentError, "type must be one of: git_diff, file_pattern, single_file")
    end

    it "raises error when target_spec is nil" do
      target = described_class.new(git_diff_attributes.merge(target_spec: nil))
      expect { target.validate! }.to raise_error(ArgumentError, "target_spec is required")
    end

    it "raises error when target_spec is empty" do
      target = described_class.new(git_diff_attributes.merge(target_spec: ""))
      expect { target.validate! }.to raise_error(ArgumentError, "target_spec is required")
    end

    it "raises error when content_type is nil" do
      target = described_class.new(git_diff_attributes.merge(content_type: nil))
      expect { target.validate! }.to raise_error(ArgumentError, "content_type is required")
    end

    it "raises error when content_type is empty" do
      target = described_class.new(git_diff_attributes.merge(content_type: ""))
      expect { target.validate! }.to raise_error(ArgumentError, "content_type is required")
    end

    it "raises error when content_type is invalid" do
      target = described_class.new(git_diff_attributes.merge(content_type: "invalid"))
      expect { target.validate! }.to raise_error(ArgumentError, "content_type must be one of: diff, xml")
    end
  end

  describe "#git_based?" do
    it "returns true for git_diff type" do
      target = described_class.new(git_diff_attributes)
      expect(target.git_based?).to be(true)
    end

    it "returns false for file_pattern type" do
      target = described_class.new(file_pattern_attributes)
      expect(target.git_based?).to be(false)
    end

    it "returns false for single_file type" do
      target = described_class.new(single_file_attributes)
      expect(target.git_based?).to be(false)
    end
  end

  describe "#file_based?" do
    it "returns false for git_diff type" do
      target = described_class.new(git_diff_attributes)
      expect(target.file_based?).to be(false)
    end

    it "returns true for file_pattern type" do
      target = described_class.new(file_pattern_attributes)
      expect(target.file_based?).to be(true)
    end

    it "returns true for single_file type" do
      target = described_class.new(single_file_attributes)
      expect(target.file_based?).to be(true)
    end
  end

  describe "#file_count" do
    it "returns count from resolved_paths when file_based" do
      target = described_class.new(file_pattern_attributes)
      expect(target.file_count).to eq(2)
    end

    it "returns count from size_info when resolved_paths is nil" do
      target = described_class.new(git_diff_attributes)
      expect(target.file_count).to eq(3)
    end

    it "returns 0 when both resolved_paths and size_info are nil" do
      target = described_class.new(git_diff_attributes.merge(resolved_paths: nil, size_info: nil))
      expect(target.file_count).to eq(0)
    end

    it "returns 0 when size_info has no files key" do
      target = described_class.new(git_diff_attributes.merge(size_info: {lines: 42, words: 156}))
      expect(target.file_count).to eq(0)
    end

    it "prioritizes resolved_paths over size_info for file_based targets" do
      target = described_class.new(file_pattern_attributes.merge(
        resolved_paths: ["file1.rb", "file2.rb", "file3.rb"],
        size_info: {files: 10}
      ))
      expect(target.file_count).to eq(3)
    end
  end

  describe "#line_count" do
    it "returns line count from size_info" do
      target = described_class.new(git_diff_attributes)
      expect(target.line_count).to eq(42)
    end

    it "returns 0 when size_info is nil" do
      target = described_class.new(git_diff_attributes.merge(size_info: nil))
      expect(target.line_count).to eq(0)
    end

    it "returns 0 when size_info has no lines key" do
      target = described_class.new(git_diff_attributes.merge(size_info: {words: 156, files: 3}))
      expect(target.line_count).to eq(0)
    end
  end

  describe "#word_count" do
    it "returns word count from size_info" do
      target = described_class.new(git_diff_attributes)
      expect(target.word_count).to eq(156)
    end

    it "returns 0 when size_info is nil" do
      target = described_class.new(git_diff_attributes.merge(size_info: nil))
      expect(target.word_count).to eq(0)
    end

    it "returns 0 when size_info has no words key" do
      target = described_class.new(git_diff_attributes.merge(size_info: {lines: 42, files: 3}))
      expect(target.word_count).to eq(0)
    end
  end

  describe ".special_keywords" do
    it "returns array of special keywords" do
      keywords = described_class.special_keywords
      expect(keywords).to eq(%w[staged unstaged working])
    end
  end

  describe "#special_keyword?" do
    it "returns true for staged keyword" do
      target = described_class.new(git_diff_attributes.merge(target_spec: "staged"))
      expect(target.special_keyword?).to be(true)
    end

    it "returns true for unstaged keyword" do
      target = described_class.new(git_diff_attributes.merge(target_spec: "unstaged"))
      expect(target.special_keyword?).to be(true)
    end

    it "returns true for working keyword" do
      target = described_class.new(git_diff_attributes.merge(target_spec: "working"))
      expect(target.special_keyword?).to be(true)
    end

    it "returns false for non-special keywords" do
      target = described_class.new(git_diff_attributes.merge(target_spec: "HEAD~1..HEAD"))
      expect(target.special_keyword?).to be(false)
    end

    it "returns false for file patterns" do
      target = described_class.new(file_pattern_attributes)
      expect(target.special_keyword?).to be(false)
    end
  end

  describe "type consistency" do
    it "maintains consistency between git_based? and file_based?" do
      targets = [
        described_class.new(git_diff_attributes),
        described_class.new(file_pattern_attributes),
        described_class.new(single_file_attributes)
      ]

      targets.each do |target|
        expect(target.git_based?).to eq(!target.file_based?)
      end
    end
  end

  describe "content type patterns" do
    it "handles diff content type correctly" do
      target = described_class.new(git_diff_attributes.merge(content_type: "diff"))
      expect(target.content_type).to eq("diff")
      expect { target.validate! }.not_to raise_error
    end

    it "handles xml content type correctly" do
      target = described_class.new(file_pattern_attributes.merge(content_type: "xml"))
      expect(target.content_type).to eq("xml")
      expect { target.validate! }.not_to raise_error
    end
  end

  describe "edge cases", :edge_cases do
    it "handles empty resolved_paths array" do
      target = described_class.new(file_pattern_attributes.merge(resolved_paths: []))
      expect(target.file_count).to eq(0)
      expect(target.file_based?).to be(true)
    end

    it "handles very large file counts" do
      large_paths = Array.new(10000) { |i| "file#{i}.rb" }
      target = described_class.new(file_pattern_attributes.merge(resolved_paths: large_paths))
      expect(target.file_count).to eq(10000)
    end

    it "handles special characters in target_spec" do
      special_spec = "HEAD~1..HEAD with spaces and (parentheses) & symbols"
      target = described_class.new(git_diff_attributes.merge(target_spec: special_spec))
      expect(target.target_spec).to eq(special_spec)
    end

    it "handles unicode characters in file paths" do
      unicode_paths = ["src/émojis🚀.rb", "lib/ñéẅ_file.rb"]
      target = described_class.new(file_pattern_attributes.merge(resolved_paths: unicode_paths))
      expect(target.resolved_paths).to eq(unicode_paths)
      expect(target.file_count).to eq(2)
    end

    it "handles very large size_info values" do
      large_size_info = {lines: 1_000_000, words: 10_000_000, files: 50_000}
      target = described_class.new(git_diff_attributes.merge(size_info: large_size_info))
      expect(target.line_count).to eq(1_000_000)
      expect(target.word_count).to eq(10_000_000)
      expect(target.file_count).to eq(50_000)
    end

    it "handles zero values in size_info" do
      zero_size_info = {lines: 0, words: 0, files: 0}
      target = described_class.new(git_diff_attributes.merge(size_info: zero_size_info))
      expect(target.line_count).to eq(0)
      expect(target.word_count).to eq(0)
      expect(target.file_count).to eq(0)
    end

    it "handles malformed size_info with extra keys" do
      malformed_size_info = {lines: 42, words: 156, files: 3, extra_key: "ignored", another: 123}
      target = described_class.new(git_diff_attributes.merge(size_info: malformed_size_info))
      expect(target.line_count).to eq(42)
      expect(target.word_count).to eq(156)
      expect(target.file_count).to eq(3)
    end

    it "handles mixed case in special keywords" do
      # Note: The current implementation is case-sensitive, so this should return false
      target = described_class.new(git_diff_attributes.merge(target_spec: "Staged"))
      expect(target.special_keyword?).to be(false)
    end
  end
end
