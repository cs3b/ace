# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer do
  let(:path_validator) { instance_double(CodingAgentTools::Molecules::SecurePathValidator) }
  let(:operation_confirmer) { instance_double(CodingAgentTools::Molecules::FileOperationConfirmer) }
  let(:synchronizer) { described_class.new(path_validator: path_validator) }

  let(:template_document) do
    CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
      'dev-handbook/templates/test.template.md',
      "# Embedded Content\n\nThis is embedded content.",
      :template,
      :documents,
      1,
      5
    )
  end

  let(:guide_document) do
    CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
      'dev-handbook/guides/test.g.md',
      "# Embedded Guide\n\nThis is embedded guide content.",
      :guide,
      :documents,
      1,
      5
    )
  end

  let(:workflow_content) do
    <<~MARKDOWN
      # Workflow File

      <documents>
      <template path="dev-handbook/templates/test.template.md">
      # Embedded Content

      This is embedded content.
      </template>

      <guide path="dev-handbook/guides/test.g.md">
      # Embedded Guide

      This is embedded guide content.
      </guide>
      </documents>
    MARKDOWN
  end

  before do
    # Default to valid paths and auto-confirmation
    allow(path_validator).to receive(:validate_path).and_return(
      double(invalid?: false, error_message: nil)
    )
    # Mock successful confirmation result
    confirmation_result = CodingAgentTools::Molecules::FileOperationConfirmer::ConfirmationResult.new(true, 'Auto-confirmed', true)
    allow(operation_confirmer).to receive(:confirm_overwrite).and_return(confirmation_result)
    # Mock the operation_confirmer method on the synchronizer
    allow(synchronizer).to receive(:operation_confirmer).and_return(operation_confirmer)
  end

  describe '#synchronize_document', :security do
    context 'when content differs' do
      let(:file_content) { "# Updated Content\n\nThis is updated content." }

      before do
        allow(File).to receive(:read).with(template_document.path).and_return(file_content)
      end

      it 'uses SecurePathValidator for security validation' do
        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(path_validator).to have_received(:validate_path).with(template_document.path)
        expect(result.success?).to be true
        expect(result.updated?).to be true
      end

      it 'returns updated content when not in dry-run mode' do
        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(result.updated?).to be true
        expect(result.updated_content).to include('# Updated Content')
        expect(result.updated_content).to include('This is updated content.')
      end

      it 'confirms operation when needed' do
        confirmation_result = CodingAgentTools::Molecules::FileOperationConfirmer::ConfirmationResult.new(true, 'User confirmed', false)
        allow(operation_confirmer).to receive(:confirm_overwrite).and_return(confirmation_result)

        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(operation_confirmer).to have_received(:confirm_overwrite).with(template_document.path)
        expect(result.success?).to be true
      end

      it 'handles operation cancellation' do
        denial_result = CodingAgentTools::Molecules::FileOperationConfirmer::ConfirmationResult.new(false, 'User declined', false)
        allow(operation_confirmer).to receive(:confirm_overwrite).and_return(denial_result)

        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(result.error?).to be true
        expect(result.error_message).to include('Operation cancelled')
      end
    end

    context 'when content is up-to-date' do
      before do
        allow(File).to receive(:read).with(template_document.path).and_return(template_document.content)
      end

      it 'returns up-to-date status' do
        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(result.up_to_date?).to be true
        expect(result.updated_content).to be_nil
      end
    end

    context 'when path validation fails' do
      before do
        allow(path_validator).to receive(:validate_path).and_return(
          double(invalid?: true, error_message: 'Path traversal detected')
        )
      end

      it 'returns error result' do
        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(result.error?).to be true
        expect(result.error_message).to include('Security validation failed')
        expect(result.error_message).to include('Path traversal detected')
      end
    end

    context 'when target file is missing' do
      before do
        allow(File).to receive(:read).with(template_document.path).and_raise(Errno::ENOENT)
      end

      it 'returns error result' do
        result = synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

        expect(result.error?).to be true
        expect(result.error_message).to include('Target file not found')
      end
    end

    context 'with invalid document paths' do
      let(:invalid_template) do
        CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
          'invalid/path/template.md',
          'content',
          :template,
          :documents,
          1,
          5
        )
      end

      let(:invalid_guide) do
        CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
          'dev-handbook/templates/guide.md',
          'content',
          :guide,
          :documents,
          1,
          5
        )
      end

      it 'validates template paths' do
        result = synchronizer.synchronize_document(workflow_content, invalid_template, 'workflow.md')

        expect(result.error?).to be true
        expect(result.error_message).to include('Invalid template path')
      end

      it 'validates guide paths' do
        result = synchronizer.synchronize_document(workflow_content, invalid_guide, 'workflow.md')

        expect(result.error?).to be true
        expect(result.error_message).to include('Invalid guide path')
      end
    end
  end

  describe '#synchronize_document in dry-run mode' do
    let(:dry_run_synchronizer) do
      described_class.new(
        path_validator: path_validator,
        dry_run: true
      )
    end

    let(:file_content) { "# Updated Content\n\nThis is updated content." }

    before do
      allow(File).to receive(:read).with(template_document.path).and_return(file_content)
    end

    it 'provides diff preview without updating content' do
      result = dry_run_synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

      expect(result.updated?).to be true
      expect(result.updated_content).to be_nil
      expect(result.diff_preview).to include('📋 WOULD UPDATE')
      expect(result.diff_preview).to include('Differences found')
    end
  end

  describe '#update_embedded_document' do
    let(:new_content) { "# New Content\n\nThis is new content." }

    context 'with documents format' do
      it 'updates template content' do
        updated = synchronizer.update_embedded_document(workflow_content, template_document, new_content)

        expect(updated).to include('# New Content')
        expect(updated).to include('This is new content.')
        expect(updated).to include('<template path="dev-handbook/templates/test.template.md">')
      end

      it 'updates guide content' do
        updated = synchronizer.update_embedded_document(workflow_content, guide_document, new_content)

        expect(updated).to include('# New Content')
        expect(updated).to include('This is new content.')
        expect(updated).to include('<guide path="dev-handbook/guides/test.g.md">')
      end
    end

    context 'with legacy templates format' do
      let(:legacy_document) do
        CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
          'dev-handbook/templates/legacy.template.md',
          'Legacy content',
          :template,
          :templates,
          1,
          5
        )
      end

      let(:legacy_workflow_content) do
        <<~MARKDOWN
          <templates>
          <template path="dev-handbook/templates/legacy.template.md">
          Legacy content
          </template>
          </templates>
        MARKDOWN
      end

      it 'updates legacy template content' do
        updated = synchronizer.update_embedded_document(legacy_workflow_content, legacy_document, new_content)

        expect(updated).to include('# New Content')
        expect(updated).to include('This is new content.')
        expect(updated).to include('<template path="dev-handbook/templates/legacy.template.md">')
      end

      it 'raises error for non-template types in legacy format' do
        legacy_guide = CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
          'dev-handbook/guides/test.g.md',
          'content',
          :guide,
          :templates,
          1,
          5
        )

        expect do
          synchronizer.update_embedded_document(legacy_workflow_content, legacy_guide, new_content)
        end.to raise_error(/Legacy templates format only supports template type/)
      end
    end
  end

  describe '#generate_diff_preview' do
    let(:embedded_content) { "Line 1\nLine 2\nLine 3" }
    let(:file_content) { "Line 1\nModified Line 2\nLine 3\nNew Line 4" }

    it 'generates formatted diff preview' do
      diff = synchronizer.generate_diff_preview(embedded_content, file_content, 'test.md')

      expect(diff).to include('📋 WOULD UPDATE: test.md')
      expect(diff).to include('Differences found')
      expect(diff).to include('- Line 2: [OLD] Line 2')
      expect(diff).to include('+ Line 2: [NEW] Modified Line 2')
      expect(diff).to include('+ Line 4: [NEW] New Line 4')
    end
  end

  describe 'statistics tracking' do
    before do
      allow(File).to receive(:read).with(template_document.path).and_return('Updated content')
    end

    it 'tracks synchronization statistics' do
      synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')

      stats = synchronizer.stats
      expect(stats.files_processed).to eq 1
      expect(stats.documents_synchronized).to eq 1
      expect(stats.documents_up_to_date).to eq 0
      expect(stats.errors).to eq 0
    end

    it 'resets statistics' do
      synchronizer.synchronize_document(workflow_content, template_document, 'workflow.md')
      synchronizer.reset_stats

      stats = synchronizer.stats
      expect(stats.files_processed).to eq 0
      expect(stats.documents_synchronized).to eq 0
    end
  end

  describe 'result structures' do
    describe 'SyncResult' do
      it 'provides status checking methods' do
        updated_result = described_class::SyncResult.new(:updated, 'content', nil, nil)
        up_to_date_result = described_class::SyncResult.new(:up_to_date, nil, nil, nil)
        error_result = described_class::SyncResult.new(:error, nil, 'error', nil)

        expect(updated_result.success?).to be true
        expect(updated_result.updated?).to be true
        expect(updated_result.up_to_date?).to be false
        expect(updated_result.error?).to be false

        expect(up_to_date_result.success?).to be true
        expect(up_to_date_result.updated?).to be false
        expect(up_to_date_result.up_to_date?).to be true
        expect(up_to_date_result.error?).to be false

        expect(error_result.success?).to be false
        expect(error_result.error?).to be true
      end
    end

    describe 'SyncStats' do
      let(:stats) { described_class::SyncStats.new }

      it 'initializes with zero values' do
        expect(stats.files_processed).to eq 0
        expect(stats.documents_synchronized).to eq 0
        expect(stats.documents_up_to_date).to eq 0
        expect(stats.errors).to eq 0
      end

      it 'calculates total documents' do
        stats.documents_synchronized = 3
        stats.documents_up_to_date = 2

        expect(stats.total_documents).to eq 5
      end
    end
  end
end
