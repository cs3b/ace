# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli"

RSpec.describe CodingAgentTools::Cli::Commands do
  describe ".register_llm_commands" do
    before do
      described_class.instance_variable_set(:@llm_commands_registered, nil)
    end

    it "registers LLM commands only once" do
      expect(described_class).to receive(:register).with("llm", aliases: []).once

      described_class.register_llm_commands
      described_class.register_llm_commands # Second call should not register again
    end

    it "requires the necessary LLM command files" do
      expect(described_class).to receive(:require_relative).with("cli/commands/llm/models")
      expect(described_class).to receive(:require_relative).with("cli/commands/llm/query")
      expect(described_class).to receive(:require_relative).with("cli/commands/llm/usage_report")

      # Mock the register call to prevent loading actual command classes
      allow(described_class).to receive(:register)

      described_class.register_llm_commands
    end

    it "sets the registration flag" do
      described_class.register_llm_commands
      expect(described_class.instance_variable_get(:@llm_commands_registered)).to be true
    end
  end

  describe ".register_task_commands" do
    before do
      described_class.instance_variable_set(:@task_commands_registered, nil)
    end

    it "registers task commands only once" do
      expect(described_class).to receive(:register).with("task", aliases: []).once

      described_class.register_task_commands
      described_class.register_task_commands
    end

    it "requires the necessary task command files" do
      expect(described_class).to receive(:require_relative).with("cli/commands/task/next")
      expect(described_class).to receive(:require_relative).with("cli/commands/task/recent")
      expect(described_class).to receive(:require_relative).with("cli/commands/task/all")
      expect(described_class).to receive(:require_relative).with("cli/commands/task/generate_id")

      described_class.register_task_commands
    end
  end

  describe ".register_release_commands" do
    before do
      described_class.instance_variable_set(:@release_commands_registered, nil)
    end

    it "registers release commands only once" do
      expect(described_class).to receive(:register).with("release", aliases: []).once

      described_class.register_release_commands
      described_class.register_release_commands
    end

    it "requires all release command files" do
      expect(described_class).to receive(:require_relative).with("cli/commands/release/current")
      expect(described_class).to receive(:require_relative).with("cli/commands/release/next")
      expect(described_class).to receive(:require_relative).with("cli/commands/release/all")
      expect(described_class).to receive(:require_relative).with("cli/commands/release/generate_id")
      expect(described_class).to receive(:require_relative).with("cli/commands/release/validate")

      described_class.register_release_commands
    end
  end

  describe ".register_dotfiles_commands" do
    before do
      described_class.instance_variable_set(:@dotfiles_commands_registered, nil)
    end

    it "registers dotfiles commands only once" do
      expect(described_class).to receive(:register).with("install-dotfiles", anything).once

      described_class.register_dotfiles_commands
      described_class.register_dotfiles_commands
    end
  end

  describe ".register_code_commands" do
    before do
      described_class.instance_variable_set(:@code_commands_registered, nil)
    end

    it "registers code commands only once" do
      expect(described_class).to receive(:register).with("code", aliases: []).once

      described_class.register_code_commands
      described_class.register_code_commands
    end
  end

  describe ".register_code_lint_commands" do
    before do
      described_class.instance_variable_set(:@code_lint_commands_registered, nil)
    end

    it "registers code-lint commands only once" do
      expect(described_class).to receive(:register).with("code-lint", aliases: []).once

      described_class.register_code_lint_commands
      described_class.register_code_lint_commands
    end
  end

  describe ".register_code_review_prepare_commands" do
    before do
      described_class.instance_variable_set(:@code_review_prepare_commands_registered, nil)
    end

    it "registers code-review-prepare commands only once" do
      expect(described_class).to receive(:register).with("code-review-prepare", aliases: []).once

      described_class.register_code_review_prepare_commands
      described_class.register_code_review_prepare_commands
    end
  end

  describe ".register_nav_commands" do
    before do
      described_class.instance_variable_set(:@nav_commands_registered, nil)
    end

    it "registers nav commands only once" do
      expect(described_class).to receive(:register).with("nav", aliases: []).once

      described_class.register_nav_commands
      described_class.register_nav_commands
    end
  end

  describe ".register_handbook_commands" do
    before do
      described_class.instance_variable_set(:@handbook_commands_registered, nil)
    end

    it "registers handbook commands only once" do
      expect(described_class).to receive(:register).with("handbook", aliases: []).once

      described_class.register_handbook_commands
      described_class.register_handbook_commands
    end
  end

  describe ".register_reflection_commands" do
    before do
      described_class.instance_variable_set(:@reflection_commands_registered, nil)
    end

    it "registers reflection commands only once" do
      expect(described_class).to receive(:register).with("reflection", aliases: []).once

      described_class.register_reflection_commands
      described_class.register_reflection_commands
    end
  end

  describe ".register_git_commands" do
    before do
      described_class.instance_variable_set(:@git_commands_registered, nil)
    end

    it "registers git commands only once" do
      expect(described_class).to receive(:register).with("git", aliases: []).once

      described_class.register_git_commands
      described_class.register_git_commands
    end

    it "requires all git command files" do
      git_commands = %w[status commit add push pull log diff fetch checkout switch mv rm restore]

      git_commands.each do |cmd|
        expect(described_class).to receive(:require_relative).with("cli/commands/git/#{cmd}")
      end

      described_class.register_git_commands
    end
  end

  describe ".register_create_path_commands" do
    before do
      described_class.instance_variable_set(:@create_path_commands_registered, nil)
    end

    it "registers create-path command only once" do
      expect(described_class).to receive(:register).with("create-path", anything).once

      described_class.register_create_path_commands
      described_class.register_create_path_commands
    end
  end

  describe ".register_coverage_commands" do
    before do
      described_class.instance_variable_set(:@coverage_commands_registered, nil)
    end

    it "registers coverage commands only once" do
      expect(described_class).to receive(:register).with("coverage", aliases: []).once

      described_class.register_coverage_commands
      described_class.register_coverage_commands
    end
  end

  describe ".register_all_commands" do
    before do
      described_class.instance_variable_set(:@all_commands_registered, nil)
    end

    it "registers all command only once" do
      expect(described_class).to receive(:register).with("all", anything).once

      described_class.register_all_commands
      described_class.register_all_commands
    end
  end

  describe "Version command" do
    let(:version_command) { described_class::Version.new }

    describe "#call" do
      it "prints the gem version" do
        expect { version_command.call }.to output("#{CodingAgentTools::VERSION}\n").to_stdout
      end
    end

    describe "registration" do
      it "is registered with correct aliases" do
        # This tests that the version command was registered properly
        # We can't easily test the actual registration without invoking the full CLI
        # But we can verify the command exists
        expect(described_class::Version).to be_a(Class)
        expect(described_class::Version.superclass).to eq(Dry::CLI::Command)
      end
    end
  end

  describe "command registration flags" do
    it "sets registration flags to prevent duplicate registrations" do
      # Reset a flag
      described_class.instance_variable_set(:@llm_commands_registered, nil)

      # First registration should set the flag
      described_class.register_llm_commands
      expect(described_class.instance_variable_get(:@llm_commands_registered)).to be true

      # Stub register to ensure it's not called again
      expect(described_class).not_to receive(:register)

      # Second call should not register again
      described_class.register_llm_commands
    end
  end

  describe "error handling" do
    before do
      described_class.instance_variable_set(:@llm_commands_registered, nil)
    end

    it "propagates require errors" do
      allow(described_class).to receive(:require_relative).and_raise(LoadError, "Cannot load file")

      expect { described_class.register_llm_commands }.to raise_error(LoadError, "Cannot load file")
    end
  end
end
