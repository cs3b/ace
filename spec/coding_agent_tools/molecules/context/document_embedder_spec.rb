# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/coding_agent_tools/molecules/context/document_embedder"

RSpec.describe CodingAgentTools::Molecules::Context::DocumentEmbedder do
  let(:embedder) { described_class.new }

  describe "#embed_content" do
    let(:source_document) do
      <<~MARKDOWN
        # Project Context

        Some documentation content.

        <context-tool-config>
        files:
          - docs/*.md
        format: xml
        </context-tool-config>

        More content here.
      MARKDOWN
    end

    let(:processed_content) do
      <<~CONTENT
        # Processed Context Results

        Files loaded:
        - docs/README.md (1.2KB)
        - docs/GUIDE.md (2.3KB)

        Total: 2 files, 3.5KB
      CONTENT
    end

    context "with nil inputs" do
      it "returns error for nil source document" do
        result = embedder.embed_content(nil, processed_content)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Source document cannot be nil")
      end

      it "returns error for nil processed content" do
        result = embedder.embed_content(source_document, nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Processed content cannot be nil")
      end
    end

    context "without embedding requested" do
      let(:options) { {embed_document_source: false} }

      it "returns processed content only" do
        result = embedder.embed_content(source_document, processed_content, options)
        
        expect(result[:success]).to be true
        expect(result[:embedded]).to be false
        expect(result[:source]).to eq(:processed_only)
        expect(result[:content]).to eq(processed_content)
      end
    end

    context "with embedding at end" do
      let(:options) { {embed_document_source: true, embedding_position: :end} }

      it "embeds content at end of document" do
        result = embedder.embed_content(source_document, processed_content, options)
        
        expect(result[:success]).to be true
        expect(result[:embedded]).to be true
        expect(result[:strategy]).to eq(:end)
        expect(result[:source]).to eq(:full_document_with_embedded)
        
        # Check that original content is preserved
        expect(result[:content]).to include("# Project Context")
        expect(result[:content]).to include("<context-tool-config>")
        
        # Check that processed content is added at end
        expect(result[:content]).to end_with(processed_content.strip)
        expect(result[:content]).to include("<!-- PROCESSED CONTEXT -->")
      end

      it "uses custom marker when provided" do
        custom_options = options.merge(embedding_marker: "<!-- CUSTOM MARKER -->")
        result = embedder.embed_content(source_document, processed_content, custom_options)
        
        expect(result[:success]).to be true
        expect(result[:content]).to include("<!-- CUSTOM MARKER -->")
        expect(result[:marker]).to eq("<!-- CUSTOM MARKER -->")
      end
    end

    context "with embedding after config block" do
      let(:options) { {embed_document_source: true, embedding_position: :after_config} }

      it "embeds content after config block" do
        result = embedder.embed_content(source_document, processed_content, options)
        
        expect(result[:success]).to be true
        expect(result[:embedded]).to be true
        expect(result[:strategy]).to eq(:after_config)
        
        # Check that content is inserted after </context-tool-config>
        config_end_index = result[:content].index("</context-tool-config>")
        marker_index = result[:content].index("<!-- PROCESSED CONTEXT -->")
        
        expect(marker_index).to be > config_end_index
        expect(result[:content]).to include(processed_content.strip)
      end

      it "falls back to end embedding when no config block found" do
        simple_document = "# Simple Document\n\nNo config blocks here."
        result = embedder.embed_content(simple_document, processed_content, options)
        
        expect(result[:success]).to be true
        expect(result[:strategy]).to eq(:end)
      end
    end

    context "with config block replacement" do
      let(:options) { {embed_document_source: true, embedding_position: :replace_config} }

      it "replaces config blocks with processed content" do
        result = embedder.embed_content(source_document, processed_content, options)
        
        expect(result[:success]).to be true
        expect(result[:embedded]).to be true
        expect(result[:strategy]).to eq(:replace_config)
        expect(result[:source]).to eq(:replaced_config_blocks)
        
        # Check that config block is replaced
        expect(result[:content]).not_to include("<context-tool-config>")
        expect(result[:content]).not_to include("</context-tool-config>")
        expect(result[:content]).to include(processed_content.strip)
      end

      it "falls back to end embedding when no config blocks found" do
        simple_document = "# Simple Document\n\nNo config blocks here."
        result = embedder.embed_content(simple_document, processed_content, options)
        
        expect(result[:success]).to be true
        expect(result[:strategy]).to eq(:end)
      end
    end
  end

  describe "#should_embed?" do
    it "returns true when embed_document_source is true" do
      options = {embed_document_source: true}
      expect(embedder.should_embed?(options)).to be true
    end

    it "returns false when embed_document_source is false" do
      options = {embed_document_source: false}
      expect(embedder.should_embed?(options)).to be false
    end

    it "checks YAML config for embedding directive" do
      yaml_config = {"embed_document_source" => true}
      options = {yaml_config: yaml_config}
      expect(embedder.should_embed?(options)).to be true
    end

    it "returns false by default" do
      options = {}
      expect(embedder.should_embed?(options)).to be false
    end
  end

  describe "#remove_existing_embedded_content" do
    let(:document_with_embedded) do
      <<~MARKDOWN
        # Original Content

        Some text here.

        <!-- PROCESSED CONTEXT -->

        Previous embedded content
        that should be removed.
      MARKDOWN
    end

    it "removes existing embedded content" do
      marker = "<!-- PROCESSED CONTEXT -->"
      cleaned = embedder.remove_existing_embedded_content(document_with_embedded, marker)
      
      expect(cleaned).to include("# Original Content")
      expect(cleaned).to include("Some text here.")
      expect(cleaned).not_to include("Previous embedded content")
      expect(cleaned).not_to include("<!-- PROCESSED CONTEXT -->")
    end

    it "handles documents without embedded content" do
      simple_document = "# Simple Document\n\nNo embedded content."
      marker = "<!-- PROCESSED CONTEXT -->"
      cleaned = embedder.remove_existing_embedded_content(simple_document, marker)
      
      expect(cleaned).to eq(simple_document.strip)
    end
  end

  describe "#validate_embedding_options" do
    it "validates valid options" do
      options = {
        embedding_position: :end,
        embedding_marker: "<!-- CUSTOM -->"
      }
      
      result = embedder.validate_embedding_options(options)
      expect(result[:valid]).to be true
      expect(result[:errors]).to be_empty
    end

    it "rejects invalid embedding position" do
      options = {embedding_position: :invalid_position}
      
      result = embedder.validate_embedding_options(options)
      expect(result[:valid]).to be false
      expect(result[:errors]).to include(/Invalid embedding position/)
    end

    it "rejects empty embedding marker" do
      options = {embedding_marker: "   "}
      
      result = embedder.validate_embedding_options(options)
      expect(result[:valid]).to be false
      expect(result[:errors]).to include(/Embedding marker cannot be empty/)
    end

    it "rejects marker with newlines" do
      options = {embedding_marker: "<!-- MARKER\nWITH NEWLINE -->"}
      
      result = embedder.validate_embedding_options(options)
      expect(result[:valid]).to be false
      expect(result[:errors]).to include(/Embedding marker cannot contain newlines/)
    end
  end

  describe "#embedding_summary" do
    it "provides summary for successful embedding" do
      result = {
        success: true,
        embedded: true,
        strategy: :end,
        source: :full_document_with_embedded,
        marker: "<!-- TEST -->",
        content: "test content"
      }
      
      summary = embedder.embedding_summary(result)
      expect(summary).to include("Content embedded successfully")
      expect(summary).to include("Strategy: end")
      expect(summary).to include("Source: full_document_with_embedded")
      expect(summary).to include("Marker: <!-- TEST -->")
    end

    it "provides summary for non-embedded result" do
      result = {
        success: true,
        embedded: false,
        source: :processed_only,
        content: "test content"
      }
      
      summary = embedder.embedding_summary(result)
      expect(summary).to include("Content returned without embedding")
      expect(summary).to include("Source: processed_only")
    end

    it "provides error summary for failed embedding" do
      result = {
        success: false,
        error: "Test error message"
      }
      
      summary = embedder.embedding_summary(result)
      expect(summary).to eq("Embedding failed: Test error message")
    end
  end

  describe "#extract_yaml_config" do
    it "parses valid YAML" do
      yaml_content = "embed_document_source: true\nformat: xml"
      config = embedder.extract_yaml_config(yaml_content)
      
      expect(config["embed_document_source"]).to be true
      expect(config["format"]).to eq("xml")
    end

    it "returns empty hash for invalid YAML" do
      yaml_content = "invalid: [unclosed bracket"
      config = embedder.extract_yaml_config(yaml_content)
      
      expect(config).to eq({})
    end

    it "returns empty hash for nil or empty input" do
      expect(embedder.extract_yaml_config(nil)).to eq({})
      expect(embedder.extract_yaml_config("")).to eq({})
    end
  end
end