# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Atoms::Code::SessionTimestampGenerator do
  let(:generator) { described_class.new }

  describe '#generate' do
    it 'generates timestamp in YYYYMMDD-HHMMSS format' do
      # Mock Time.now to return a known time
      fixed_time = Time.new(2024, 7, 24, 14, 30, 22)
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate
      expect(result).to eq('20240724-143022')
    end

    it 'generates different timestamps when time advances' do
      first_time = Time.new(2024, 7, 24, 14, 30, 22)
      second_time = Time.new(2024, 7, 24, 14, 30, 23)

      allow(Time).to receive(:now).and_return(first_time)
      first_result = generator.generate

      allow(Time).to receive(:now).and_return(second_time)
      second_result = generator.generate

      expect(first_result).to eq('20240724-143022')
      expect(second_result).to eq('20240724-143023')
      expect(first_result).not_to eq(second_result)
    end

    it 'handles single-digit months and days with zero padding' do
      fixed_time = Time.new(2024, 1, 5, 9, 7, 3)
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate
      expect(result).to eq('20240105-090703')
    end

    it 'handles end of year correctly' do
      fixed_time = Time.new(2024, 12, 31, 23, 59, 59)
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate
      expect(result).to eq('20241231-235959')
    end

    it 'handles leap year correctly' do
      fixed_time = Time.new(2024, 2, 29, 12, 0, 0)
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate
      expect(result).to eq('20240229-120000')
    end
  end

  describe '#generate_iso8601' do
    it 'generates ISO8601 formatted timestamp' do
      fixed_time = Time.new(2024, 7, 24, 14, 30, 22, '+00:00')
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate_iso8601
      expect(result).to match(/2024-07-24T14:30:22(\+00:00|Z)/)
    end

    it 'includes timezone information' do
      # Test with a different timezone
      fixed_time = Time.new(2024, 7, 24, 14, 30, 22, '-08:00')
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate_iso8601
      expect(result).to include('2024-07-24T14:30:22')
      expect(result).to include('-08:00')
    end

    it 'handles UTC timezone correctly' do
      fixed_time = Time.new(2024, 7, 24, 14, 30, 22).utc
      allow(Time).to receive(:now).and_return(fixed_time)

      result = generator.generate_iso8601
      expect(result).to match(/2024-07-24T\d{2}:30:22(Z|\+00:00)/)
    end

    it 'generates different ISO timestamps when time advances' do
      first_time = Time.new(2024, 7, 24, 14, 30, 22, '+00:00')
      second_time = Time.new(2024, 7, 24, 14, 30, 23, '+00:00')

      allow(Time).to receive(:now).and_return(first_time)
      first_result = generator.generate_iso8601

      allow(Time).to receive(:now).and_return(second_time)
      second_result = generator.generate_iso8601

      expect(first_result).to match(/2024-07-24T14:30:22(\+00:00|Z)/)
      expect(second_result).to match(/2024-07-24T14:30:23(\+00:00|Z)/)
      expect(first_result).not_to eq(second_result)
    end
  end

  describe '#generate_for_time' do
    it 'generates timestamp for specific time object' do
      specific_time = Time.new(2024, 7, 24, 14, 30, 22)

      result = generator.generate_for_time(specific_time)
      expect(result).to eq('20240724-143022')
    end

    it 'handles different time zones in input time' do
      # Create times that represent the same moment but in different timezones
      base_time = Time.new(2024, 7, 24, 14, 30, 22)
      utc_time = base_time.utc

      utc_result = generator.generate_for_time(utc_time)
      local_result = generator.generate_for_time(base_time)

      # Both should be properly formatted
      expect(utc_result).to match(/^\d{8}-\d{6}$/)
      expect(local_result).to match(/^\d{8}-\d{6}$/)
    end

    it 'handles edge cases for time formatting' do
      # Test midnight
      midnight = Time.new(2024, 1, 1, 0, 0, 0)
      result = generator.generate_for_time(midnight)
      expect(result).to eq('20240101-000000')

      # Test end of day
      end_of_day = Time.new(2024, 12, 31, 23, 59, 59)
      result = generator.generate_for_time(end_of_day)
      expect(result).to eq('20241231-235959')
    end

    it 'handles single digit values with zero padding' do
      time_with_single_digits = Time.new(2024, 1, 5, 9, 7, 3)

      result = generator.generate_for_time(time_with_single_digits)
      expect(result).to eq('20240105-090703')
    end

    it 'produces same format as generate() when using current time' do
      current_time = Time.now

      # Mock Time.now to return our current_time
      allow(Time).to receive(:now).and_return(current_time)

      generated_result = generator.generate
      specific_result = generator.generate_for_time(current_time)

      expect(generated_result).to eq(specific_result)
    end

    it 'handles nil time gracefully' do
      expect { generator.generate_for_time(nil) }.to raise_error(NoMethodError)
    end

    it 'handles invalid time objects' do
      expect { generator.generate_for_time('not a time') }.to raise_error(NoMethodError)
    end
  end

  # Test consistency between methods
  describe 'method consistency' do
    it 'generate() and generate_for_time() produce consistent results' do
      fixed_time = Time.new(2024, 7, 24, 14, 30, 22)

      allow(Time).to receive(:now).and_return(fixed_time)
      generate_result = generator.generate

      specific_result = generator.generate_for_time(fixed_time)

      expect(generate_result).to eq(specific_result)
    end

    it 'handles microseconds by ignoring them' do
      time_with_microseconds = Time.new(2024, 7, 24, 14, 30, 22.123456)

      result = generator.generate_for_time(time_with_microseconds)
      expect(result).to eq('20240724-143022')
    end
  end

  # Performance and behavior tests
  describe 'behavior tests' do
    it 'generates timestamps with expected format consistently' do
      # Test that multiple calls produce properly formatted timestamps
      timestamps = []

      10.times do |i|
        # Use different mock times to ensure uniqueness
        mock_time = Time.new(2024, 7, 24, 14, 30, 22 + i)
        allow(Time).to receive(:now).and_return(mock_time)
        timestamps << generator.generate
      end

      # All should be properly formatted
      timestamps.each do |timestamp|
        expect(timestamp).to match(/^\d{8}-\d{6}$/)
      end

      # All should be unique since we used different times
      expect(timestamps.uniq.size).to eq(10)
    end

    it "doesn't modify global time state" do
      original_time = Time.now

      generator.generate
      generator.generate_iso8601
      generator.generate_for_time(Time.new(2024, 1, 1))

      # Time.now should still work normally
      current_time = Time.now
      expect(current_time).to be_within(5).of(original_time)
    end
  end
end
