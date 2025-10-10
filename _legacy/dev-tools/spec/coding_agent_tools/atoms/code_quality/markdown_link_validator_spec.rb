# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::MarkdownLinkValidator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:validator) { described_class.new(root: temp_dir) }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#validate" do
    context "with valid markdown files" do
      it "validates existing local files with no broken links" do
        # Create test files
        target_file = File.join(temp_dir, "target.md")
        File.write(target_file, "Target content")

        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[Link](target.md)")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
        expect(result[:errors]).to be_empty
      end

      it "validates relative path links" do
        # Create nested directory structure
        nested_dir = File.join(temp_dir, "docs")
        FileUtils.mkdir_p(nested_dir)
        File.write(File.join(nested_dir, "guide.md"), "Guide content")

        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[Guide](docs/guide.md)")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "handles links with anchors" do
        target_file = File.join(temp_dir, "target.md")
        File.write(target_file, "# Section\nContent")

        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[Link with anchor](target.md#section)")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with invalid internal links" do
      it "detects broken local file links" do
        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[Broken link](nonexistent.md)")

        result = validator.validate([source_file])

        expect(result[:success]).to be false
        expect(result[:findings]).not_to be_empty
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first).to include("Broken link")
      end

      it "detects broken relative path links" do
        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[Broken](docs/nonexistent.md)")

        result = validator.validate([source_file])

        expect(result[:success]).to be false
        expect(result[:findings]).not_to be_empty
      end
    end

    context "with external links" do
      it "ignores external URLs (not validated)" do
        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[External](https://example.com/page)")

        result = validator.validate([source_file])

        # External links are ignored by this validator
        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "ignores mailto links" do
        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "[Email](mailto:test@example.com)")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with mixed content" do
      it "validates combination of internal and external links" do
        target_file = File.join(temp_dir, "local.md")
        File.write(target_file, "Local content")

        source_file = File.join(temp_dir, "source.md")
        content = <<~MARKDOWN
          # Project Documentation
          
          See [architecture](local.md) for details.
          [External link](https://example.com) is ignored.
          [Broken local](missing.md) should be caught.
        MARKDOWN
        File.write(source_file, content)

        result = validator.validate([source_file])

        expect(result[:success]).to be false
        expect(result[:findings].length).to eq(1)
        expect(result[:findings].first[:link]).to eq("missing.md")
      end
    end

    context "with image links" do
      it "validates image file references" do
        image_file = File.join(temp_dir, "image.png")
        File.write(image_file, "fake image data")

        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "![Image](image.png)")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "detects missing image files" do
        source_file = File.join(temp_dir, "source.md")
        File.write(source_file, "![Missing](missing.png)")

        result = validator.validate([source_file])

        expect(result[:success]).to be false
        expect(result[:findings]).not_to be_empty
      end
    end

    context "with code blocks" do
      it "ignores links in code blocks" do
        source_file = File.join(temp_dir, "source.md")
        content = <<~MARKDOWN
          # Documentation
          
          Here's a code example:
          
          ```markdown
          [This link](nonexistent.md) is in a code block
          ```
          
          This [real link](nonexistent.md) should be checked.
        MARKDOWN
        File.write(source_file, content)

        result = validator.validate([source_file])

        expect(result[:success]).to be false
        expect(result[:findings].length).to eq(1)
        expect(result[:findings].first[:link]).to eq("nonexistent.md")
      end
    end

    context "with empty or malformed content" do
      it "handles empty files" do
        source_file = File.join(temp_dir, "empty.md")
        File.write(source_file, "")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end

      it "handles files with no links" do
        source_file = File.join(temp_dir, "no_links.md")
        File.write(source_file, "Just plain text with no links.")

        result = validator.validate([source_file])

        expect(result[:success]).to be true
        expect(result[:findings]).to be_empty
      end
    end

    context "with directory validation" do
      it "validates all markdown files in a directory" do
        # Create multiple files with different link states
        File.write(File.join(temp_dir, "good.md"), "[Valid](target.md)")
        File.write(File.join(temp_dir, "target.md"), "Target content")
        File.write(File.join(temp_dir, "bad.md"), "[Broken](missing.md)")

        result = validator.validate([temp_dir])

        expect(result[:success]).to be false
        expect(result[:findings].length).to eq(1)
        expect(result[:findings].first[:link]).to eq("missing.md")
      end
    end
  end

  describe "initialization" do
    it "sets default root path when none provided" do
      validator = described_class.new
      expect(validator.root_path.to_s).to eq(File.expand_path("."))
    end

    it "sets custom root path when provided" do
      custom_path = "/custom/path"
      validator = described_class.new(root: custom_path)
      expect(validator.root_path.to_s).to eq(File.expand_path(custom_path))
    end

    it "sets default context lines" do
      validator = described_class.new
      expect(validator.context_lines).to eq(3)
    end

    it "sets custom context lines when provided" do
      validator = described_class.new(context: 5)
      expect(validator.context_lines).to eq(5)
    end
  end
end
