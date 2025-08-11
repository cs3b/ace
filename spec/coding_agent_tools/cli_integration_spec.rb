# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli"

RSpec.describe "CodingAgentTools::Cli integration", type: :integration do
  let(:cli) { Dry::CLI.new(CodingAgentTools::Cli::Commands) }

  describe "version command" do
    it "displays the version" do
      expect {
        with_argv(["version"]) { cli.call }
      }.to output("#{CodingAgentTools::VERSION}\n").to_stdout
    end

    it "works with -v alias" do
      expect {
        with_argv(["-v"]) { cli.call }
      }.to output("#{CodingAgentTools::VERSION}\n").to_stdout
    end

    it "works with --version alias" do
      expect {
        with_argv(["--version"]) { cli.call }
      }.to output("#{CodingAgentTools::VERSION}\n").to_stdout
    end
  end

  describe "command registration" do
    it "registers all command groups on first call" do
      # Track registration state before
      registration_methods = %i[
        @llm_commands_registered @task_commands_registered @release_commands_registered
        @dotfiles_commands_registered @code_commands_registered @code_lint_commands_registered
        @code_review_prepare_commands_registered @nav_commands_registered @handbook_commands_registered
        @reflection_commands_registered @git_commands_registered @create_path_commands_registered
        @coverage_commands_registered @all_commands_registered
      ]

      # Reset all flags
      registration_methods.each do |flag|
        CodingAgentTools::Cli::Commands.instance_variable_set(flag, nil)
      end

      # Execute command to trigger registration
      with_argv(["version"]) { cli.call }

      # All flags should now be set
      registration_methods.each do |flag|
        expect(CodingAgentTools::Cli::Commands.instance_variable_get(flag)).to be true,
          "Expected #{flag} to be true after CLI call"
      end
    end

    it "does not re-register commands on subsequent calls" do
      # First call to ensure registration
      with_argv(["version"]) { cli.call }

      # Track if any registration methods are called
      registration_called = false

      %i[register_llm_commands register_task_commands register_release_commands
        register_dotfiles_commands register_code_commands register_code_lint_commands
        register_code_review_prepare_commands register_nav_commands register_handbook_commands
        register_reflection_commands register_git_commands register_create_path_commands
        register_coverage_commands register_all_commands].each do |method|
        allow(CodingAgentTools::Cli::Commands).to receive(method).and_wrap_original do |original|
          registration_called = true
          original.call
        end
      end

      # Second call should not trigger registrations
      with_argv(["version"]) { cli.call }

      expect(registration_called).to be false
    end
  end

  describe "help command" do
    it "shows available commands" do
      expect {
        with_argv([]) { cli.call }
      }.to output(/Commands:/).to_stdout
    end
  end

  private

  def with_argv(args)
    original_argv = ARGV.dup
    ARGV.clear
    ARGV.concat(args)
    yield
  ensure
    ARGV.clear
    ARGV.concat(original_argv)
  end
end
