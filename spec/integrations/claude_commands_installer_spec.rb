# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'coding_agent_tools/integrations/claude_commands_installer'

RSpec.describe CodingAgentTools::Integrations::ClaudeCommandsInstaller do
  let(:test_dir) { Dir.mktmpdir('claude_installer_test') }
  let(:installer) { described_class.new(test_dir) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(File.join(test_dir, '.claude', 'commands'))
    FileUtils.mkdir_p(File.join(test_dir, 'dev-handbook', 'workflow-instructions'))
    FileUtils.mkdir_p(File.join(test_dir, 'dev-handbook', '.integrations', 'claude', 'commands'))
  end

  after do
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
  end

  describe '#initialize' do
    it 'sets the project root' do
      expect(installer.project_root.to_s).to eq(test_dir)
    end

    it 'initializes stats counter' do
      expect(installer.stats).to eq({ created: 0, skipped: 0, updated: 0, errors: [] })
    end
  end

  describe '#run' do
    context 'with workflow files' do
      before do
        # Create test workflow files
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'test-workflow.wf.md'),
          '# Test Workflow'
        )
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'another-workflow.wf.md'),
          '# Another Workflow'
        )
      end

      it 'creates command files from workflows' do
        expect { installer.run }.to output(/Creating command files/).to_stdout
        
        command_file = File.join(test_dir, '.claude', 'commands', 'test-workflow.md')
        expect(File.exist?(command_file)).to be true
        
        content = File.read(command_file)
        expect(content).to include('@dev-handbook/workflow-instructions/test-workflow.wf.md')
        expect(content).to include('@.claude/commands/commit.md')
      end

      it 'updates commands.json' do
        installer.run
        
        json_file = File.join(test_dir, '.claude', 'commands', 'commands.json')
        expect(File.exist?(json_file)).to be true
        
        commands = JSON.parse(File.read(json_file))
        expect(commands).to have_key('/test-workflow')
        expect(commands).to have_key('/another-workflow')
      end

      it 'reports correct statistics' do
        expect { installer.run }.to output(/2 created/).to_stdout
      end
    end

    context 'with existing command files' do
      before do
        # Create existing command file
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'existing.wf.md'),
          '# Existing Workflow'
        )
        File.write(
          File.join(test_dir, '.claude', 'commands', 'existing.md'),
          '# Existing command'
        )
      end

      it 'skips existing commands' do
        expect { installer.run }.to output(/Skipped: existing.md/).to_stdout
        
        # Check that file wasn't overwritten
        content = File.read(File.join(test_dir, '.claude', 'commands', 'existing.md'))
        expect(content).to eq('# Existing command')
      end

      it 'reports skipped files in statistics' do
        expect { installer.run }.to output(/1 skipped/).to_stdout
      end
    end

    context 'with custom multi-task commands' do
      before do
        # Create custom command
        File.write(
          File.join(test_dir, 'dev-handbook', '.integrations', 'claude', 'commands', 'custom-task.md'),
          '# Custom multi-task command'
        )
      end

      it 'copies custom commands' do
        expect { installer.run }.to output(/Copying custom multi-task commands/).to_stdout
        
        custom_file = File.join(test_dir, '.claude', 'commands', 'custom-task.md')
        expect(File.exist?(custom_file)).to be true
        expect(File.read(custom_file)).to eq('# Custom multi-task command')
      end
    end

    context 'with existing commands.json' do
      before do
        existing_json = { '/existing-command' => { 'some' => 'config' } }
        File.write(
          File.join(test_dir, '.claude', 'commands', 'commands.json'),
          JSON.pretty_generate(existing_json)
        )
        
        # Add a workflow file
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'new-workflow.wf.md'),
          '# New Workflow'
        )
      end

      it 'creates backup before modification' do
        installer.run
        
        backup_file = File.join(test_dir, '.claude', 'commands', 'commands.json.backup')
        expect(File.exist?(backup_file)).to be true
      end

      it 'preserves existing commands in JSON' do
        installer.run
        
        json_file = File.join(test_dir, '.claude', 'commands', 'commands.json')
        commands = JSON.parse(File.read(json_file))
        
        expect(commands).to have_key('/existing-command')
        expect(commands['/existing-command']).to eq({ 'some' => 'config' })
      end

      it 'adds new commands to JSON' do
        installer.run
        
        json_file = File.join(test_dir, '.claude', 'commands', 'commands.json')
        commands = JSON.parse(File.read(json_file))
        
        expect(commands).to have_key('/new-workflow')
      end
    end

    context 'with custom templates' do
      before do
        # Create workflow files that have custom templates
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'commit.wf.md'),
          '# Commit Workflow'
        )
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'load-project-context.wf.md'),
          '# Load Project Context'
        )
      end

      it 'uses custom template for commit workflow' do
        installer.run
        
        commit_file = File.join(test_dir, '.claude', 'commands', 'commit.md')
        content = File.read(commit_file)
        
        expect(content).to include('Follow the instructions exactly')
        expect(content).not_to include('@.claude/commands/commit.md')
      end

      it 'uses custom template for load-project-context workflow' do
        installer.run
        
        context_file = File.join(test_dir, '.claude', 'commands', 'load-project-context.md')
        content = File.read(context_file)
        
        expect(content).to include('Load all the context documents')
      end
    end

    context 'without workflow directory' do
      before do
        FileUtils.rm_rf(File.join(test_dir, 'dev-handbook'))
      end

      it 'handles missing workflow directory gracefully' do
        expect { installer.run }.to output(/Warning: Workflow instructions directory not found/).to_stdout
        expect { installer.run }.not_to raise_error
      end
    end
  end

  describe 'error handling' do
    context 'with permission errors' do
      before do
        # Create a command file without write permission
        command_dir = File.join(test_dir, '.claude', 'commands')
        File.write(File.join(command_dir, 'readonly.md'), 'test')
        FileUtils.chmod(0444, File.join(command_dir, 'readonly.md'))
        
        # Create corresponding workflow
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'readonly.wf.md'),
          '# Readonly Workflow'
        )
      end

      after do
        # Restore permissions for cleanup
        command_dir = File.join(test_dir, '.claude', 'commands')
        FileUtils.chmod(0644, File.join(command_dir, 'readonly.md')) rescue nil
      end

      it 'skips files with permission issues' do
        expect { installer.run }.to output(/Skipped: readonly.md/).to_stdout
      end
    end
  end
end