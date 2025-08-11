# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Claude::YamlFrontmatterValidator do
  describe ".valid?" do
    context "with valid YAML frontmatter" do
      it "returns true for simple YAML" do
        content = <<~CONTENT
          ---
          description: Test command
          allowed-tools: Read, Write
          ---
          
          Some content
        CONTENT

        expect(described_class.valid?(content)).to be true
      end

      it "returns true for complex YAML" do
        content = <<~CONTENT
          ---
          description: Complex command
          allowed-tools: Read, Write, Bash
          argument-hint: "[task-id]"
          model: opus
          ---
          
          More content
        CONTENT

        expect(described_class.valid?(content)).to be true
      end
    end

    context "with invalid YAML frontmatter" do
      it "returns false for malformed YAML" do
        content = <<~CONTENT
          ---
          description: Missing colon
          allowed-tools
          ---
          
          Content
        CONTENT

        expect(described_class.valid?(content)).to be false
      end

      it "returns false for missing closing marker" do
        content = <<~CONTENT
          ---
          description: No closing marker
          allowed-tools: Read
          
          Content
        CONTENT

        expect(described_class.valid?(content)).to be false
      end

      it "returns false for missing opening marker" do
        content = <<~CONTENT
          description: No opening marker
          allowed-tools: Read
          ---
          
          Content
        CONTENT

        expect(described_class.valid?(content)).to be false
      end
    end

    context "with edge cases" do
      it "returns false for nil content" do
        expect(described_class.valid?(nil)).to be false
      end

      it "returns false for empty content" do
        expect(described_class.valid?("")).to be false
      end

      it "returns false for content without frontmatter" do
        content = "Just some regular content\nwithout frontmatter"
        expect(described_class.valid?(content)).to be false
      end
    end
  end

  describe ".parse" do
    context "with valid YAML frontmatter" do
      it "returns parsed hash" do
        content = <<~CONTENT
          ---
          description: Test command
          allowed-tools: Read, Write
          model: sonnet
          ---
          
          Content
        CONTENT

        result = described_class.parse(content)
        expect(result).to eq({
          "description" => "Test command",
          "allowed-tools" => "Read, Write",
          "model" => "sonnet"
        })
      end
    end

    context "with invalid content" do
      it "returns nil for malformed YAML" do
        content = <<~CONTENT
          ---
          invalid: yaml: syntax
          ---
        CONTENT

        expect(described_class.parse(content)).to be_nil
      end

      it "returns nil for nil content" do
        expect(described_class.parse(nil)).to be_nil
      end

      it "returns nil for empty content" do
        expect(described_class.parse("")).to be_nil
      end

      it "returns nil for non-hash YAML" do
        content = <<~CONTENT
          ---
          - item1
          - item2
          ---
        CONTENT

        expect(described_class.parse(content)).to be_nil
      end
    end
  end

  describe ".extract_frontmatter" do
    it "extracts frontmatter content without markers" do
      content = <<~CONTENT
        ---
        description: Test
        model: opus
        ---
        
        Body content
      CONTENT

      result = described_class.extract_frontmatter(content)
      expect(result).to eq("description: Test\nmodel: opus")
    end

    it "returns nil for content without frontmatter" do
      content = "Just regular content"
      expect(described_class.extract_frontmatter(content)).to be_nil
    end

    it "returns nil for nil content" do
      expect(described_class.extract_frontmatter(nil)).to be_nil
    end
  end

  describe ".has_frontmatter?" do
    it "returns true when frontmatter exists" do
      content = <<~CONTENT
        ---
        key: value
        ---
        
        Content
      CONTENT

      expect(described_class.has_frontmatter?(content)).to be true
    end

    it "returns false when no frontmatter" do
      content = "Regular content without frontmatter"
      expect(described_class.has_frontmatter?(content)).to be false
    end

    it "returns false for nil content" do
      expect(described_class.has_frontmatter?(nil)).to be false
    end

    it "returns false for empty content" do
      expect(described_class.has_frontmatter?("")).to be false
    end
  end
end
