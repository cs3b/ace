# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/coding_agent_tools/molecules/context/markdown_yaml_extractor"

RSpec.describe CodingAgentTools::Molecules::Context::MarkdownYamlExtractor do
  let(:extractor) { described_class.new }

  describe "#extract_yaml_from_markdown" do
    context "with nil or empty content" do
      it "returns error for nil content" do
        result = extractor.extract_yaml_from_markdown(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Content cannot be nil")
      end

      it "returns error for empty content" do
        result = extractor.extract_yaml_from_markdown("")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Content cannot be empty")
      end
    end

    context "with tagged blocks format" do
      let(:markdown_with_tags) do
        <<~MARKDOWN
          # Project Context

          Some documentation content.

          <context-tool-config>
          files:
            - docs/*.md
            - README.md
          commands:
            - git-status
          format: markdown-xml
          </context-tool-config>

          More content here.
        MARKDOWN
      end

      it "extracts YAML from tagged blocks" do
        result = extractor.extract_yaml_from_markdown(markdown_with_tags)

        expect(result[:success]).to be true
        expect(result[:source_format]).to eq(:tagged_blocks)
        expect(result[:template][:files]).to eq(["docs/*.md", "README.md"])
        expect(result[:template][:commands]).to eq(["git-status"])
        expect(result[:template][:format]).to eq("markdown-xml")
      end

      it "includes the extracted YAML content" do
        result = extractor.extract_yaml_from_markdown(markdown_with_tags)

        expect(result[:yaml_content]).to include("files:")
        expect(result[:yaml_content]).to include("- docs/*.md")
        expect(result[:yaml_content]).to include("commands:")
        expect(result[:yaml_content]).to include("format: markdown-xml")
      end
    end

    context "with multiple tagged blocks" do
      let(:markdown_with_multiple_blocks) do
        <<~MARKDOWN
          # Project Context

          <context-tool-config>
          files:
            - docs/*.md
          format: xml
          </context-tool-config>

          Some content between blocks.

          <context-tool-config>
          files:
            - src/*.rb
          format: yaml
          </context-tool-config>

          End content.
        MARKDOWN
      end

      it "uses the first block and warns about others" do
        result = extractor.extract_yaml_from_markdown(markdown_with_multiple_blocks)

        expect(result[:success]).to be true
        expect(result[:source_format]).to eq(:tagged_blocks)
        expect(result[:total_blocks]).to eq(2)
        expect(result[:warning]).to include("Multiple <context-tool-config> blocks found")
        expect(result[:template][:format]).to eq("xml") # From first block
      end
    end

    context "with legacy Context Definition format" do
      let(:markdown_with_legacy_format) do
        <<~MARKDOWN
          # Agent Documentation

          ## Core Functionality
          This agent does important work.

          ## Context Definition

          ```yaml
          files:
            - legacy/*.md
          commands:
            - task-manager list
          format: markdown-xml
          ```

          ## Error Handling
          Handle errors gracefully.
        MARKDOWN
      end

      it "extracts YAML from legacy format" do
        result = extractor.extract_yaml_from_markdown(markdown_with_legacy_format)

        expect(result[:success]).to be true
        expect(result[:source_format]).to eq(:context_definition)
        expect(result[:template][:files]).to eq(["legacy/*.md"])
        expect(result[:template][:commands]).to eq(["task-manager list"])
        expect(result[:template][:format]).to eq("markdown-xml")
      end
    end

    context "with invalid YAML in tagged blocks" do
      let(:markdown_with_invalid_yaml) do
        <<~MARKDOWN
          # Project Context

          <context-tool-config>
          files:
            - docs/*.md
          invalid_yaml: [unclosed bracket]
          format: xml
          
          
          invalid_key_structure: {
          </context-tool-config>
        MARKDOWN
      end

      it "returns error for invalid YAML" do
        result = extractor.extract_yaml_from_markdown(markdown_with_invalid_yaml)

        expect(result[:success]).to be false
        expect(result[:error]).to match(/parse|template/)
        expect(result[:source_format]).to eq(:tagged_blocks)
      end
    end

    context "with no extractable configuration" do
      let(:plain_markdown) do
        <<~MARKDOWN
          # Regular Markdown

          This is just regular markdown content without any
          context configuration blocks or sections.

          ## Some Section
          Regular content here.
        MARKDOWN
      end

      it "returns error when no configuration found" do
        result = extractor.extract_yaml_from_markdown(plain_markdown)

        expect(result[:success]).to be false
        expect(result[:error]).to include("No <context-tool-config> blocks or Context Definition sections found")
      end
    end
  end

  describe "#find_context_tool_config_blocks" do
    it "finds single block" do
      content = <<~MARKDOWN
        <context-tool-config>
        files: [docs/*.md]
        </context-tool-config>
      MARKDOWN

      blocks = extractor.find_context_tool_config_blocks(content)
      expect(blocks.length).to eq(1)
      expect(blocks.first).to include("files: [docs/*.md]")
    end

    it "finds multiple blocks" do
      content = <<~MARKDOWN
        <context-tool-config>
        files: [docs/*.md]
        </context-tool-config>
        
        <context-tool-config>
        commands: [git status]
        </context-tool-config>
      MARKDOWN

      blocks = extractor.find_context_tool_config_blocks(content)
      expect(blocks.length).to eq(2)
      expect(blocks.first).to include("files: [docs/*.md]")
      expect(blocks.last).to include("commands: [git status]")
    end

    it "returns empty array when no blocks found" do
      content = "Regular markdown content without tagged blocks"
      blocks = extractor.find_context_tool_config_blocks(content)
      expect(blocks).to be_empty
    end

    it "ignores empty blocks" do
      content = <<~MARKDOWN
        <context-tool-config>
        files: [docs/*.md]
        </context-tool-config>
        
        <context-tool-config>
        
        </context-tool-config>
      MARKDOWN

      blocks = extractor.find_context_tool_config_blocks(content)
      expect(blocks.length).to eq(1)
    end
  end

  describe "#has_extractable_config?" do
    it "returns true for content with tagged blocks" do
      content = <<~MARKDOWN
        <context-tool-config>
        files: [docs/*.md]
        </context-tool-config>
      MARKDOWN

      expect(extractor.has_extractable_config?(content)).to be true
    end

    it "returns true for content with legacy Context Definition" do
      content = <<~MARKDOWN
        ## Context Definition
        ```yaml
        files: [docs/*.md]
        ```
      MARKDOWN

      expect(extractor.has_extractable_config?(content)).to be true
    end

    it "returns false for content without configuration" do
      content = "Regular markdown content"
      expect(extractor.has_extractable_config?(content)).to be false
    end

    it "returns false for nil or empty content" do
      expect(extractor.has_extractable_config?(nil)).to be false
      expect(extractor.has_extractable_config?("")).to be false
    end
  end

  describe "#validate_markdown_config" do
    context "with valid tagged blocks" do
      let(:valid_content) do
        <<~MARKDOWN
          <context-tool-config>
          files: [docs/*.md]
          format: xml
          </context-tool-config>
        MARKDOWN
      end

      it "returns valid result" do
        result = extractor.validate_markdown_config(valid_content)

        expect(result[:valid]).to be true
        expect(result[:source_format]).to eq(:tagged_blocks)
        expect(result[:template]).to be_a(Hash)
      end
    end

    context "with valid legacy format" do
      let(:legacy_content) do
        <<~MARKDOWN
          ## Context Definition
          ```yaml
          files: [legacy/*.md]
          ```
        MARKDOWN
      end

      it "returns valid result" do
        result = extractor.validate_markdown_config(legacy_content)

        expect(result[:valid]).to be true
        expect(result[:source_format]).to eq(:context_definition)
      end
    end

    context "with invalid content" do
      it "returns invalid for content without configuration" do
        result = extractor.validate_markdown_config("Regular content")

        expect(result[:valid]).to be false
        expect(result[:error]).to include("No <context-tool-config> blocks or Context Definition sections found")
      end

      it "returns invalid for nil content" do
        result = extractor.validate_markdown_config(nil)

        expect(result[:valid]).to be false
        expect(result[:error]).to eq("Content cannot be nil")
      end
    end
  end

  describe "#extraction_summary" do
    it "provides summary for successful tagged extraction" do
      result = {
        success: true,
        source_format: :tagged_blocks,
        total_blocks: 1,
        template: {
          files: ["docs/*.md"],
          commands: ["git-status"],
          format: "xml"
        }
      }

      summary = extractor.extraction_summary(result)
      expect(summary).to include("YAML extracted successfully")
      expect(summary).to include("Source: <context-tool-config> tagged blocks")
      expect(summary).to include("Files: 1 pattern(s)")
      expect(summary).to include("Commands: 1 command(s)")
      expect(summary).to include("Format: xml")
    end

    it "provides summary for legacy extraction" do
      result = {
        success: true,
        source_format: :context_definition,
        template: {
          files: ["legacy/*.md"],
          commands: [],
          format: "yaml"
        }
      }

      summary = extractor.extraction_summary(result)
      expect(summary).to include("Source: Legacy Context Definition section")
    end

    it "provides error summary for failed extraction" do
      result = {
        success: false,
        error: "Invalid YAML format"
      }

      summary = extractor.extraction_summary(result)
      expect(summary).to eq("Extraction failed: Invalid YAML format")
    end
  end
end
