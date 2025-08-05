# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/integrations/claude_commands_installer'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Integrations::ClaudeCommandsInstaller do
  let(:test_dir) { Dir.mktmpdir }
  let(:project_root) { Pathname.new(test_dir) }
  let(:installer) { described_class.new(project_root, options) }
  let(:options) { {} }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom')
    FileUtils.mkdir_p(project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated')
    FileUtils.mkdir_p(project_root / 'dev-handbook' / '.integrations' / 'claude' / 'agents')
    FileUtils.mkdir_p(project_root / 'dev-handbook' / 'workflow-instructions')
    FileUtils.mkdir_p(project_root / '.claude' / 'commands')
    FileUtils.mkdir_p(project_root / '.claude' / 'agents')
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#run' do
    context 'with custom and generated commands' do
      before do
        # Create test files
        (project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom' / 'test-custom.md').write("# Custom Command")
        (project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_generated' / 'test-generated.md').write("# Generated Command")
        (project_root / 'dev-handbook' / '.integrations' / 'claude' / 'agents' / 'test-agent.md').write("# Test Agent")
      end

      it 'copies commands from both directories' do
        result = installer.run
        expect(result.success).to be true
        expect((project_root / '.claude' / 'commands' / 'test-custom.md').exist?).to be true
        expect((project_root / '.claude' / 'commands' / 'test-generated.md').exist?).to be true
      end

      it 'copies agents' do
        result = installer.run
        expect(result.success).to be true
        expect((project_root / '.claude' / 'agents' / 'test-agent.md').exist?).to be true
      end

      it 'adds metadata to copied files' do
        result = installer.run
        content = (project_root / '.claude' / 'commands' / 'test-custom.md').read
        expect(content).to match(/^---\nlast_modified: .+\n---/)
      end
    end

    context 'with --force option' do
      let(:options) { { force: true } }

      before do
        # Create existing file
        (project_root / '.claude' / 'commands' / 'test-custom.md').write("Old content")
        (project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom' / 'test-custom.md').write("New content")
      end

      it 'overwrites existing files' do
        result = installer.run
        content = (project_root / '.claude' / 'commands' / 'test-custom.md').read
        expect(content).to match(/New content/)
        expect(content).to match(/last_modified:/)
      end
    end

    context 'with --backup option' do
      let(:options) { { backup: true } }

      before do
        # Create existing .claude directory with content
        (project_root / '.claude' / 'commands' / 'existing.md').write("Existing file")
      end

      it 'creates backup of existing installation' do
        result = installer.run
        backup_dirs = project_root.glob('.claude.backup.*')
        expect(backup_dirs).not_to be_empty
        expect((backup_dirs.first / 'commands' / 'existing.md').exist?).to be true
      end
    end

    context 'with --dry-run option' do
      let(:options) { { dry_run: true } }

      before do
        (project_root / 'dev-handbook' / '.integrations' / 'claude' / 'commands' / '_custom' / 'test.md').write("Test")
      end

      it 'does not create any files' do
        result = installer.run
        expect((project_root / '.claude' / 'commands' / 'test.md').exist?).to be false
        expect(result.stats[:created]).to eq(1) # Still counts in stats
      end
    end

    context 'with missing source directories' do
      before do
        FileUtils.rm_rf(project_root / 'dev-handbook')
      end

      it 'exits with error' do
        expect { installer.run }.to raise_error(SystemExit)
      end
    end
  end

  describe '#inject_metadata' do
    it 'adds metadata to content without frontmatter' do
      content = "# My Command\nContent here"
      result = installer.send(:inject_metadata, content, { 'last_modified' => '2025-08-04' })
      expect(result).to match(/^---\nlast_modified: .+\n---\n\n# My Command/)
    end

    it 'updates existing frontmatter' do
      content = "---\nname: test\n---\n# Content"
      result = installer.send(:inject_metadata, content, { 'last_modified' => '2025-08-04' })
      expect(result).to match(/^---\nname: test\nlast_modified: .+\n---/)
    end
  end

  describe '#validate_source!' do
    context 'with custom source path' do
      let(:options) { { source: project_root / 'custom' } }

      it 'validates custom source directory' do
        FileUtils.mkdir_p(project_root / 'custom' / 'commands' / '_custom')
        expect { installer.send(:validate_source!) }.not_to raise_error
      end
    end
  end
end