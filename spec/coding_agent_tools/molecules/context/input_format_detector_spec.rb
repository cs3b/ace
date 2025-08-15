# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/coding_agent_tools/molecules/context/input_format_detector"

RSpec.describe CodingAgentTools::Molecules::Context::InputFormatDetector do
  let(:detector) { described_class.new }

  describe "#detect_format" do
    context "with nil input" do
      it "returns error for nil input" do
        result = detector.detect_format(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Input cannot be nil")
      end
    end

    context "with empty input" do
      it "returns error for empty input" do
        result = detector.detect_format("")
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Input cannot be empty")
      end
    end

    context "with YAML file" do
      let(:yaml_file) { "template.yml" }
      let(:yaml_content) { "files:\n  - docs/*.md\nformat: xml" }

      before do
        allow(File).to receive(:exist?).with(yaml_file).and_return(true)
      end

      it "detects YAML file format" do
        result = detector.detect_format(yaml_file)
        expect(result[:success]).to be true
        expect(result[:format]).to eq(:yaml_file)
        expect(result[:file_path]).to eq(yaml_file)
      end
    end

    context "with agent markdown file" do
      let(:agent_file) { "task-finder.ag.md" }

      before do
        allow(File).to receive(:exist?).with(agent_file).and_return(true)
        # Mock file reading for old agent format (no context-tool-config tags)
        allow(File).to receive(:read).with(agent_file).and_return("# Agent: Task Finder\n\n## Context Definition\nfiles:\n  - '**/*.md'")
      end

      it "detects agent file format" do
        result = detector.detect_format(agent_file)
        expect(result[:success]).to be true
        expect(result[:format]).to eq(:agent_file)
        expect(result[:file_path]).to eq(agent_file)
      end
    end

    context "with regular markdown file" do
      let(:md_file) { "context.md" }

      before do
        allow(File).to receive(:exist?).with(md_file).and_return(true)
      end

      it "detects markdown file format" do
        result = detector.detect_format(md_file)
        expect(result[:success]).to be true
        expect(result[:format]).to eq(:markdown_file)
        expect(result[:file_path]).to eq(md_file)
      end
    end

    context "with YAML string content" do
      let(:yaml_string) { "files:\n  - docs/*.md\ncommands:\n  - git status" }

      it "detects YAML string format" do
        result = detector.detect_format(yaml_string)
        expect(result[:success]).to be true
        expect(result[:format]).to eq(:yaml_string)
        expect(result[:content]).to eq(yaml_string)
      end
    end

    context "with markdown string containing context tags" do
      let(:markdown_string) do
        <<~MARKDOWN
          # Project Context
          
          <context-tool-config>
          files:
            - docs/*.md
          </context-tool-config>
        MARKDOWN
      end

      it "detects markdown string format" do
        result = detector.detect_format(markdown_string)
        expect(result[:success]).to be true
        expect(result[:format]).to eq(:markdown_string)
        expect(result[:content]).to eq(markdown_string)
      end
    end
  end

  describe "#looks_like_file_path?" do
    it "returns true for paths with separators" do
      expect(detector.looks_like_file_path?("docs/file.md")).to be true
      expect(detector.looks_like_file_path?("../file.yml")).to be true
      expect(detector.looks_like_file_path?("file.txt")).to be true
    end

    it "returns false for plain strings" do
      expect(detector.looks_like_file_path?("files: docs")).to be false
      expect(detector.looks_like_file_path?("plain text")).to be false
    end
  end

  describe "#detect_file_format" do
    it "detects YAML files" do
      expect(detector.detect_file_format("template.yml")).to eq(:yaml_file)
      expect(detector.detect_file_format("config.yaml")).to eq(:yaml_file)
    end

    it "detects agent markdown files" do
      expect(detector.detect_file_format("task-finder.ag.md")).to eq(:agent_file)
      expect(detector.detect_file_format("search.ag.md")).to eq(:agent_file)
    end

    it "detects regular markdown files" do
      expect(detector.detect_file_format("README.md")).to eq(:markdown_file)
      expect(detector.detect_file_format("context.md")).to eq(:markdown_file)
    end

    it "returns unknown for unrecognized extensions" do
      expect(detector.detect_file_format("file.txt")).to eq(:unknown)
      expect(detector.detect_file_format("script.rb")).to eq(:unknown)
    end
  end

  describe "#has_context_config_tag?" do
    it "returns true when tags are present" do
      content = "<context-tool-config>\nfiles: []\n</context-tool-config>"
      expect(detector.has_context_config_tag?(content)).to be true
    end

    it "returns false when tags are absent" do
      content = "Regular markdown content without tags"
      expect(detector.has_context_config_tag?(content)).to be false
    end
  end

  describe "#looks_like_yaml?" do
    it "returns true for YAML content with document separator" do
      content = "---\nfiles:\n  - docs/*.md"
      expect(detector.looks_like_yaml?(content)).to be true
    end

    it "returns true for YAML content with key-value pairs" do
      content = "files:\n  - docs/*.md\nformat: xml"
      expect(detector.looks_like_yaml?(content)).to be true
    end

    it "returns false for content with context tags" do
      content = "<context-tool-config>\nfiles: []\n</context-tool-config>"
      expect(detector.looks_like_yaml?(content)).to be false
    end

    it "returns false for plain text" do
      content = "This is just plain text without structure"
      expect(detector.looks_like_yaml?(content)).to be false
    end
  end

  describe "#format_description" do
    it "returns descriptions for all supported formats" do
      expect(detector.format_description(:yaml_file)).to eq("YAML template file")
      expect(detector.format_description(:agent_file)).to eq("Agent markdown file (.ag.md)")
      expect(detector.format_description(:markdown_file)).to eq("Instruction markdown file with <context-tool-config> tags")
      expect(detector.format_description(:unknown)).to eq("Unknown format")
    end
  end

  describe "#supported_format?" do
    it "returns true for supported formats" do
      expect(detector.supported_format?(:yaml_file)).to be true
      expect(detector.supported_format?(:agent_file)).to be true
      expect(detector.supported_format?(:markdown_file)).to be true
    end

    it "returns false for unsupported formats" do
      expect(detector.supported_format?(:unknown)).to be false
      expect(detector.supported_format?(:unsupported)).to be false
    end
  end
end