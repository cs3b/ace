# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Molecules::Claude::CommandMetadataInferrer do
  subject(:inferrer) { described_class.new }

  describe '#infer' do
    context 'with nil or empty input' do
      it 'returns empty hash for nil' do
        expect(inferrer.infer(nil)).to eq({})
      end

      it 'returns empty hash for empty string' do
        expect(inferrer.infer('')).to eq({})
      end
    end

    context 'description generation' do
      it 'capitalizes words and replaces hyphens' do
        result = inferrer.infer('create-new-feature')
        expect(result[:description]).to eq('Create New Feature')
      end

      it 'handles abbreviations correctly' do
        result = inferrer.infer('create-api-docs')
        expect(result[:description]).to eq('Create API Docs')
      end

      it 'handles ADR abbreviation' do
        result = inferrer.infer('create-adr')
        expect(result[:description]).to eq('Create ADR')
      end
    end

    context 'allowed tools inference' do
      it 'infers git tools for git workflows' do
        result = inferrer.infer('git-commit')
        expect(result[:allowed_tools]).to eq('Bash(git *), Read, Write')
      end

      it 'infers git tools for commit workflow' do
        result = inferrer.infer('commit')
        expect(result[:allowed_tools]).to eq('Bash(git *), Read, Write')
      end

      it 'infers task tools for task workflows' do
        result = inferrer.infer('work-on-task')
        expect(result[:allowed_tools]).to eq('Read, Write, TodoWrite, Bash(task-manager *)')
      end

      it 'infers creation tools for create workflows' do
        result = inferrer.infer('create-adr')
        expect(result[:allowed_tools]).to eq('Read, Write, Grep, Glob')
      end

      it 'infers test tools for test creation' do
        result = inferrer.infer('create-test-cases')
        expect(result[:allowed_tools]).to eq('Read, Write, Bash(bundle exec rspec), Grep')
      end

      it 'infers testing tools for test workflows' do
        result = inferrer.infer('test-feature')
        expect(result[:allowed_tools]).to eq('Bash, Read, Grep')
      end

      it 'infers fix tools for fix workflows' do
        result = inferrer.infer('fix-tests')
        expect(result[:allowed_tools]).to eq('Read, Write, Edit, Bash(bundle exec *), Grep')
      end

      it 'infers research tools for research workflows' do
        result = inferrer.infer('research-topic')
        expect(result[:allowed_tools]).to eq('Read, Grep, Glob, WebSearch')
      end

      it 'infers synthesis tools for synthesis workflows' do
        result = inferrer.infer('synthesize-reflection-notes')
        expect(result[:allowed_tools]).to eq('Read, Write, Grep, TodoWrite')
      end

      it 'infers context tools for load-project-context' do
        result = inferrer.infer('load-project-context')
        expect(result[:allowed_tools]).to eq('Read, LS')
      end

      it 'infers release tools for release workflows' do
        result = inferrer.infer('draft-release')
        expect(result[:allowed_tools]).to eq('Read, Write, Bash(task-manager release *), Grep')
      end

      it 'infers update tools for update-blueprint' do
        result = inferrer.infer('update-blueprint')
        expect(result[:allowed_tools]).to eq('Read, Write, Edit, Grep')
      end

      it 'infers capture tools for capture-idea' do
        result = inferrer.infer('capture-idea')
        expect(result[:allowed_tools]).to eq('Write, TodoWrite')
      end

      it 'uses default tools for unknown workflows' do
        result = inferrer.infer('unknown-workflow')
        expect(result[:allowed_tools]).to eq('Read, Write, Edit, Grep')
      end
    end

    context 'argument hint inference' do
      it 'adds task-id hint for task workflows' do
        result = inferrer.infer('work-on-task')
        expect(result[:argument_hint]).to eq('[task-id]')
      end

      it 'adds branch-name hint for rebase workflows' do
        result = inferrer.infer('rebase-against')
        expect(result[:argument_hint]).to eq('[branch-name]')
      end

      it 'adds linter-output-file hint for fix-linting-issue-from' do
        result = inferrer.infer('fix-linting-issue-from')
        expect(result[:argument_hint]).to eq('[linter-output-file]')
      end

      it 'adds version hint for release workflows' do
        result = inferrer.infer('draft-release')
        expect(result[:argument_hint]).to eq('[version]')
      end

      it 'adds idea-description hint for capture-idea' do
        result = inferrer.infer('capture-idea')
        expect(result[:argument_hint]).to eq('[idea-description]')
      end

      it 'adds decision-title hint for create-adr' do
        result = inferrer.infer('create-adr')
        expect(result[:argument_hint]).to eq('[decision-title]')
      end

      it 'does not add hint for workflows without parameters' do
        result = inferrer.infer('commit')
        expect(result).not_to have_key(:argument_hint)
      end
    end

    context 'model inference' do
      it 'selects opus for analysis workflows' do
        result = inferrer.infer('analyze-codebase')
        expect(result[:model]).to eq('opus')
      end

      it 'selects opus for synthesis workflows' do
        result = inferrer.infer('synthesize-results')
        expect(result[:model]).to eq('opus')
      end

      it 'selects opus for research workflows' do
        result = inferrer.infer('research-topic')
        expect(result[:model]).to eq('opus')
      end

      it 'selects sonnet for fix-tests' do
        result = inferrer.infer('fix-tests')
        expect(result[:model]).to eq('sonnet')
      end

      it 'selects sonnet for fix-linting' do
        result = inferrer.infer('fix-linting')
        expect(result[:model]).to eq('sonnet')
      end

      it 'does not specify model for simple workflows' do
        result = inferrer.infer('commit')
        expect(result).not_to have_key(:model)
      end
    end

    context 'complete metadata' do
      it 'returns full metadata for complex workflow' do
        result = inferrer.infer('work-on-task')
        
        expect(result).to eq({
          description: 'Work On Task',
          allowed_tools: 'Read, Write, TodoWrite, Bash(task-manager *)',
          argument_hint: '[task-id]'
        })
      end

      it 'returns metadata without optional fields for simple workflow' do
        result = inferrer.infer('commit')
        
        expect(result).to eq({
          description: 'Commit',
          allowed_tools: 'Bash(git *), Read, Write'
        })
      end
    end
  end
end