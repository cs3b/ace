# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/code/prompt_enhancer"

RSpec.describe CodingAgentTools::Molecules::Code::PromptEnhancer do
  let(:enhancer) { described_class.new }
  
  let(:base_prompt) do
    "You are a code reviewer. Review the following code for quality."
  end
  
  let(:context_content) do
    "Project uses Ruby 3.0 with Rails 7. Follow SOLID principles."
  end

  describe "#enhance_prompt" do
    it "enhances a prompt with context" do
      enhanced = enhancer.enhance_prompt(base_prompt, context_content)
      
      expect(enhanced).to include(base_prompt)
      expect(enhanced).to include("## Project Context")
      expect(enhanced).to include(context_content)
    end

    it "returns base prompt when no context provided" do
      enhanced = enhancer.enhance_prompt(base_prompt, nil)
      expect(enhanced).to eq(base_prompt)
      
      enhanced = enhancer.enhance_prompt(base_prompt, "")
      expect(enhanced).to eq(base_prompt)
    end

    it "uses default prompt when none provided" do
      enhanced = enhancer.enhance_prompt(nil, context_content)
      
      expect(enhanced).to include("# Code Review")
      expect(enhanced).to include("## Project Context")
      expect(enhanced).to include(context_content)
    end

    it "properly formats the enhanced prompt" do
      enhanced = enhancer.enhance_prompt(base_prompt, context_content)
      
      lines = enhanced.split("\n")
      expect(lines).to include("## Project Context")
      expect(lines).to include("The following project-specific information provides background context for this review:")
    end

    it "handles prompts already ending with newlines" do
      prompt_with_newlines = "#{base_prompt}\n\n"
      enhanced = enhancer.enhance_prompt(prompt_with_newlines, context_content)
      
      # Should not have excessive newlines
      expect(enhanced).not_to include("\n\n\n\n")
    end
  end

  describe "#extract_context" do
    it "extracts context from an enhanced prompt" do
      enhanced = enhancer.enhance_prompt(base_prompt, context_content)
      extracted = enhancer.extract_context(enhanced)
      
      expect(extracted).to include(context_content)
    end

    it "returns nil when no context section present" do
      extracted = enhancer.extract_context(base_prompt)
      expect(extracted).to be_nil
    end

    it "returns nil for nil input" do
      extracted = enhancer.extract_context(nil)
      expect(extracted).to be_nil
    end
  end

  describe "#enhanced?" do
    it "returns true for enhanced prompts" do
      enhanced = enhancer.enhance_prompt(base_prompt, context_content)
      expect(enhancer.enhanced?(enhanced)).to be true
    end

    it "returns false for non-enhanced prompts" do
      expect(enhancer.enhanced?(base_prompt)).to be false
    end

    it "returns false for nil" do
      expect(enhancer.enhanced?(nil)).to be false
    end
  end

  describe "#default_prompt" do
    it "returns the default system prompt" do
      default = enhancer.default_prompt
      
      expect(default).to include("# Code Review")
      expect(default).to include("You are a senior software engineer")
      expect(default).to include("## Review Guidelines")
      expect(default).to include("## Output Format")
    end
  end
end