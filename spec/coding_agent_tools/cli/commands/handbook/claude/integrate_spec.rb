# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/handbook/claude/integrate"
require "coding_agent_tools/integrations/claude_commands_installer"

RSpec.describe CodingAgentTools::Cli::Commands::Handbook::Claude::Integrate do
  subject { described_class.new }

  let(:installer_mock) { instance_double(CodingAgentTools::Integrations::ClaudeCommandsInstaller) }
  let(:result) { CodingAgentTools::Integrations::ClaudeCommandsInstaller::Result.new(success: true, exit_code: 0, stats: {}) }

  before do
    allow(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
      .to receive(:new).and_return(installer_mock)
    allow(installer_mock).to receive(:run).and_return(result)
  end

  describe "#call" do
    it "calls the ClaudeCommandsInstaller with default options" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: false, verbose: false, backup: false, force: false, source: nil)
      expect(installer_mock).to receive(:run)

      subject.call
    end

    it "passes dry_run option to installer" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: true, verbose: false, backup: false, force: false, source: nil)

      subject.call(dry_run: true)
    end

    it "passes verbose option to installer" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: false, verbose: true, backup: false, force: false, source: nil)

      subject.call(verbose: true)
    end

    it "passes both options to installer" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: true, verbose: true, backup: false, force: false, source: nil)

      subject.call(dry_run: true, verbose: true)
    end

    it "passes backup option to installer" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: false, verbose: false, backup: true, force: false, source: nil)

      subject.call(backup: true)
    end

    it "passes force option to installer" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: false, verbose: false, backup: false, force: true, source: nil)

      subject.call(force: true)
    end

    it "passes source option to installer" do
      expect(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).with(nil, dry_run: false, verbose: false, backup: false, force: false, source: "/custom/path")

      subject.call(source: "/custom/path")
    end

    context "when installer returns non-zero exit code" do
      let(:result) { CodingAgentTools::Integrations::ClaudeCommandsInstaller::Result.new(success: false, exit_code: 1, stats: {}) }

      it "exits with the same exit code" do
        expect(subject).to receive(:exit).with(1)
        subject.call
      end
    end

    context "when installer returns zero exit code" do
      it "does not call exit" do
        expect(subject).not_to receive(:exit)
        subject.call
      end
    end
  end
end
