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

      it 'lists custom commands' do
        expect { lister.list }.to output(/Custom Commands \(2\)/).to_stdout
        expect { lister.list }.to output(/commit/).to_stdout
        expect { lister.list }.to output(/draft-tasks/).to_stdout
      end

      it 'shows verbose information when requested' do
        expect { lister.list(verbose: true) }.to output(/Path:/).to_stdout
        expect { lister.list(verbose: true) }.to output(/Modified:/).to_stdout
        expect { lister.list(verbose: true) }.to output(/Size:/).to_stdout
      end
    end

    context 'with generated commands' do
      before do
        generated_dir = test_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated'
        File.write(generated_dir / 'capture-idea.md', 'Capture idea command')
        File.write(generated_dir / 'create-adr.md', 'Create ADR command')
      end

      it 'lists generated commands' do
        expect { lister.list }.to output(/Generated Commands \(2\)/).to_stdout
        expect { lister.list }.to output(/capture-idea/).to_stdout
        expect { lister.list }.to output(/create-adr/).to_stdout
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

      it 'identifies missing commands' do
        expect { lister.list }.to output(/Missing Commands \(2\)/).to_stdout
        expect { lister.list }.to output(/fix-linting-issue-from/).to_stdout
        expect { lister.list }.to output(/rebase-against/).to_stdout
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
        expect(output).to include('Custom Commands')
        expect(output).not_to include('Generated Commands')
        expect(output).not_to include('Missing Commands')
      end

      it 'filters by generated type' do
        output = capture_stdout { lister.list(type: 'generated') }
        expect(output).not_to include('Custom Commands')
        expect(output).to include('Generated Commands')
        expect(output).not_to include('Missing Commands')
      end

      it 'filters by missing type' do
        output = capture_stdout { lister.list(type: 'missing') }
        expect(output).not_to include('Custom Commands')
        expect(output).not_to include('Generated Commands')
        expect(output).to include('Missing Commands')
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
        
        expect(json).to have_key('custom')
        expect(json).to have_key('generated')
        expect(json).to have_key('missing')
        
        expect(json['custom']).to be_an(Array)
        expect(json['custom'].first).to have_key('name')
        expect(json['custom'].first).to have_key('path')
        expect(json['custom'].first).to have_key('modified')
        expect(json['custom'].first).to have_key('size')
      end
    end

    context 'with empty directories' do
      it 'handles missing directories gracefully' do
        expect { lister.list }.to output(/Custom Commands \(0\)/).to_stdout
        expect { lister.list }.to output(/Generated Commands \(0\)/).to_stdout
        expect { lister.list }.to output(/Summary: 0 commands available, 0 missing/).to_stdout
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