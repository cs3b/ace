# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Atoms::Claude::WorkflowScanner do
  let(:temp_dir) { Pathname.new(Dir.mktmpdir) }
  let(:workflow_dir) { temp_dir / 'workflow-instructions' }

  before do
    workflow_dir.mkpath
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '.scan' do
    context 'when workflow directory exists' do
      before do
        # Create test workflow files
        (workflow_dir / 'create-adr.wf.md').write('test content')
        (workflow_dir / 'commit.wf.md').write('test content')
        (workflow_dir / 'update-blueprint.wf.md').write('test content')
        # Create non-workflow file to ensure filtering
        (workflow_dir / 'README.md').write('not a workflow')
      end

      it 'returns all workflow names without pattern' do
        result = described_class.scan(workflow_dir)
        expect(result).to eq(['commit', 'create-adr', 'update-blueprint'])
      end

      it 'returns matching workflows with glob pattern' do
        result = described_class.scan(workflow_dir, 'create-*')
        expect(result).to eq(['create-adr'])
      end

      it 'returns specific workflow when pattern is exact name' do
        result = described_class.scan(workflow_dir, 'commit')
        expect(result).to eq(['commit'])
      end

      it 'returns empty array when specific workflow not found' do
        result = described_class.scan(workflow_dir, 'non-existent')
        expect(result).to eq([])
      end

      it 'returns empty array with non-matching glob pattern' do
        result = described_class.scan(workflow_dir, 'fix-*')
        expect(result).to eq([])
      end
    end

    context 'when workflow directory does not exist' do
      it 'returns empty array' do
        non_existent = temp_dir / 'non-existent'
        result = described_class.scan(non_existent)
        expect(result).to eq([])
      end
    end

    context 'when workflow directory is actually a file' do
      before do
        workflow_dir.rmdir
        workflow_dir.write('not a directory')
      end

      it 'returns empty array' do
        result = described_class.scan(workflow_dir)
        expect(result).to eq([])
      end
    end
  end
end
