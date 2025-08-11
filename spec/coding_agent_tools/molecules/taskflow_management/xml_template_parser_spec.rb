# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser do
  let(:parser) { described_class.new }

  describe "#parse" do
    context "with documents format" do
      let(:content) do
        <<~MARKDOWN
          # Some markdown

          <documents>
          <template path="dev-handbook/templates/example.template.md">
          # Example Template
          
          This is template content.
          </template>

          <guide path="dev-handbook/guides/example.g.md">
          # Example Guide

          This is guide content.
          </guide>
          </documents>

          More markdown content.
        MARKDOWN
      end

      it "extracts templates and guides correctly", :format_support do
        result = parser.parse(content)

        expect(result.success?).to be true
        expect(result.documents.size).to eq 2

        template = result.documents.find(&:template?)
        expect(template.path).to eq "dev-handbook/templates/example.template.md"
        expect(template.content).to include "# Example Template"
        expect(template.source_format).to eq :documents

        guide = result.documents.find(&:guide?)
        expect(guide.path).to eq "dev-handbook/guides/example.g.md"
        expect(guide.content).to include "# Example Guide"
        expect(guide.source_format).to eq :documents
      end

      it "handles multiple documents sections" do
        multi_section_content = content + "\n\n" + content
        result = parser.parse(multi_section_content)

        expect(result.success?).to be true
        expect(result.documents.size).to eq 4
        expect(result.template_count).to eq 2
        expect(result.guide_count).to eq 2
      end
    end

    context "with legacy templates format" do
      let(:content) do
        <<~MARKDOWN
          # Some markdown

          <templates>
          <template path="dev-handbook/templates/legacy.template.md">
          # Legacy Template
          
          This is legacy template content.
          </template>
          </templates>
        MARKDOWN
      end

      it "extracts legacy templates with warning" do
        result = parser.parse(content)

        expect(result.success?).to be true
        expect(result.documents.size).to eq 1
        expect(result.has_warnings?).to be true
        expect(result.warnings).to include(/Legacy.*templates.*format/)

        template = result.documents.first
        expect(template.path).to eq "dev-handbook/templates/legacy.template.md"
        expect(template.type).to eq :template
        expect(template.source_format).to eq :templates
      end
    end

    context "with mixed formats" do
      let(:content) do
        <<~MARKDOWN
          <documents>
          <template path="dev-handbook/templates/new.template.md">New format</template>
          </documents>

          <templates>
          <template path="dev-handbook/templates/old.template.md">Old format</template>
          </templates>
        MARKDOWN
      end

      it "handles both new and legacy formats" do
        result = parser.parse(content)

        expect(result.success?).to be true
        expect(result.documents.size).to eq 2
        expect(result.has_warnings?).to be true

        new_format = result.documents.find { |d| d.source_format == :documents }
        legacy_format = result.documents.find { |d| d.source_format == :templates }

        expect(new_format.path).to eq "dev-handbook/templates/new.template.md"
        expect(legacy_format.path).to eq "dev-handbook/templates/old.template.md"
      end
    end

    context "with edge cases", :edge_cases do
      it "handles empty content gracefully" do
        result = parser.parse("")

        expect(result.success?).to be true
        expect(result.documents).to be_empty
      end

      it "handles malformed XML gracefully" do
        malformed_content = <<~MARKDOWN
          <documents>
          <template path="test.md">Content without closing tag
          </documents>
        MARKDOWN

        result = parser.parse(malformed_content)

        # Should still succeed but extract what it can
        expect(result.success?).to be true
        expect(result.documents).to be_empty
      end

      it "handles missing path attribute" do
        missing_path_content = <<~MARKDOWN
          <documents>
          <template>Content without path</template>
          </documents>
        MARKDOWN

        result = parser.parse(missing_path_content)

        expect(result.success?).to be true
        expect(result.documents).to be_empty
      end

      it "handles empty path attribute" do
        empty_path_content = <<~MARKDOWN
          <documents>
          <template path="">Content with empty path</template>
          </documents>
        MARKDOWN

        result = parser.parse(empty_path_content)

        expect(result.success?).to be true
        expect(result.documents).to be_empty
      end

      it "handles whitespace in paths" do
        whitespace_content = <<~MARKDOWN
          <documents>
          <template path="  dev-handbook/templates/test.template.md  ">Content</template>
          </documents>
        MARKDOWN

        result = parser.parse(whitespace_content)

        expect(result.success?).to be true
        expect(result.documents.size).to eq 1
        expect(result.documents.first.path).to eq "dev-handbook/templates/test.template.md"
      end
    end
  end

  describe "format registration and extensibility", :format_support do
    it "supports checking for format support" do
      expect(parser.supports_format?(:documents)).to be true
      expect(parser.supports_format?(:templates)).to be true
      expect(parser.supports_format?(:custom)).to be false
    end

    it "lists supported formats" do
      formats = parser.supported_formats
      expect(formats).to include(:documents, :templates)
    end

    it "allows registering custom format handlers" do
      custom_handler = double("CustomHandler")
      allow(custom_handler).to receive(:extract).and_return(
        CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::FormatResult.new([], [], [])
      )

      parser.register_format(:custom, custom_handler)

      expect(parser.supports_format?(:custom)).to be true
      expect(parser.supported_formats).to include(:custom)

      # Test that custom handler is called
      parser.parse("test content")
      expect(custom_handler).to have_received(:extract).with("test content", nil)
    end
  end

  describe "result structures" do
    describe "ParsedDocument" do
      let(:doc) { described_class::ParsedDocument.new("path", "content", :template, :documents, 1, 5) }

      it "provides type checking methods" do
        expect(doc.template?).to be true
        expect(doc.guide?).to be false

        guide_doc = described_class::ParsedDocument.new("path", "content", :guide, :documents, 1, 5)
        expect(guide_doc.template?).to be false
        expect(guide_doc.guide?).to be true
      end
    end

    describe "ParserResult" do
      let(:template_doc) { described_class::ParsedDocument.new("t", "c", :template, :documents, 1, 2) }
      let(:guide_doc) { described_class::ParsedDocument.new("g", "c", :guide, :documents, 1, 2) }

      it "provides success checking" do
        success_result = described_class::ParserResult.new([], [], [])
        failure_result = described_class::ParserResult.new([], ["error"], [])

        expect(success_result.success?).to be true
        expect(failure_result.success?).to be false
      end

      it "counts documents by type" do
        result = described_class::ParserResult.new([template_doc, guide_doc, template_doc], [], [])

        expect(result.template_count).to eq 2
        expect(result.guide_count).to eq 1
      end

      it "detects warnings" do
        no_warnings = described_class::ParserResult.new([], [], [])
        with_warnings = described_class::ParserResult.new([], [], ["warning"])

        expect(no_warnings.has_warnings?).to be false
        expect(with_warnings.has_warnings?).to be true
      end
    end
  end
end
