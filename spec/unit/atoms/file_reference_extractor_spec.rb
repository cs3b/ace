# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/file_reference_extractor"

RSpec.describe CodingAgentTools::Atoms::FileReferenceExtractor do
  let(:extractor) { described_class.new }

  describe "#extract_markdown_links" do
    it "extracts markdown links from content" do
      content = "See [Architecture](docs/architecture.md) and [Blueprint](../blueprint.md)"
      links = extractor.extract_markdown_links(content)
      
      expect(links).to eq([
        ["Architecture", "docs/architecture.md"],
        ["Blueprint", "../blueprint.md"]
      ])
    end

    it "handles empty content" do
      expect(extractor.extract_markdown_links("")).to eq([])
    end
  end

  describe "#extract_context_references" do
    it "extracts context loading references" do
      content = "Load project objectives: `docs/what-do-we-build.md`\nCheck something: `other.wf.md`"
      refs = extractor.extract_context_references(content)
      
      expect(refs).to eq(["docs/what-do-we-build.md", "other.wf.md"])
    end

    it "handles various context patterns" do
      content = "Read: `file.md` and See: `guide.g.md`"
      refs = extractor.extract_context_references(content)
      
      expect(refs).to include("file.md", "guide.g.md")
    end
  end

  describe "#extract_all_references" do
    it "combines markdown links and context references, filtering out external/anchor links" do
      content = <<~CONTENT
        See [Guide](guide.md) for more info.
        Load config: `config.md`
        External [link](https://example.com) should be filtered out.
        Anchor [link](#section) should be filtered out too.
      CONTENT
      
      refs = extractor.extract_all_references(content)
      
      # Only internal links should be included
      expect(refs).to include("guide.md", "config.md")
      expect(refs).not_to include("https://example.com", "#section")
    end
  end

  describe "link type checks" do
    it "identifies external links" do
      expect(extractor.external_link?("https://example.com")).to be true
      expect(extractor.external_link?("http://example.com")).to be true
      expect(extractor.external_link?("docs/file.md")).to be false
    end

    it "identifies anchor links" do
      expect(extractor.anchor_link?("#section")).to be true
      expect(extractor.anchor_link?("docs/file.md")).to be false
    end

    it "identifies internal links" do
      expect(extractor.internal_link?("docs/file.md")).to be true
      expect(extractor.internal_link?("https://example.com")).to be false
      expect(extractor.internal_link?("#section")).to be false
    end
  end
end