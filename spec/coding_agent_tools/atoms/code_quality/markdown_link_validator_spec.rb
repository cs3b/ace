# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::MarkdownLinkValidator do
  let(:validator) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#validate_links" do
    context "with valid internal links" do
      it "validates existing local files" do
        # Create test files
        target_file = File.join(temp_dir, "target.md")
        File.write(target_file, "Target content")
        
        source_content = "[Link](target.md)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to include("target.md")
        expect(result[:invalid]).to be_empty
      end

      it "validates relative path links" do
        # Create nested directory structure
        nested_dir = File.join(temp_dir, "docs")
        FileUtils.mkdir_p(nested_dir)
        File.write(File.join(nested_dir, "guide.md"), "Guide content")
        
        source_content = "[Guide](docs/guide.md)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to include("docs/guide.md")
      end

      it "handles links with anchors" do
        target_file = File.join(temp_dir, "target.md")
        File.write(target_file, "# Section\nContent")
        
        source_content = "[Link with anchor](target.md#section)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to include("target.md")
      end
    end

    context "with invalid internal links" do
      it "detects broken local file links" do
        source_content = "[Broken link](nonexistent.md)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:invalid]).to include("nonexistent.md")
        expect(result[:valid]).to be_empty
      end

      it "detects broken relative path links" do
        source_content = "[Broken](docs/nonexistent.md)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:invalid]).to include("docs/nonexistent.md")
      end
    end

    context "with external links" do
      before do
        WebMock.enable!
      end

      after do
        WebMock.disable!
      end

      it "validates accessible external URLs" do
        stub_request(:get, "https://example.com/page")
          .to_return(status: 200, body: "OK")
        
        source_content = "[External](https://example.com/page)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to include("https://example.com/page")
      end

      it "detects inaccessible external URLs" do
        stub_request(:get, "https://broken.example.com")
          .to_return(status: 404, body: "Not Found")
        
        source_content = "[Broken External](https://broken.example.com)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:invalid]).to include("https://broken.example.com")
      end

      it "handles network timeouts" do
        stub_request(:get, "https://timeout.example.com")
          .to_timeout
        
        source_content = "[Timeout](https://timeout.example.com)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:invalid]).to include("https://timeout.example.com")
      end
    end

    context "with mixed link types" do
      it "validates combination of internal and external links" do
        stub_request(:get, "https://example.com").to_return(status: 200)
        
        target_file = File.join(temp_dir, "local.md")
        File.write(target_file, "Local content")
        
        source_content = <<~MARKDOWN
          [Local link](local.md)
          [External link](https://example.com)
          [Broken local](missing.md)
        MARKDOWN
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to include("local.md")
        expect(result[:valid]).to include("https://example.com")
        expect(result[:invalid]).to include("missing.md")
      end
    end

    context "with image links" do
      it "validates image file references" do
        image_file = File.join(temp_dir, "image.png")
        File.write(image_file, "fake image data")
        
        source_content = "![Image](image.png)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to include("image.png")
      end

      it "detects missing image files" do
        source_content = "![Missing](missing.png)"
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:invalid]).to include("missing.png")
      end
    end

    context "with malformed content" do
      it "handles empty content" do
        result = validator.validate_links("", temp_dir)
        
        expect(result[:valid]).to be_empty
        expect(result[:invalid]).to be_empty
      end

      it "handles malformed markdown links" do
        source_content = "[Incomplete link]("
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to be_empty
        expect(result[:invalid]).to be_empty
      end

      it "ignores non-link content" do
        source_content = "Just plain text with no links."
        
        result = validator.validate_links(source_content, temp_dir)
        
        expect(result[:valid]).to be_empty
        expect(result[:invalid]).to be_empty
      end
    end

    context "with performance considerations" do
      it "handles documents with many links efficiently" do
        # Create many target files
        (1..50).each do |i|
          File.write(File.join(temp_dir, "file#{i}.md"), "Content #{i}")
        end
        
        # Create content with many links
        links = (1..50).map { |i| "[File #{i}](file#{i}.md)" }.join("\n")
        
        start_time = Time.now
        result = validator.validate_links(links, temp_dir)
        end_time = Time.now
        
        expect(result[:valid].size).to eq(50)
        expect(end_time - start_time).to be < 2.0  # Should complete reasonably fast
      end
    end
  end

  describe "#extract_links" do
    it "extracts markdown links" do
      content = "[Link](file.md) and ![Image](image.png)"
      
      links = validator.send(:extract_links, content)
      
      expect(links).to include("file.md")
      expect(links).to include("image.png")
    end

    it "ignores malformed links" do
      content = "[Incomplete]( and [Complete](file.md)"
      
      links = validator.send(:extract_links, content)
      
      expect(links).to include("file.md")
      expect(links.size).to eq(1)
    end
  end

  describe "#external_link?" do
    it "identifies external URLs" do
      expect(validator.send(:external_link?, "https://example.com")).to be true
      expect(validator.send(:external_link?, "http://example.com")).to be true
      expect(validator.send(:external_link?, "ftp://example.com")).to be true
      expect(validator.send(:external_link?, "local.md")).to be false
      expect(validator.send(:external_link?, "../file.md")).to be false
    end
  end
end