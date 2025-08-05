# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/atoms/timestamp_generator'

RSpec.describe CodingAgentTools::Atoms::TimestampGenerator do
  describe '.generate' do
    it 'generates timestamp with default format' do
      time = Time.new(2025, 8, 5, 14, 30, 45)
      timestamp = described_class.generate(time: time)
      
      expect(timestamp).to eq('20250805-1430')
    end
    
    it 'generates timestamp with custom format' do
      time = Time.new(2025, 8, 5, 14, 30, 45)
      timestamp = described_class.generate(time: time, format: '%Y-%m-%d')
      
      expect(timestamp).to eq('2025-08-05')
    end
  end
  
  describe '.backup_timestamp' do
    it 'generates backup-friendly timestamp' do
      time = Time.new(2025, 8, 5, 14, 30, 45)
      timestamp = described_class.backup_timestamp(time: time)
      
      expect(timestamp).to eq('20250805-1430')
    end
  end
  
  describe '.iso_timestamp' do
    it 'generates ISO format timestamp' do
      time = Time.new(2025, 8, 5, 14, 30, 45)
      timestamp = described_class.iso_timestamp(time: time)
      
      expect(timestamp).to eq('2025-08-05 14:30:45')
    end
  end
  
  describe '.filename_timestamp' do
    it 'generates filename-safe timestamp' do
      time = Time.new(2025, 8, 5, 14, 30, 45)
      timestamp = described_class.filename_timestamp(time: time)
      
      expect(timestamp).to eq('20250805_143045')
    end
  end
  
  describe '.parse' do
    it 'parses timestamp with default format' do
      time = described_class.parse('20250805-1430')
      
      expect(time).to be_a(Time)
      expect(time.year).to eq(2025)
      expect(time.month).to eq(8)
      expect(time.day).to eq(5)
      expect(time.hour).to eq(14)
      expect(time.min).to eq(30)
    end
    
    it 'returns nil for invalid timestamp' do
      time = described_class.parse('invalid')
      
      expect(time).to be_nil
    end
  end
end