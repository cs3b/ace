# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Code::ReviewPrepare::SessionDir do
  let(:command) { described_class.new }
  let(:mock_session_manager) { instance_double('CodingAgentTools::Organisms::Code::SessionManager') }
  let(:mock_session) do
    double('session',
      directory_path: '/sessions/review-20240101-120000',
      session_id: '20240101-120000')
  end

  before do
    allow(CodingAgentTools::Organisms::Code::SessionManager).to receive(:new).and_return(mock_session_manager)
    allow(mock_session_manager).to receive(:create_session).and_return(mock_session)

    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  describe '#call' do
    context 'with successful session creation' do
      it 'creates session successfully with required options' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          focus: 'code',
          target: 'HEAD~1..HEAD',
          context_mode: 'auto',
          base_path: nil
        )
      end

      it 'displays success information' do
        command.call(focus: 'code', target: 'HEAD~1..HEAD')

        expect($stdout).to have_received(:puts).with('✅ Created session directory: /sessions/review-20240101-120000')
        expect($stdout).to have_received(:puts).with('📁 Session ID: 20240101-120000')
      end

      it 'handles custom base_path' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD', base_path: '/custom/sessions')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          focus: 'code',
          target: 'HEAD~1..HEAD',
          context_mode: 'auto',
          base_path: '/custom/sessions'
        )
      end

      it 'handles different focus types' do
        focus_types = ['code', 'tests', 'docs', 'code tests', 'code tests docs']

        focus_types.each do |focus|
          result = command.call(focus: focus, target: 'HEAD~1..HEAD')

          expect(result).to eq(0)
          expect(mock_session_manager).to have_received(:create_session).with(
            hash_including(focus: focus)
          )
        end
      end

      it 'handles different target types' do
        target_types = [
          'HEAD~1..HEAD',
          'lib/**/*.rb',
          'staged',
          'unstaged',
          'working',
          'v1.0.0..v2.0.0'
        ]

        target_types.each do |target|
          result = command.call(focus: 'code', target: target)

          expect(result).to eq(0)
          expect(mock_session_manager).to have_received(:create_session).with(
            hash_including(target: target)
          )
        end
      end

      it 'always uses auto context mode' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(context_mode: 'auto')
        )
      end
    end

    context 'with session creation failures' do
      before do
        allow(mock_session_manager).to receive(:create_session).and_raise(StandardError, 'Session creation failed')
      end

      it 'handles session creation errors gracefully' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Session creation failed\n")
      end

      it 'handles different error types' do
        error_types = [
          [ArgumentError, 'Invalid focus'],
          [IOError, 'Directory creation failed'],
          [RuntimeError, 'Runtime error occurred']
        ]

        error_types.each do |error_class, message|
          allow(mock_session_manager).to receive(:create_session).and_raise(error_class, message)

          result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

          expect(result).to eq(1)
          expect($stderr).to have_received(:write).with("Error: #{message}\n")
        end
      end
    end

    context 'with various session configurations' do
      it 'creates session with complex focus combinations' do
        complex_focuses = [
          'code tests',
          'code docs',
          'tests docs',
          'code tests docs'
        ]

        complex_focuses.each do |focus|
          result = command.call(focus: focus, target: 'HEAD~1..HEAD')

          expect(result).to eq(0)
          expect(mock_session_manager).to have_received(:create_session).with(
            hash_including(focus: focus)
          )
        end
      end

      it 'creates session with file pattern targets' do
        file_patterns = [
          'lib/**/*.rb',
          'src/**/*.{js,ts}',
          'spec/**/*_spec.rb',
          '{lib,app}/**/*.rb'
        ]

        file_patterns.each do |pattern|
          result = command.call(focus: 'code', target: pattern)

          expect(result).to eq(0)
          expect(mock_session_manager).to have_received(:create_session).with(
            hash_including(target: pattern)
          )
        end
      end

      it 'creates session with git range targets' do
        git_ranges = [
          'HEAD~1..HEAD',
          'HEAD~5..HEAD',
          'main..feature-branch',
          'v1.0.0..v2.0.0',
          'abc123..def456'
        ]

        git_ranges.each do |range|
          result = command.call(focus: 'code', target: range)

          expect(result).to eq(0)
          expect(mock_session_manager).to have_received(:create_session).with(
            hash_including(target: range)
          )
        end
      end

      it 'creates session with special targets' do
        special_targets = ['staged', 'unstaged', 'working']

        special_targets.each do |target|
          result = command.call(focus: 'code', target: target)

          expect(result).to eq(0)
          expect(mock_session_manager).to have_received(:create_session).with(
            hash_including(target: target)
          )
        end
      end
    end

    context 'with different base paths' do
      it 'handles absolute base paths' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD', base_path: '/absolute/path/sessions')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(base_path: '/absolute/path/sessions')
        )
      end

      it 'handles relative base paths' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD', base_path: 'relative/sessions')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(base_path: 'relative/sessions')
        )
      end

      it 'handles base paths with special characters' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD', base_path: '/path with spaces & symbols!/sessions')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(base_path: '/path with spaces & symbols!/sessions')
        )
      end

      it 'handles nil base_path (default behavior)' do
        result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

        expect(result).to eq(0)
        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(base_path: nil)
        )
      end
    end

    context 'with edge cases' do
      it 'handles empty focus (should be caught by validation)' do
        # This tests how the command handles edge cases
        # The actual validation might happen in the session manager
        result = command.call(focus: '', target: 'HEAD~1..HEAD')

        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(focus: '')
        )
        # Result depends on session manager validation
        expect(result).to be_a(Integer)
      end

      it 'handles empty target (should be caught by validation)' do
        result = command.call(focus: 'code', target: '')

        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(target: '')
        )
        # Result depends on session manager validation
        expect(result).to be_a(Integer)
      end

      it 'handles very long focus strings' do
        long_focus = 'code ' * 100
        result = command.call(focus: long_focus.strip, target: 'HEAD~1..HEAD')

        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(focus: long_focus.strip)
        )
        expect(result).to be_a(Integer)
      end

      it 'handles very long target strings' do
        long_target = 'very/long/path/' * 50 + '*.rb'
        result = command.call(focus: 'code', target: long_target)

        expect(mock_session_manager).to have_received(:create_session).with(
          hash_including(target: long_target)
        )
        expect(result).to be_a(Integer)
      end
    end

    context 'with session manager integration' do
      it 'creates session manager instance' do
        expect(CodingAgentTools::Organisms::Code::SessionManager).to receive(:new)

        command.call(focus: 'code', target: 'HEAD~1..HEAD')
      end

      it 'delegates session creation properly' do
        focus = 'code tests'
        target = 'lib/**/*.rb'
        base_path = '/custom/sessions'

        command.call(focus: focus, target: target, base_path: base_path)

        expect(mock_session_manager).to have_received(:create_session).with(
          focus: focus,
          target: target,
          context_mode: 'auto',
          base_path: base_path
        )
      end

      it 'handles session manager returning different session objects' do
        different_session = double('session',
          directory_path: '/different/session/path',
          session_id: 'different-id')
        allow(mock_session_manager).to receive(:create_session).and_return(different_session)

        result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with('✅ Created session directory: /different/session/path')
        expect($stdout).to have_received(:puts).with('📁 Session ID: different-id')
      end
    end
  end

  describe 'command configuration' do
    it 'has correct description' do
      expect(described_class.description).to eq('Create session directory structure')
    end

    it 'requires focus option' do
      expect { command.call(target: 'HEAD~1..HEAD') }.to raise_error(ArgumentError)
    end

    it 'requires target option' do
      expect { command.call(focus: 'code') }.to raise_error(ArgumentError)
    end

    it 'has base_path as optional' do
      # Should not raise error when base_path is not provided
      expect { command.call(focus: 'code', target: 'HEAD~1..HEAD') }.not_to raise_error
    end

    it 'has usage examples defined' do
      expect(described_class).to respond_to(:example)
    end
  end

  describe 'return codes' do
    it 'returns 0 for successful session creation' do
      result = command.call(focus: 'code', target: 'HEAD~1..HEAD')
      expect(result).to eq(0)
    end

    it 'returns 1 for session creation errors' do
      allow(mock_session_manager).to receive(:create_session).and_raise(StandardError)
      result = command.call(focus: 'code', target: 'HEAD~1..HEAD')
      expect(result).to eq(1)
    end
  end

  describe 'output formatting' do
    it 'formats directory path correctly' do
      command.call(focus: 'code', target: 'HEAD~1..HEAD')

      expect($stdout).to have_received(:puts).with('✅ Created session directory: /sessions/review-20240101-120000')
    end

    it 'formats session ID correctly' do
      command.call(focus: 'code', target: 'HEAD~1..HEAD')

      expect($stdout).to have_received(:puts).with('📁 Session ID: 20240101-120000')
    end

    it 'handles nil or empty session information' do
      nil_session = double('session', directory_path: nil, session_id: nil)
      allow(mock_session_manager).to receive(:create_session).and_return(nil_session)

      result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

      expect(result).to eq(0)
      expect($stdout).to have_received(:puts).with('✅ Created session directory: ')
      expect($stdout).to have_received(:puts).with('📁 Session ID: ')
    end
  end

  describe 'error handling' do
    it 'provides meaningful error messages' do
      allow(mock_session_manager).to receive(:create_session).and_raise(ArgumentError, 'Invalid focus: xyz')

      result = command.call(focus: 'xyz', target: 'HEAD~1..HEAD')

      expect(result).to eq(1)
      expect($stderr).to have_received(:write).with("Error: Invalid focus: xyz\n")
    end

    it 'handles unexpected exceptions' do
      allow(mock_session_manager).to receive(:create_session).and_raise(NoMethodError, 'undefined method')

      result = command.call(focus: 'code', target: 'HEAD~1..HEAD')

      expect(result).to eq(1)
      expect($stderr).to have_received(:write).with("Error: undefined method\n")
    end
  end
end
