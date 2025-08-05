# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Models::ClaudeCommand do
  describe 'initialization' do
    it 'creates a command with all attributes' do
      time = Time.now
      command = described_class.new(
        name: 'commit',
        type: 'custom',
        path: 'dev-handbook/.integrations/claude/commands/_custom/commit.md',
        installed: true,
        valid: true,
        size: 1024,
        modified: time,
        modified_iso: time.iso8601
      )

      expect(command.name).to eq('commit')
      expect(command.type).to eq('custom')
      expect(command.path).to eq('dev-handbook/.integrations/claude/commands/_custom/commit.md')
      expect(command.installed).to be true
      expect(command.valid).to be true
      expect(command.size).to eq(1024)
      expect(command.modified).to eq(time)
      expect(command.modified_iso).to eq(time.iso8601)
    end

    it 'creates a command with minimal attributes' do
      command = described_class.new(
        name: 'missing-command',
        type: 'missing',
        installed: false,
        valid: false
      )

      expect(command.name).to eq('missing-command')
      expect(command.type).to eq('missing')
      expect(command.installed).to be false
      expect(command.valid).to be false
      expect(command.path).to be_nil
      expect(command.size).to be_nil
    end
  end

  describe '#missing?' do
    it 'returns true for missing type' do
      command = described_class.new(type: 'missing')
      expect(command.missing?).to be true
    end

    it 'returns false for other types' do
      command = described_class.new(type: 'custom')
      expect(command.missing?).to be false
    end
  end

  describe '#custom?' do
    it 'returns true for custom type' do
      command = described_class.new(type: 'custom')
      expect(command.custom?).to be true
    end

    it 'returns false for other types' do
      command = described_class.new(type: 'generated')
      expect(command.custom?).to be false
    end
  end

  describe '#generated?' do
    it 'returns true for generated type' do
      command = described_class.new(type: 'generated')
      expect(command.generated?).to be true
    end

    it 'returns false for other types' do
      command = described_class.new(type: 'custom')
      expect(command.generated?).to be false
    end
  end

  describe '#to_h' do
    it 'returns hash with all non-nil values' do
      command = described_class.new(
        name: 'test',
        type: 'custom',
        installed: true,
        valid: true,
        path: nil,
        size: nil
      )

      hash = command.to_h
      expect(hash).to eq({
        name: 'test',
        type: 'custom',
        installed: true,
        valid: true
      })
    end
  end
end