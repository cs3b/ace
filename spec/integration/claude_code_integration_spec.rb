# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "json"

RSpec.describe "Claude Code Integration", :vcr do
  let(:llm_query_path) { File.expand_path("../../exe/llm-query", __dir__) }
  let(:llm_models_path) { File.expand_path("../../exe/llm-models", __dir__) }

  describe "llm-query with cc provider" do
    context "basic functionality" do
      it "executes with cc:opus model" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:opus "Say hello in 3 words" 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
        expect(output).not_to include("Unknown provider")
        expect(output).not_to include("error")
      end

      it "executes with cc:sonnet model" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "Say hello in 3 words" 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
      end

      it "executes with cc:haiku model" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:haiku "Say hello in 3 words" 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
      end

      it "uses default model with cc provider only" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc "Say hello in 3 words" 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
      end
    end

    context "with options" do
      it "supports JSON format output" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "Return a JSON object with name and age" --format json 2>&1`
        expect($?).to be_success
        
        # Should be parseable JSON
        expect { JSON.parse(output) }.not_to raise_error
      end

      it "supports system instruction" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "Hello" --system "Always respond in French" 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
        # Claude should respond in French
        expect(output.downcase).to match(/bonjour|salut|bonsoir/)
      end

      it "supports temperature setting" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "Generate a random word" --temperature 1.0 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
      end

      it "supports max tokens limit" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "Tell me a story" --max-tokens 50 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
        # Output should be relatively short due to token limit
        expect(output.split.size).to be < 100
      end
    end

    context "with file input/output" do
      let(:temp_prompt) { Tempfile.new(["prompt", ".txt"]) }
      let(:temp_output) { Tempfile.new(["output", ".txt"]) }
      let(:temp_system) { Tempfile.new(["system", ".txt"]) }

      before do
        temp_prompt.write("What is 2 + 2?")
        temp_prompt.close
        
        temp_system.write("You are a math tutor")
        temp_system.close
      end

      after do
        temp_prompt.unlink
        temp_output.unlink
        temp_system.unlink
      end

      it "reads prompt from file" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet #{temp_prompt.path} 2>&1`
        expect($?).to be_success
        expect(output).to include("4")
      end

      it "writes output to file" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        `#{llm_query_path} cc:sonnet "What is 2 + 2?" --output #{temp_output.path} 2>&1`
        expect($?).to be_success
        
        content = File.read(temp_output.path)
        expect(content).to include("4")
      end

      it "reads system instruction from file" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "What is 2 + 2?" --system #{temp_system.path} 2>&1`
        expect($?).to be_success
        expect(output).not_to be_empty
      end
    end

    context "error handling" do
      it "handles missing Claude CLI gracefully" do
        # Mock the which command to simulate missing Claude
        allow_any_instance_of(CodingAgentTools::Organisms::ClaudeCodeClient)
          .to receive(:system).with("which claude > /dev/null 2>&1").and_return(false)
        
        output = `#{llm_query_path} cc:sonnet "test" 2>&1`
        expect(output).to include("Claude CLI not found")
        expect(output).to include("npm install -g @anthropic-ai/claude-cli")
      end

      it "handles invalid model names" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:invalid-model "test" 2>&1`
        # Should still attempt but Claude CLI will handle the invalid model
        expect(output).not_to include("Unknown provider")
      end

      it "handles empty prompts" do
        skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
        
        output = `#{llm_query_path} cc:sonnet "" 2>&1`
        expect(output).to include("error")
      end
    end
  end

  describe "llm-models with cc provider" do
    it "lists Claude Code models" do
      output = `#{llm_models_path} --provider cc 2>&1`
      expect($?).to be_success
      expect(output).to include("opus")
      expect(output).to include("sonnet")
      expect(output).to include("haiku")
      expect(output).to include("200000") # Context size
    end

    it "includes cc in all providers list" do
      output = `#{llm_models_path} 2>&1`
      expect($?).to be_success
      expect(output).to include("cc")
    end
  end

  describe "cost tracking" do
    it "tracks Claude Code usage" do
      skip "Claude CLI required for integration test" unless system("which claude > /dev/null 2>&1")
      
      # Make a query
      `#{llm_query_path} cc:sonnet "Hello" 2>&1`
      
      # Check usage report
      output = `#{File.expand_path("../../exe/llm-usage-report", __dir__)} --provider cc 2>&1`
      expect($?).to be_success
      # Should show some usage data (or indicate no data if first run)
      expect(output).not_to be_empty
    end
  end
end