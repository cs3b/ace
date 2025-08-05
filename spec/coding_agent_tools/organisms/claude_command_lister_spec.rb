# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/organisms/claude_command_lister'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Organisms::ClaudeCommandLister do
  let(:test_root) { Pathname.new(Dir.mktmpdir) }
  let(:lister) { described_class.new(test_root) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom')
    FileUtils.mkdir_p(test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated')
    FileUtils.mkdir_p(test_root / 'dev-handbook' / 'workflow-instructions')
    FileUtils.mkdir_p(test_root / '.claude' / 'commands')
  end

  after do
    FileUtils.rm_rf(test_root)
  end

  describe '#list' do
    context 'with custom commands' do
      before do
        custom_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
        File.write(custom_dir / 'commit.md', 'Commit command')
        File.write(custom_dir / 'draft-tasks.md', 'Draft tasks command')
      end

      it 'lists custom commands in table format' do
        output = capture_stdout { lister.list }
        expect(output).to include('Claude Commands Overview')
        expect(output).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
        expect(output).to include('commit')
        expect(output).to include('draft-tasks')
        expect(output).to include('custom')
      end

      it 'shows verbose information when requested' do
        output = capture_stdout { lister.list(verbose: true) }
        expect(output).to include('Custom Commands (2):')
        expect(output).to include('Path:')
        expect(output).to include('Modified:')
        expect(output).to include('Size:')
      end
    end

    context 'with generated commands' do
      before do
        generated_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
        File.write(generated_dir / 'capture-idea.md', 'Capture idea command')
        File.write(generated_dir / 'create-adr.md', 'Create ADR command')
      end

      it 'lists generated commands in table format' do
        output = capture_stdout { lister.list }
        expect(output).to include('Claude Commands Overview')
        expect(output).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
        expect(output).to include('capture-idea')
        expect(output).to include('create-adr')
        expect(output).to include('generated')
      end
    end

    context 'with missing commands' do
      before do
        # Create workflows without corresponding commands
        workflows_dir = test_root / 'dev-handbook' / 'workflow-instructions'
        File.write(workflows_dir / 'fix-linting-issue-from.wf.md', 'Workflow content')
        File.write(workflows_dir / 'rebase-against.wf.md', 'Workflow content')

        # Create some installed commands but not for these workflows
        installed_dir = test_root / '.claude' / 'commands'
        File.write(installed_dir / 'commit.md', 'Installed command')
      end

      it 'identifies missing commands in table format' do
        output = capture_stdout { lister.list }
        expect(output).to include('Claude Commands Overview')
        expect(output).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
        expect(output).to include('fix-linting-issue-from')
        expect(output).to include('rebase-against')
        expect(output).to include('missing')
        expect(output).to match(/Summary:.*2 missing/)
      end
    end

    context 'with type filtering' do
      before do
        # Set up commands of each type
        custom_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
        File.write(custom_dir / 'commit.md', 'Commit command')

        generated_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
        File.write(generated_dir / 'capture-idea.md', 'Capture idea command')

        workflows_dir = test_root / 'dev-handbook' / 'workflow-instructions'
        File.write(workflows_dir / 'missing-workflow.wf.md', 'Workflow content')
      end

      it 'filters by custom type' do
        output = capture_stdout { lister.list(type: 'custom') }
        expect(output).to include('Claude Commands Overview')
        expect(output).to include('commit')
        expect(output).to include('custom')
        expect(output).not_to include('capture-idea')
        expect(output).not_to include('missing-workflow')
      end

      it 'filters by generated type' do
        output = capture_stdout { lister.list(type: 'generated') }
        expect(output).to include('Claude Commands Overview')
        expect(output).to include('capture-idea')
        expect(output).to include('generated')
        expect(output).not_to include('commit')
        expect(output).not_to include('missing-workflow')
      end

      it 'filters by missing type' do
        output = capture_stdout { lister.list(type: 'missing') }
        expect(output).to include('Claude Commands Overview')
        expect(output).to include('missing-workflow')
        expect(output).to include('missing')
        expect(output).not_to include('commit')
        expect(output).not_to include('capture-idea')
      end
    end

    context 'with JSON output format' do
      before do
        custom_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
        File.write(custom_dir / 'commit.md', 'Commit command')

        workflows_dir = test_root / 'dev-handbook' / 'workflow-instructions'
        File.write(workflows_dir / 'missing-workflow.wf.md', 'Workflow content')
      end

      it 'outputs valid JSON' do
        output = capture_stdout { lister.list(format: 'json') }
        json = JSON.parse(output)

        expect(json).to have_key('commands')
        expect(json).to have_key('summary')

        expect(json['commands']).to be_an(Array)
        expect(json['commands'].first).to have_key('name')
        expect(json['commands'].first).to have_key('type')
        expect(json['commands'].first).to have_key('installed')
        expect(json['commands'].first).to have_key('valid')

        expect(json['summary']).to have_key('installed')
        expect(json['summary']).to have_key('missing')
        expect(json['summary']).to have_key('total')
      end
    end

    context 'with empty directories' do
      it 'handles missing directories gracefully' do
        output = capture_stdout { lister.list }
        expect(output).to include('Claude Commands Overview')
        expect(output).to match(/Installed\s+\|\s+Type\s+\|\s+Valid\s+\|\s+Command Name/)
        expect(output).to match(/Summary: 0 commands installed, 0 missing/)
      end
    end

    context 'with installed commands' do
      before do
        # Create source commands
        custom_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom'
        File.write(custom_dir / 'commit.md', 'Commit command')
        File.write(custom_dir / 'draft-tasks.md', 'Draft tasks command')

        generated_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
        File.write(generated_dir / 'capture-idea.md', 'Capture idea command')

        # Install some commands in subdirectories
        installed_custom = test_root / '.claude' / 'commands' / '_custom'
        FileUtils.mkdir_p(installed_custom)
        File.write(installed_custom / 'commit.md', 'Installed commit')

        installed_generated = test_root / '.claude' / 'commands' / '_generated'
        FileUtils.mkdir_p(installed_generated)
        File.write(installed_generated / 'capture-idea.md', 'Installed capture-idea')
      end

      it 'shows installed status correctly' do
        output = capture_stdout { lister.list }
        lines = output.split("\n")

        # Find the commit line - should show as installed
        commit_line = lines.find { |l| l.include?('commit') && l.include?('custom') }
        expect(commit_line).to include('✓')

        # Find the draft-tasks line - should show as not installed
        draft_line = lines.find { |l| l.include?('draft-tasks') && l.include?('custom') }
        expect(draft_line).to include('✗')

        # Check summary
        expect(output).to match(/Summary: 2 commands installed/)
      end

      it 'detects only commands that exist in dev-handbook' do
        # Commands in root directory that don't exist in dev-handbook are ignored
        # because scan_installed_command_names only returns names, not validation status
        File.write(test_root / '.claude' / 'commands' / 'other-command.md', 'Other command')

        output = capture_stdout { lister.list }
        # Still only 2 installed because other-command doesn't exist in dev-handbook
        expect(output).to match(/Summary: 2 commands installed/)
      end
    end
  end

  describe '#build_inventory' do
    it 'builds complete inventory of commands' do
      # This is a private method but we can test it indirectly through #list
      expect { lister.list }.not_to raise_error
    end
  end

  private

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
