# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/handbook/claude/generate_commands"

RSpec.describe CodingAgentTools::Cli::Commands::Handbook::Claude::GenerateCommands do
  let(:command) { described_class.new }
  let(:generator) { instance_double(CodingAgentTools::Organisms::ClaudeCommandGenerator) }
  let(:result) { CodingAgentTools::Organisms::ClaudeCommandGenerator::Result.new(success: true, stats: {}, missing_workflows: []) }

  before do
    allow(CodingAgentTools::Organisms::ClaudeCommandGenerator).to receive(:new).and_return(generator)
    allow(generator).to receive(:generate).and_return(result)
  end

  describe "#call" do
    context "with successful generation" do
      it "calls the generator with default options" do
        expect(generator).to receive(:generate).with({})
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it "passes dry_run option to generator" do
        expect(generator).to receive(:generate).with(hash_including(dry_run: true))
        expect { command.call(dry_run: true) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it "passes force option to generator" do
        expect(generator).to receive(:generate).with(hash_including(force: true))
        expect { command.call(force: true) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it "passes workflow option to generator" do
        expect(generator).to receive(:generate).with(hash_including(workflow: "test-workflow"))
        expect { command.call(workflow: "test-workflow") }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it "passes all options to generator" do
        expect(generator).to receive(:generate).with(hash_including(dry_run: true, force: true, workflow: "test-*"))
        expect { command.call(dry_run: true, force: true, workflow: "test-*") }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end
    end

    context "with failed generation" do
      let(:result) { CodingAgentTools::Organisms::ClaudeCommandGenerator::Result.new(success: false, stats: { errors: ["Some error"] }, missing_workflows: []) }

      it "exits with status 1" do
        expect { command.call }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "with exception" do
      before do
        allow(generator).to receive(:generate).and_raise(StandardError, "Something went wrong")
      end

      it "prints error message and exits with status 1" do
        expect { command.call }.to output(/Error: Something went wrong/).to_stdout
          .and raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
      end

      it "prints backtrace when DEBUG is set" do
        ENV['DEBUG'] = '1'
        expect { command.call }.to output(/Error: Something went wrong/).to_stdout
          .and raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        ENV.delete('DEBUG')
      end
    end
  end
end