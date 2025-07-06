# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::BinstubGenerator do
  describe ".generate_shell_binstub" do
    context "when generating a basic shell binstub" do
      it "creates proper shell script with executable and command" do
        alias_name = "tn"
        alias_config = {
          "description" => "Get next task",
          "executable" => "task-manager",
          "command" => "next",
          "type" => "shell",
          "args_processing" => "pass_through"
        }

        result = described_class.generate_shell_binstub(alias_name, alias_config)

        expect(result).to include("#!/bin/sh")
        expect(result).to include("# Get next task")
        expect(result).to include("set -e")
        expect(result).to include('ORIGINAL_DIR="$(pwd)"')
        expect(result).to include("trap 'cd \"$ORIGINAL_DIR\"' EXIT")
        expect(result).to include('cd "$(dirname "$0")/../dev-tools"')
        expect(result).to include("./exe/task-manager next \"$@\"")
        expect(result).to include("echo \"INFO: Get next task from dev-tools directory: $(pwd)\"")
      end
    end

    context "when generating binstub without command" do
      it "creates shell script with only executable" do
        alias_name = "llm"
        alias_config = {
          "description" => "Query LLM providers",
          "executable" => "llm-query",
          "type" => "shell",
          "args_processing" => "pass_through"
        }

        result = described_class.generate_shell_binstub(alias_name, alias_config)

        expect(result).to include("#!/bin/sh")
        expect(result).to include("# Query LLM providers")
        expect(result).to include("./exe/llm-query \"$@\"")
        expect(result).not_to include("next")
      end
    end

    context "when generating binstub with special characters in description" do
      it "handles descriptions safely" do
        alias_name = "test"
        alias_config = {
          "description" => "Test with \"quotes\" and 'apostrophes'",
          "executable" => "test-tool",
          "type" => "shell"
        }

        result = described_class.generate_shell_binstub(alias_name, alias_config)

        expect(result).to include("# Test with \"quotes\" and 'apostrophes'")
        expect(result).to include("./exe/test-tool \"$@\"")
      end
    end
  end

  describe ".generate_all_binstubs" do
    context "when generating from valid configuration" do
      it "creates all binstubs from config" do
        config = {
          "version" => "1.0",
          "aliases" => {
            "tn" => {
              "description" => "Get next task",
              "executable" => "task-manager",
              "command" => "next",
              "type" => "shell"
            },
            "llm" => {
              "description" => "Query LLM",
              "executable" => "llm-query",
              "type" => "shell"
            }
          }
        }

        result = described_class.generate_all_binstubs(config)

        expect(result).to have_key("tn")
        expect(result).to have_key("llm")
        expect(result["tn"]).to include("# Get next task")
        expect(result["tn"]).to include("./exe/task-manager next \"$@\"")
        expect(result["llm"]).to include("# Query LLM")
        expect(result["llm"]).to include("./exe/llm-query \"$@\"")
      end
    end

    context "when config has no aliases" do
      it "returns empty hash" do
        config = {"version" => "1.0"}

        result = described_class.generate_all_binstubs(config)

        expect(result).to eq({})
      end
    end

    context "when config is completely empty" do
      it "returns empty hash" do
        config = {}

        result = described_class.generate_all_binstubs(config)

        expect(result).to eq({})
      end
    end

    context "when alias has unsupported type" do
      it "raises an error" do
        config = {
          "aliases" => {
            "test" => {
              "description" => "Test",
              "executable" => "test-tool",
              "type" => "unsupported"
            }
          }
        }

        expect {
          described_class.generate_all_binstubs(config)
        }.to raise_error(CodingAgentTools::Error, /Unsupported binstub type: unsupported/)
      end
    end
  end
end