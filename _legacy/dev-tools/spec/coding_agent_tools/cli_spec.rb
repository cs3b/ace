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
      expect(described_class).to receive(:require_relative).with("cli/commands/task/list")
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
      git_commands = ["status", "commit", "add", "push", "pull", "log", "diff", "fetch", "checkout", "switch", "mv", "rm", "restore", "tag"]

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

  describe ".call" do
    let(:cli_instance) { Dry::CLI.new(described_class) }

    before do
      # Reset all registration flags
      %i[@llm_commands_registered @task_commands_registered @release_commands_registered
        @dotfiles_commands_registered @code_commands_registered @code_lint_commands_registered
        @nav_commands_registered @handbook_commands_registered @reflection_commands_registered 
        @git_commands_registered @create_path_commands_registered @coverage_commands_registered 
        @all_commands_registered].each do |flag|
        described_class.instance_variable_set(flag, nil)
      end
    end

    it "registers all command groups when CLI is invoked" do
      # Track which methods are called
      calls = []

      allow(described_class).to receive(:register_llm_commands) { calls << :llm }
      allow(described_class).to receive(:register_task_commands) { calls << :task }
      allow(described_class).to receive(:register_release_commands) { calls << :release }
      allow(described_class).to receive(:register_dotfiles_commands) { calls << :dotfiles }
      allow(described_class).to receive(:register_code_commands) { calls << :code }
      allow(described_class).to receive(:register_code_lint_commands) { calls << :code_lint }
      allow(described_class).to receive(:register_nav_commands) { calls << :nav }
      allow(described_class).to receive(:register_handbook_commands) { calls << :handbook }
      allow(described_class).to receive(:register_reflection_commands) { calls << :reflection }
      allow(described_class).to receive(:register_git_commands) { calls << :git }
      allow(described_class).to receive(:register_create_path_commands) { calls << :create_path }
      allow(described_class).to receive(:register_coverage_commands) { calls << :coverage }
      allow(described_class).to receive(:register_all_commands) { calls << :all }

      # Call with a valid command to trigger registration (Dry::CLI#call takes no args, uses ARGV)
      allow(ARGV).to receive(:dup).and_return(["version"])
      cli_instance.call

      # Verify all registrations were called
      expect(calls).to eq([:llm, :task, :release, :dotfiles, :code, :code_lint,
        :nav, :handbook, :reflection, :git, :create_path, :coverage, :all])
    end

    it "registers commands only once on multiple calls" do
      # Count registration calls
      registration_count = 0
      allow(described_class).to receive(:register_llm_commands) { registration_count += 1 }

      # Stub other registrations
      %i[register_task_commands register_release_commands
        register_dotfiles_commands register_code_commands register_code_lint_commands
        register_nav_commands register_handbook_commands register_reflection_commands 
        register_git_commands register_create_path_commands register_coverage_commands 
        register_all_commands].each do |method|
        allow(described_class).to receive(method)
      end

      # Call multiple times
      allow(ARGV).to receive(:dup).and_return(["version"])
      3.times { cli_instance.call }

      # Should only register once
      expect(registration_count).to eq(1)
    end

    it "handles command execution after registration" do
      # Stub all registrations
      %i[register_llm_commands register_task_commands register_release_commands
        register_dotfiles_commands register_code_commands register_code_lint_commands
        register_nav_commands register_handbook_commands register_reflection_commands 
        register_git_commands register_create_path_commands register_coverage_commands 
        register_all_commands].each do |method|
        allow(described_class).to receive(method)
      end

      # Test with version command
      allow(ARGV).to receive(:dup).and_return(["version"])
      expect { cli_instance.call }.to output(/\d+\.\d+\.\d+/).to_stdout
    end
  end

  describe "complete command registration details" do
    describe ".register_git_commands" do
      before do
        described_class.instance_variable_set(:@git_commands_registered, nil)
      end

      it "requires all 14 git command files" do
        # Test the actual registration block
        allow(described_class).to receive(:register).and_yield(double("prefix").tap do |prefix|
          expect(prefix).to receive(:register).with("status", anything)
          expect(prefix).to receive(:register).with("commit", anything)
          expect(prefix).to receive(:register).with("add", anything)
          expect(prefix).to receive(:register).with("push", anything)
          expect(prefix).to receive(:register).with("pull", anything)
          expect(prefix).to receive(:register).with("log", anything)
          expect(prefix).to receive(:register).with("diff", anything)
          expect(prefix).to receive(:register).with("fetch", anything)
          expect(prefix).to receive(:register).with("checkout", anything)
          expect(prefix).to receive(:register).with("switch", anything)
          expect(prefix).to receive(:register).with("mv", anything)
          expect(prefix).to receive(:register).with("rm", anything)
          expect(prefix).to receive(:register).with("restore", anything)
          expect(prefix).to receive(:register).with("tag", anything)
        end)

        described_class.register_git_commands
      end
    end

    describe ".register_task_commands" do
      before do
        described_class.instance_variable_set(:@task_commands_registered, nil)
      end

      it "registers task commands with all alias" do
        allow(described_class).to receive(:register).and_yield(double("prefix").tap do |prefix|
          expect(prefix).to receive(:register).with("next", anything)
          expect(prefix).to receive(:register).with("recent", anything)
          expect(prefix).to receive(:register).with("list", anything)
          expect(prefix).to receive(:register).with("all", anything) # backwards compatibility alias
          expect(prefix).to receive(:register).with("generate-id", anything)
        end)

        described_class.register_task_commands
      end
    end

    describe ".register_code_commands" do
      before do
        described_class.instance_variable_set(:@code_commands_registered, nil)
      end

      it "requires all code command files" do
        expect(described_class).to receive(:require_relative).with("cli/commands/code/review")
        expect(described_class).to receive(:require_relative).with("cli/commands/code/review_synthesize")
        expect(described_class).to receive(:require_relative).with("cli/commands/code/lint")

        allow(described_class).to receive(:register)

        described_class.register_code_commands
      end
    end

    describe ".register_code_lint_commands" do
      before do
        described_class.instance_variable_set(:@code_lint_commands_registered, nil)
      end

      it "requires all code-lint command files" do
        expect(described_class).to receive(:require_relative).with("cli/commands/code_lint/all")
        expect(described_class).to receive(:require_relative).with("cli/commands/code_lint/ruby")
        expect(described_class).to receive(:require_relative).with("cli/commands/code_lint/markdown")
        expect(described_class).to receive(:require_relative).with("cli/commands/code_lint/docs_dependencies")

        allow(described_class).to receive(:register)

        described_class.register_code_lint_commands
      end
    end

    describe ".register_nav_commands" do
      before do
        described_class.instance_variable_set(:@nav_commands_registered, nil)
      end

      it "requires all nav command files" do
        expect(described_class).to receive(:require_relative).with("cli/commands/nav")
        expect(described_class).to receive(:require_relative).with("cli/commands/nav/path")
        expect(described_class).to receive(:require_relative).with("cli/commands/nav/tree")
        expect(described_class).to receive(:require_relative).with("cli/commands/nav/ls")

        allow(described_class).to receive(:register)

        described_class.register_nav_commands
      end
    end

    describe ".register_handbook_commands" do
      before do
        described_class.instance_variable_set(:@handbook_commands_registered, nil)
      end

      it "requires all handbook command files including claude subcommands" do
        expect(described_class).to receive(:require_relative).with("cli/commands/handbook/sync_templates")
        expect(described_class).to receive(:require_relative).with("cli/commands/handbook/claude/generate_commands")
        expect(described_class).to receive(:require_relative).with("cli/commands/handbook/claude/integrate")
        expect(described_class).to receive(:require_relative).with("cli/commands/handbook/claude/validate")
        expect(described_class).to receive(:require_relative).with("cli/commands/handbook/claude/list")

        allow(described_class).to receive(:register)

        described_class.register_handbook_commands
      end

      it "registers claude as a proper subcommand namespace" do
        allow(described_class).to receive(:require_relative)

        claude_prefix = double("claude_prefix")
        expect(claude_prefix).to receive(:register).with("generate-commands", anything)
        expect(claude_prefix).to receive(:register).with("integrate", anything)
        expect(claude_prefix).to receive(:register).with("validate", anything)
        expect(claude_prefix).to receive(:register).with("list", anything)

        handbook_prefix = double("handbook_prefix")
        expect(handbook_prefix).to receive(:register).with("sync-templates", anything)
        expect(handbook_prefix).to receive(:register).with("claude", aliases: []).and_yield(claude_prefix)

        allow(described_class).to receive(:register).and_yield(handbook_prefix)

        described_class.register_handbook_commands
      end
    end

    describe ".register_reflection_commands" do
      before do
        described_class.instance_variable_set(:@reflection_commands_registered, nil)
      end

      it "requires reflection command files" do
        expect(described_class).to receive(:require_relative).with("cli/commands/reflection/synthesize")

        allow(described_class).to receive(:register)

        described_class.register_reflection_commands
      end
    end

    describe ".register_create_path_commands" do
      before do
        described_class.instance_variable_set(:@create_path_commands_registered, nil)
      end

      it "requires create-path command file" do
        expect(described_class).to receive(:require_relative).with("cli/create_path_command")

        allow(described_class).to receive(:register)

        described_class.register_create_path_commands
      end
    end

    describe ".register_coverage_commands" do
      before do
        described_class.instance_variable_set(:@coverage_commands_registered, nil)
      end

      it "requires coverage command files" do
        expect(described_class).to receive(:require_relative).with("cli/commands/coverage/analyze")

        allow(described_class).to receive(:register)

        described_class.register_coverage_commands
      end
    end

    describe ".register_all_commands" do
      before do
        described_class.instance_variable_set(:@all_commands_registered, nil)
      end

      it "requires all command file" do
        expect(described_class).to receive(:require_relative).with("cli/commands/all")

        allow(described_class).to receive(:register)

        described_class.register_all_commands
      end
    end
  end
end
