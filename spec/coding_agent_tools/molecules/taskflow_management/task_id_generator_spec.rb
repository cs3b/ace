# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskIdGenerator do
  describe 'GenerationResult' do
    it 'creates successful result' do
      result = described_class::GenerationResult.new('v.1.0.0+task.1', 'v.1.0.0', 1, true, nil)

      expect(result.success?).to be true
      expect(result.task_id).to eq('v.1.0.0+task.1')
      expect(result.version).to eq('v.1.0.0')
      expect(result.sequential_number).to eq(1)
      expect(result.error_message).to be_nil
    end

    it 'creates failure result' do
      result = described_class::GenerationResult.new(nil, nil, nil, false, 'Version not found')

      expect(result.success?).to be false
      expect(result.task_id).to be_nil
      expect(result.error_message).to eq('Version not found')
    end
  end

  describe '.generate_next_task_id' do
    let(:release_path) { '/path/to/v.1.0.0-release' }
    let(:version) { 'v.1.0.0' }

    before do
      # Mock version extraction
      allow(described_class).to receive(:extract_version_from_directory)
        .with(release_path).and_return(version)

      # Mock finding max task number
      allow(described_class).to receive(:find_max_task_number)
        .with(release_path, version).and_return(5)

      # Mock task ID parser
      allow(CodingAgentTools::Atoms::TaskflowManagement::TaskIdParser)
        .to receive(:generate_next_id).with(version, current_max: 5)
        .and_return('v.1.0.0+task.6')
    end

    it 'generates next task ID successfully' do
      result = described_class.generate_next_task_id(release_path)

      expect(result.success?).to be true
      expect(result.task_id).to eq('v.1.0.0+task.6')
      expect(result.version).to eq('v.1.0.0')
      expect(result.sequential_number).to eq(6)
      expect(result.error_message).to be_nil
    end

    it 'accepts explicit version parameter' do
      custom_version = 'v.2.0.0'
      allow(described_class).to receive(:find_max_task_number)
        .with(release_path, custom_version).and_return(10)
      allow(CodingAgentTools::Atoms::TaskflowManagement::TaskIdParser)
        .to receive(:generate_next_id).with(custom_version, current_max: 10)
        .and_return('v.2.0.0+task.11')

      result = described_class.generate_next_task_id(release_path, version: custom_version)

      expect(result.success?).to be true
      expect(result.task_id).to eq('v.2.0.0+task.11')
      expect(result.version).to eq('v.2.0.0')
      expect(result.sequential_number).to eq(11)
    end

    context 'when version extraction fails' do
      before do
        allow(described_class).to receive(:extract_version_from_directory)
          .with(release_path).and_return(nil)
      end

      it 'returns failure result' do
        result = described_class.generate_next_task_id(release_path)

        expect(result.success?).to be false
        expect(result.task_id).to be_nil
        expect(result.error_message).to eq('Could not extract version')
      end
    end

    context 'when task ID generation raises exception' do
      before do
        allow(CodingAgentTools::Atoms::TaskflowManagement::TaskIdParser)
          .to receive(:generate_next_id).and_raise(StandardError.new('ID generation failed'))
      end

      it 'returns failure result with error message' do
        result = described_class.generate_next_task_id(release_path)

        expect(result.success?).to be false
        expect(result.task_id).to be_nil
        expect(result.error_message).to include('Error generating task ID')
        expect(result.error_message).to include('ID generation failed')
      end
    end
  end
end
