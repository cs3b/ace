# frozen_string_literal: true

require 'spec_helper'
require 'support/claude_test_helpers'

RSpec.describe 'handbook claude namespace' do
  include ClaudeTestHelpers
  include CliHelpers

  before { setup_claude_test_environment }
  after { teardown_claude_test_environment }

  describe 'handbook claude' do
    it 'displays help when called without subcommand' do
      result = execute_cli_command('handbook', ['claude'])

      # dry-cli exits with 1 when showing help for namespace commands
      expect(result.exit_code).to eq(1)
      expect(result.stdout).to include('handbook claude [SUBCOMMAND]')
      expect(result.stdout).to include('generate-commands')
      # update-registry command has been removed
      expect(result.stdout).to include('integrate')
      expect(result.stdout).to include('validate')
      expect(result.stdout).to include('list')
    end

    it 'shows available subcommands with descriptions' do
      result = execute_cli_command('handbook', ['claude'])

      expect(result.stdout).to include('Generate missing Claude commands from workflow files')
      # Update Claude commands registry line has been removed
      expect(result.stdout).to include('Install Claude Code commands to .claude/ directory')
      expect(result.stdout).to include('Validate Claude command coverage')
      expect(result.stdout).to include('List all Claude commands and their status')
    end
  end

  describe 'handbook claude --help' do
    it 'displays the same help as without arguments' do
      result_no_args = execute_cli_command('handbook', ['claude'])
      result_with_help = execute_cli_command('handbook', ['claude', '--help'])

      expect(result_with_help.stdout).to eq(result_no_args.stdout)
      expect(result_with_help.exit_code).to eq(result_no_args.exit_code)
    end
  end

  describe 'handbook claude with invalid subcommand' do
    it 'shows error for unknown subcommand' do
      result = execute_cli_command('handbook', ['claude', 'unknown-command'])

      expect(result.exit_code).to eq(1)
      expect(result.stderr).to include('Unknown command')
    end
  end

  # Shared examples for Claude commands
  shared_examples 'claude command' do |command_name|
    it 'responds to --help' do
      result = execute_cli_command('handbook', ['claude', command_name, '--help'])

      expect(result).to be_success
      expect(result.stdout).to include("handbook claude #{command_name}")
    end

    it 'has a description' do
      result = execute_cli_command('handbook', ['claude', command_name, '--help'])

      expect(result.stdout).not_to be_empty
      expect(result.stdout).to match(/[A-Z].*[a-z]/)  # Has a sentence description
    end
  end

  describe 'subcommand help' do
    ['generate-commands', 'integrate', 'validate', 'list'].each do |subcommand|
      context "handbook claude #{subcommand}" do
        include_examples 'claude command', subcommand
      end
    end
  end
end
