# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/cli/commands/handbook/claude/validate'

RSpec.describe CodingAgentTools::Cli::Commands::Handbook::Claude::Validate do
  let(:command) { described_class.new }
  let(:validator) { instance_double(CodingAgentTools::Organisms::ClaudeValidator) }
  let(:validation_result) { instance_double(CodingAgentTools::Organisms::ClaudeValidator::ValidationResult) }

  before do
    allow(CodingAgentTools::Organisms::ClaudeValidator).to receive(:new).and_return(validator)
    allow(validator).to receive(:validate).and_return(validation_result)
    allow(validation_result).to receive(:to_s).and_return('Validation output')
    allow(validation_result).to receive(:success).and_return(true)
    allow(command).to receive(:exit)
  end

  describe '#call' do
    it 'creates a validator and runs validation' do
      expect(validator).to receive(:validate).with({})
      expect { command.call }.to output("Validation output\n").to_stdout
    end

    it 'passes options to validator' do
      options = { check: 'missing', workflow: 'test', format: 'json' }
      expect(validator).to receive(:validate).with(options)
      command.call(**options)
    end

    context 'when validation succeeds' do
      it 'exits with code 0' do
        expect(command).to receive(:exit).with(0)
        command.call
      end
    end

    context 'when validation fails' do
      before do
        allow(validation_result).to receive(:success).and_return(false)
      end

      it 'exits with code 1' do
        expect(command).to receive(:exit).with(1)
        command.call
      end

      context 'with strict option' do
        it 'exits with code 1' do
          expect(command).to receive(:exit).with(1)
          command.call(strict: true)
        end
      end
    end

    context 'when an error occurs' do
      before do
        allow(validator).to receive(:validate).and_raise(StandardError, 'Test error')
        allow(command).to receive(:warn)
      end

      it 'outputs error message and exits with code 1' do
        expect(command).to receive(:warn).with('Error: Test error')
        expect(command).to receive(:exit).with(1)
        command.call
      end

      it 'outputs backtrace when DEBUG is set' do
        allow(ENV).to receive(:[]).with('DEBUG').and_return('true')
        expect(command).to receive(:warn).with('Error: Test error')
        expect(command).to receive(:warn).with(instance_of(Array))
        expect(command).to receive(:exit).with(1)
        command.call
      end
    end
  end

  describe 'command metadata' do
    it 'has correct description' do
      expect(described_class.description).to eq('Validate Claude command coverage')
    end

    it 'has correct options' do
      options = described_class.options
      option_names = options.map(&:name)

      expect(option_names).to include(:check)
      expect(option_names).to include(:strict)
      expect(option_names).to include(:workflow)
      expect(option_names).to include(:format)

      format_option = options.find { |opt| opt.name == :format }
      expect(format_option.values).to eq(['text', 'json'])

      strict_option = options.find { |opt| opt.name == :strict }
      expect(strict_option.default).to eq(false)
    end

    it 'has examples' do
      expect(described_class.examples).to be_an(Array)
      expect(described_class.examples).not_to be_empty
      expect(described_class.examples.join(' ')).to include('--check missing')
      expect(described_class.examples.join(' ')).to include('--workflow draft-task')
    end
  end
end
