# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::Code::PromptCombiner, :workflow do
  let(:combiner) { described_class.new }
  let(:file_reader_mock) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }
  let(:yaml_reader_mock) { instance_double(CodingAgentTools::Atoms::YamlReader) }

  before do
    # Mock the atoms dependencies
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(file_reader_mock)
    allow(CodingAgentTools::Atoms::YamlReader).to receive(:new).and_return(yaml_reader_mock)

    # Set up the instance variable mocks
    combiner.instance_variable_set(:@file_reader, file_reader_mock)
    combiner.instance_variable_set(:@yaml_reader, yaml_reader_mock)
  end

  describe "#build_prompt" do
    let(:session) do
      CodingAgentTools::Models::Code::ReviewSession.new(
        session_id: "test-session",
        session_name: "test-session",
        timestamp: Time.now.iso8601,
        directory_path: "/tmp/test-session",
        target: "lib/test.rb",
        context_mode: "diff",
        focus: "code"
      )
    end

    let(:target_content) { "puts 'Hello World'" }

    let(:context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [
          {
            type: "blueprint",
            path: "docs/blueprint.md",
            content: "# Project Blueprint"
          }
        ],
        loaded_at: Time.now
      )
    end

    let(:focus) { "code" }
    let(:system_prompt_content) { "You are a security-focused code reviewer." }

    before do
      # Mock system prompt loading
      allow(combiner).to receive(:select_system_prompt).and_return("prompts/security.md")
      allow(file_reader_mock).to receive(:read).with("prompts/security.md").and_return(
        success: true,
        content: system_prompt_content
      )
    end

    it "builds complete prompt from components" do
      result = combiner.build_prompt(session, target_content, context, focus)

      expect(result).to be_a(CodingAgentTools::Models::Code::ReviewPrompt)
      expect(result.system_prompt_path).not_to be_nil
      expect(result.combined_content).to include(target_content)
      expect(result.combined_content).to include("Project Blueprint")
    end

    it "includes session metadata in prompt" do
      result = combiner.build_prompt(session, target_content, context, focus)

      expect(result.session_id).to eq("test-session")
      expect(result.combined_content).to include("lib/test.rb")
      expect(result.focus_areas).to eq([
        "Code quality, architecture, security, performance",
        "Architecture compliance (see docs/architecture.md)",
        "Ruby best practices and conventions"
      ])
    end

    it "handles empty context gracefully" do
      empty_context = CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "none",
        documents: [],
        loaded_at: Time.now
      )

      result = combiner.build_prompt(session, target_content, empty_context, focus)

      expect(result.system_prompt_path).not_to be_nil
      expect(result.combined_content).to include(target_content)
      expect(result.combined_content).not_to include("Project Blueprint")
    end

    it "handles system prompt loading failure" do
      allow(file_reader_mock).to receive(:read).and_return(
        success: false,
        error: "File not found"
      )

      result = combiner.build_prompt(session, target_content, context, focus)

      expect(result.system_prompt_path).not_to be_nil
      expect(result.combined_content).to include(target_content)
    end

    context "with custom system prompt" do
      let(:custom_prompt_path) { "custom/security.md" }
      let(:custom_content) { "Custom security review prompt." }

      before do
        allow(combiner).to receive(:select_system_prompt).with(focus, custom_prompt_path).and_return(custom_prompt_path)
        allow(file_reader_mock).to receive(:read).with(custom_prompt_path).and_return(
          success: true,
          content: custom_content
        )
      end

      it "uses custom system prompt when provided" do
        result = combiner.build_prompt(session, target_content, context, focus, custom_prompt_path)

        expect(result.system_prompt_path).to eq(custom_prompt_path)
      end
    end
  end

  xdescribe "#format_context_section" do # Skipping - method doesn't exist in implementation
    let(:context) do
      CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "auto",
        documents: [
          {
            type: "blueprint",
            path: "docs/blueprint.md",
            content: "# Project Blueprint\nThis is the blueprint."
          },
          {
            type: "architecture",
            path: "docs/architecture.md",
            content: "# Architecture\nSystem design details."
          }
        ],
        loaded_at: Time.now
      )
    end

    it "formats context documents into readable sections" do
      formatted = combiner.format_context_section(context)

      expect(formatted).to include("Project Context")
      expect(formatted).to include("blueprint")
      expect(formatted).to include("architecture")
      expect(formatted).to include("This is the blueprint")
      expect(formatted).to include("System design details")
    end

    it "handles empty context" do
      empty_context = CodingAgentTools::Models::Code::ReviewContext.new(
        mode: "none",
        documents: [],
        loaded_at: Time.now
      )

      formatted = combiner.format_context_section(empty_context)

      expect(formatted).to include("No project context")
    end
  end

  describe "private methods" do
    describe "#select_system_prompt" do
      it "returns custom prompt path when provided" do
        custom_path = "custom/prompt.md"
        result = combiner.send(:select_system_prompt, "security", custom_path)
        expect(result).to eq(custom_path)
      end

      it "selects focus-specific prompt when available" do
        result = combiner.send(:select_system_prompt, "code", nil)
        expect(result).to include("review-code")
      end

      it "falls back to default prompt when focus-specific not found" do
        result = combiner.send(:select_system_prompt, "unknown-focus", nil)
        expect(result).to include("review-code")
      end
    end

    xdescribe "#build_user_content" do # Skipping - method doesn't exist in implementation
      let(:session) do
        CodingAgentTools::Models::Code::ReviewSession.new(
          session_id: "test-session",
          session_name: "test-session",
          timestamp: Time.now.iso8601,
          directory_path: "/tmp/test-session",
          target: "lib/test.rb",
          context_mode: "diff",
          focus: "code"
        )
      end

      it "combines session, content, and context into user prompt" do
        user_content = combiner.send(:build_user_content, session, "code content", "context section")

        expect(user_content).to include("test-session")
        expect(user_content).to include("lib/test.rb")
        expect(user_content).to include("code content")
        expect(user_content).to include("context section")
      end
    end
  end
end
