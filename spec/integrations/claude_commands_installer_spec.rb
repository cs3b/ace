# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'coding_agent_tools/integrations/claude_commands_installer'

RSpec.describe CodingAgentTools::Integrations::ClaudeCommandsInstaller do
  let(:test_dir) { Dir.mktmpdir('claude_installer_test') }
  let(:installer) { described_class.new(test_dir) }
  let(:installer_with_options) { described_class.new(test_dir, dry_run: true, verbose: true) }

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
      expect(installer.stats).to eq({
        created: 0,
        skipped: 0,
        updated: 0,
        errors: [],
        custom_commands: 0,
        generated_commands: 0,
        workflow_commands: 0,
        agents: 0
      })
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
        result = nil
        expect { result = installer.run }.to output(/Creating command files/).to_stdout

        expect(result).to be_a(CodingAgentTools::Integrations::ClaudeCommandsInstaller::Result)
        expect(result.success).to be true
        expect(result.exit_code).to eq(0)

        command_file = File.join(test_dir, '.claude', 'commands', 'test-workflow.md')
        expect(File.exist?(command_file)).to be true

        content = File.read(command_file)
        expect(content).to include('@dev-handbook/workflow-instructions/test-workflow.wf.md')
        expect(content).to include('@.claude/commands/commit.md')
      end

      # Commands.json functionality has been removed
      # it 'updates commands.json' do
      #   result = installer.run
      #   expect(result.success).to be true
      #
      #   json_file = File.join(test_dir, '.claude', 'commands', 'commands.json')
      #   expect(File.exist?(json_file)).to be true
      #
      #   commands = JSON.parse(File.read(json_file))
      #   expect(commands).to have_key('/test-workflow')
      #   expect(commands).to have_key('/another-workflow')
      # end

      it 'reports correct statistics' do
        result = nil
        expect { result = installer.run }.to output(/Commands: 2/).to_stdout
        expect(result.stats[:created]).to eq(2)
        expect(result.stats[:workflow_commands]).to eq(2)
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
        result = nil
        expect { result = installer.run }.to output(/Skipped: existing.md/).to_stdout
        expect(result.success).to be true

        # Check that file wasn't overwritten
        content = File.read(File.join(test_dir, '.claude', 'commands', 'existing.md'))
        expect(content).to eq('# Existing command')
      end

      it 'reports skipped files in statistics' do
        result = nil
        expect { result = installer.run }.to output(/Skipped: existing.md/).to_stdout
        expect(result.stats[:skipped]).to eq(1)
      end
    end

    context 'with custom multi-task commands' do
      before do
        # Create custom command in new structure
        FileUtils.mkdir_p(File.join(test_dir, 'dev-handbook', '.integrations', 'claude', 'commands', '_custom'))
        File.write(
          File.join(test_dir, 'dev-handbook', '.integrations', 'claude', 'commands', '_custom', 'custom-task.md'),
          '# Custom multi-task command'
        )
      end

      it 'copies custom commands' do
        expect { installer.run }.to output(/Copying commands/).to_stdout

        custom_file = File.join(test_dir, '.claude', 'commands', 'custom-task.md')
        expect(File.exist?(custom_file)).to be true
        # Check that metadata was injected
        content = File.read(custom_file)
        expect(content).to include('last_modified:')
        expect(content).to include('# Custom multi-task command')
      end
    end

    # Commands.json functionality has been removed
    # context 'with existing commands.json' do
    #   ...test code removed...
    # end

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
        result = nil
        expect { result = installer.run }.to output(/Warning: Workflow instructions directory not found/).to_stdout
        expect { installer.run }.not_to raise_error
        expect(result.success).to be true
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

    context 'with dry_run option' do
      before do
        File.write(
          File.join(test_dir, 'dev-handbook', 'workflow-instructions', 'test.wf.md'),
          '# Test Workflow'
        )
      end

      it 'does not create files in dry run mode' do
        installer_dry = described_class.new(test_dir, dry_run: true)
        result = nil
        expect { result = installer_dry.run }.to output(/DRY RUN/).to_stdout

        command_file = File.join(test_dir, '.claude', 'commands', 'test.md')
        expect(File.exist?(command_file)).to be false
        expect(result.success).to be true
      end

      it 'shows what would be created' do
        installer_dry = described_class.new(test_dir, dry_run: true)
        expect { installer_dry.run }.to output(/DRY RUN/).to_stdout
        expect { installer_dry.run }.to output(/Created: test.md/).to_stdout
      end
    end

    context 'with verbose option' do
      it 'shows detailed output' do
        installer_verbose = described_class.new(test_dir, verbose: true)
        expect { installer_verbose.run }.to output(/Project root:/).to_stdout
      end
    end
  end
end
