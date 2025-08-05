# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/organisms/claude_validator'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Organisms::ClaudeValidator do
  let(:test_dir) { Dir.mktmpdir }
  let(:validator) { described_class.new(test_dir) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{test_dir}/dev-handbook/workflow-instructions")
    FileUtils.mkdir_p("#{test_dir}/dev-handbook/.integrations/claude/commands/_custom")
    FileUtils.mkdir_p("#{test_dir}/dev-handbook/.integrations/claude/commands/_generated")
    FileUtils.mkdir_p("#{test_dir}/.claude/commands")
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe '#initialize' do
    it 'initializes with correct paths and finds project root' do
      expect(validator.project_root.to_s).to eq(test_dir)
      expect(validator.validation_results).to eq({
        workflow_count: 0,
        command_count: 0,
        missing: [],
        outdated: [],
        duplicates: [],
        orphaned: [],
        valid: []
      })
    end

    context 'when project root is not provided' do
      it 'finds project root by looking for .claude/commands directory' do
        Dir.chdir(test_dir) do
          validator = described_class.new
          expect(validator.project_root.realpath.to_s).to eq(Pathname.new(test_dir).realpath.to_s)
        end
      end
    end
  end

  describe '#validate' do
    context 'with no workflows or commands' do
      it 'returns successful validation with zero counts' do
        result = validator.validate

        expect(result.success).to be true
        expect(result.data[:workflow_count]).to eq(0)
        expect(result.data[:command_count]).to eq(0)
      end
    end

    context 'with missing commands' do
      before do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test-workflow.wf.md", '# Test workflow')
      end

      it 'detects missing commands' do
        result = validator.validate

        expect(result.success).to be false
        expect(result.data[:workflow_count]).to eq(1)
        expect(result.data[:missing]).to eq(['test-workflow'])
      end
    end

    context 'with outdated commands' do
      before do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test-workflow.wf.md", '# Test workflow')
        File.write("#{test_dir}/.claude/commands/test-workflow.md", 'old content')
      end

      it 'detects outdated commands' do
        result = validator.validate

        expect(result.success).to be false
        expect(result.data[:outdated].size).to eq(1)
        expect(result.data[:outdated].first[:command]).to eq('test-workflow.md')
        expect(result.data[:outdated].first[:reason]).to eq('Content hash mismatch')
      end
    end

    context 'with duplicate commands' do
      before do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test-workflow.wf.md", '# Test workflow')
        File.write("#{test_dir}/dev-handbook/.integrations/claude/commands/_custom/test-workflow.md", 'content')
        File.write("#{test_dir}/.claude/commands/test-workflow.md", 'content')
      end

      it 'detects duplicate commands' do
        result = validator.validate

        expect(result.success).to be false
        expect(result.data[:duplicates].size).to eq(1)
        expect(result.data[:duplicates].first[:name]).to eq('test-workflow')
        expect(result.data[:duplicates].first[:locations]).to include(
          'dev-handbook/.integrations/claude/commands/_custom',
          '.claude/commands'
        )
      end
    end

    context 'with orphaned commands' do
      before do
        File.write("#{test_dir}/.claude/commands/orphaned-command.md", 'content')
      end

      it 'detects orphaned commands' do
        result = validator.validate

        expect(result.data[:orphaned].size).to eq(1)
        expect(result.data[:orphaned].first[:name]).to eq('orphaned-command')
        expect(result.data[:orphaned].first[:location]).to eq('.claude/commands/')
      end

      it 'ignores multi-task commands' do
        # Don't include the orphaned-command.md from the previous test
        FileUtils.rm_f("#{test_dir}/.claude/commands/orphaned-command.md")
        File.write("#{test_dir}/.claude/commands/commit.md", 'content')
        result = validator.validate

        expect(result.data[:orphaned]).to be_empty
      end
    end

    context 'with valid commands' do
      before do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test-workflow.wf.md", '# Test workflow')
        expected_content = <<~CONTENT
          read whole file and follow @dev-handbook/workflow-instructions/test-workflow.wf.md

          read and run @.claude/commands/commit.md
        CONTENT
        File.write("#{test_dir}/.claude/commands/test-workflow.md", expected_content)
      end

      it 'identifies valid commands' do
        result = validator.validate

        expect(result.success).to be true
        expect(result.data[:valid]).to eq(['test-workflow'])
      end
    end

    context 'with specific check option' do
      before do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test1.wf.md", '# Test 1')
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test2.wf.md", '# Test 2')
      end

      it 'runs only the specified check' do
        result = validator.validate(check: 'missing')

        expect(result.data[:missing]).to eq(['test1', 'test2'])
        expect(result.data[:outdated]).to be_empty
        expect(result.data[:duplicates]).to be_empty
      end

      it 'raises error for unknown check type' do
        expect { validator.validate(check: 'invalid') }.to raise_error(ArgumentError, /Unknown check type/)
      end
    end

    context 'with specific workflow option' do
      before do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/test-workflow.wf.md", '# Test workflow')
      end

      it 'validates only the specified workflow' do
        result = validator.validate(workflow: 'test-workflow')

        expect(result.data[:missing]).to eq(['test-workflow'])
      end

      it 'raises error for non-existent workflow' do
        expect { validator.validate(workflow: 'non-existent') }.to raise_error(ArgumentError, /Workflow not found/)
      end
    end

    context 'with custom command templates' do
      it 'uses custom template for commit command' do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/commit.wf.md", '# Commit workflow')
        expected_content = <<~CONTENT
          Read the entire file: @dev-handbook/workflow-instructions/commit.wf.md

          Follow the instructions exactly, including creating the git commit with the specific format shown.
        CONTENT
        File.write("#{test_dir}/.claude/commands/commit.md", expected_content)

        result = validator.validate

        expect(result.success).to be true
        expect(result.data[:valid]).to include('commit')
      end

      it 'uses custom template for load-project-context command' do
        File.write("#{test_dir}/dev-handbook/workflow-instructions/load-project-context.wf.md", '# Load context')
        expected_content = <<~CONTENT
          Read the entire file: @dev-handbook/workflow-instructions/load-project-context.wf.md

          Load all the context documents listed in the workflow.
        CONTENT
        File.write("#{test_dir}/.claude/commands/load-project-context.md", expected_content)

        result = validator.validate

        expect(result.success).to be true
        expect(result.data[:valid]).to include('load-project-context')
      end
    end
  end

  describe '#has_issues?' do
    it 'returns false when no issues' do
      expect(validator.has_issues?).to be false
    end

    it 'returns true when missing commands exist' do
      File.write("#{test_dir}/dev-handbook/workflow-instructions/test.wf.md", '# Test')
      validator.validate
      expect(validator.has_issues?).to be true
    end
  end

  describe 'ValidationResult' do
    let(:data) do
      {
        workflow_count: 5,
        command_count: 4,
        missing: ['test1', 'test2'],
        outdated: [{ command: 'test3.md', reason: 'Content hash mismatch' }],
        duplicates: [],
        orphaned: [],
        valid: ['test4', 'test5']
      }
    end

    let(:result) { described_class::ValidationResult.new(success: false, data: data) }

    describe '#to_text' do
      it 'generates human-readable text report' do
        output = result.to_text

        expect(output).to include('Workflows found: 5')
        expect(output).to include('Commands found: 4')
        expect(output).to include('✗ Missing commands:')
        expect(output).to include('  - test1.wf.md (no command found)')
        expect(output).to include('⚠ Outdated commands')
        expect(output).to include('Summary: 2 missing, 1 outdated')
      end
    end

    describe '#to_json' do
      it 'generates JSON report' do
        result = described_class::ValidationResult.new(success: false, data: data, format: 'json')
        json_output = JSON.parse(result.to_s)

        expect(json_output['success']).to be false
        expect(json_output['validation_status']).to eq('failed')
        expect(json_output['summary']['missing_count']).to eq(2)
        expect(json_output['details']['missing']).to eq(['test1', 'test2'])
      end
    end
  end

  describe 'content hash comparison' do
    it 'detects content changes using SHA256' do
      File.write("#{test_dir}/dev-handbook/workflow-instructions/test.wf.md", '# Test')

      # Write command with slightly different content (extra space)
      wrong_content = <<~CONTENT
        read whole file and follow @dev-handbook/workflow-instructions/test.wf.md 

        read and run @.claude/commands/commit.md
      CONTENT
      File.write("#{test_dir}/.claude/commands/test.md", wrong_content)

      result = validator.validate

      expect(result.data[:outdated].size).to eq(1)
      expect(result.data[:outdated].first[:reason]).to eq('Content hash mismatch')
    end
  end
end
