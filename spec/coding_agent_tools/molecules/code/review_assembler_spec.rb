# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/code/review_assembler"

RSpec.describe CodingAgentTools::Molecules::Code::ReviewAssembler do
  let(:assembler) { described_class.new }
  
  let(:enhanced_prompt) do
    "You are a code reviewer.\n\n## Project Context\n\nProject uses Ruby 3.0."
  end
  
  let(:subject_content) do
    "diff --git a/file.rb b/file.rb\n+puts 'Hello'"
  end

  describe "#assemble" do
    it "assembles prompt and subject with proper structure" do
      result = assembler.assemble(enhanced_prompt, subject_content)
      
      expect(result).to include(enhanced_prompt)
      expect(result).to include("---")
      expect(result).to include("# Content for Review")
      expect(result).to include(subject_content)
    end

    it "raises error when enhanced_prompt is nil" do
      expect {
        assembler.assemble(nil, subject_content)
      }.to raise_error(ArgumentError, "Enhanced prompt cannot be nil")
    end

    it "raises error when subject_content is nil" do
      expect {
        assembler.assemble(enhanced_prompt, nil)
      }.to raise_error(ArgumentError, "Subject content cannot be nil")
    end

    it "properly formats the assembled prompt" do
      result = assembler.assemble(enhanced_prompt, subject_content)
      
      parts = result.split("\n---\n")
      expect(parts.length).to eq(2)
      
      expect(parts[0]).to include(enhanced_prompt.strip)
      expect(parts[1]).to include("# Content for Review")
      expect(parts[1]).to include(subject_content)
    end
  end

  describe "#disassemble" do
    it "disassembles a properly assembled prompt" do
      original = assembler.assemble(enhanced_prompt, subject_content)
      components = assembler.disassemble(original)
      
      expect(components[:enhanced_prompt]).to eq(enhanced_prompt.strip)
      expect(components[:subject]).to eq(subject_content.strip)
    end

    it "handles prompts without clear separator" do
      components = assembler.disassemble(enhanced_prompt)
      
      expect(components[:enhanced_prompt]).to eq(enhanced_prompt.strip)
      expect(components[:subject]).to be_nil
    end

    it "removes Content for Review header from subject" do
      original = assembler.assemble(enhanced_prompt, subject_content)
      components = assembler.disassemble(original)
      
      expect(components[:subject]).not_to include("# Content for Review")
      expect(components[:subject]).to eq(subject_content.strip)
    end

    it "handles nil input" do
      components = assembler.disassemble(nil)
      
      expect(components[:enhanced_prompt]).to be_nil
      expect(components[:subject]).to be_nil
    end
  end

  describe "#valid_assembly?" do
    it "returns true for properly assembled prompts" do
      assembled = assembler.assemble(enhanced_prompt, subject_content)
      expect(assembler.valid_assembly?(assembled)).to be true
    end

    it "returns false for non-assembled prompts" do
      expect(assembler.valid_assembly?(enhanced_prompt)).to be false
    end

    it "returns false for prompts missing content header" do
      partial = "#{enhanced_prompt}\n---\n\n#{subject_content}"
      expect(assembler.valid_assembly?(partial)).to be false
    end

    it "returns false for nil" do
      expect(assembler.valid_assembly?(nil)).to be false
    end
  end

  describe "#prompt_stats" do
    it "returns statistics for assembled prompt" do
      assembled = assembler.assemble(enhanced_prompt, subject_content)
      stats = assembler.prompt_stats(assembled)
      
      expect(stats[:total_length]).to be > 0
      expect(stats[:total_lines]).to be > 0
      expect(stats[:enhanced_prompt_length]).to eq(enhanced_prompt.strip.length)
      expect(stats[:subject_length]).to eq(subject_content.strip.length)
      expect(stats[:has_context]).to be true
    end

    it "detects absence of context" do
      simple_prompt = "Review this code"
      assembled = assembler.assemble(simple_prompt, subject_content)
      stats = assembler.prompt_stats(assembled)
      
      expect(stats[:has_context]).to be false
    end

    it "returns nil for nil input" do
      stats = assembler.prompt_stats(nil)
      expect(stats).to be_nil
    end
  end
end