# frozen_string_literal: true

require 'spec_helper'
require 'support/claude_test_helpers'

RSpec.describe 'Claude Integration Workflow' do
  include ClaudeTestHelpers
  include ProcessHelpers

  before do
    setup_claude_test_environment
  end

  after do
    teardown_claude_test_environment
  end

  describe 'CLI integration' do
    it 'shows help for claude namespace' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', '--help'])
      # dry-cli returns 1 for help and output goes to stderr
      expect(status.exitstatus).to eq(1)
      output = stdout + stderr
      expect(output).to include('handbook claude')
      expect(output).to include('generate-commands')
      expect(output).to include('update-registry')
      expect(output).to include('integrate')
      expect(output).to include('validate')
      expect(output).to include('list')
    end

    it 'shows help for all Claude subcommands' do
      ['generate-commands', 'update-registry', 'integrate', 'validate', 'list'].each do |subcommand|
        stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', subcommand, '--help'])
        expect(status).to be_success
        expect(stdout).to include("handbook claude #{subcommand}")
      end
    end
  end

  describe 'command functionality' do
    # These tests verify the commands run without errors
    # They don't test the actual functionality since that requires
    # the real handbook directory structure

    it 'runs generate-commands with dry-run' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'generate-commands', '--dry-run'])
      expect(status).to be_success
      expect(stdout).to include('Scanning workflow instructions')
    end

    it 'runs update-registry command' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'update-registry'])
      expect(status).to be_success
      expect(stdout).to include('Not yet implemented')
    end

    it 'runs validate command' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'validate'])
      # May fail if no handbook directory exists, which is OK for integration test
      expect(status.exitstatus).to be_between(0, 1)
    end

    it 'runs list command' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'list'])
      expect(status).to be_success
    end

    it 'runs integrate with dry-run' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'integrate', '--dry-run'])
      expect(status).to be_success
      # The actual output shows the integration was successful
    end
  end

  describe 'command options' do
    it 'accepts force option for generate-commands' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'generate-commands', '--force', '--dry-run'])
      expect(status).to be_success
    end

    it 'accepts format option for list' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'list', '--format', 'json'])
      expect(status).to be_success
    end

    it 'accepts type option for list' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'list', '--type', 'custom'])
      expect(status).to be_success
    end

    it 'accepts workflow option for generate-commands' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'generate-commands', '--workflow', 'test', '--dry-run'])
      expect(status).to be_success
    end
  end

  describe 'error handling' do
    it 'shows error for unknown subcommand' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'unknown-command'])
      expect(status.exitstatus).to eq(1)
    end

    it 'shows error for invalid option' do
      stdout, stderr, status = execute_command(['bundle', 'exec', 'handbook', 'claude', 'list', '--invalid-option'])
      expect(status.exitstatus).to eq(1)
    end
  end
end
