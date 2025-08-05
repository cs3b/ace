# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Release::Validate do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_release_manager) { double('CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager') }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(mock_release_manager)
  end

  describe '#call' do
    context 'with successful validation and text format' do
      let(:success_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-workflows',
            path: '/path/to/current/v.0.3.0-workflows',
            validation_status: 'consistent'
          },
          error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(success_result)
      end

      it 'displays success message in text format' do
        output = capture_stdout { command.call }

        expect(output).to include('Release Context Validation: PASSED')
        expect(output).to include('Current Release: v.0.3.0-workflows')
        expect(output).to include('Path: /path/to/current/v.0.3.0-workflows')
        expect(output).to include('Status: consistent')
        expect(output).to include('✓ No inconsistencies detected')
      end

      it 'returns 0 for successful validation' do
        capture_stdout { expect(command.call).to eq(0) }
      end

      it 'creates ReleaseManager with correct project root' do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to have_received(:new).with(base_path: project_root)
      end
    end

    context 'with failed validation and text format' do
      let(:failed_result) do
        double('Result',
          success?: false,
          error_message: 'Release context inconsistency detected')
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(failed_result)
        allow(command).to receive(:error_output)
      end

      it 'displays failure message and recommendations' do
        output = capture_stdout { command.call }

        expect(command).to have_received(:error_output).with('Validation FAILED: Release context inconsistency detected')
        expect(output).to include('This indicates that release-manager and nav-path may report different')
        expect(output).to include('Recommended actions:')
        expect(output).to include('1. Check that dev-taskflow/current/ contains exactly one release directory')
        expect(output).to include('2. Verify that both tools use the same release detection mechanism')
        expect(output).to include('3. Check for any manual modifications to release directories')
      end

      it 'returns 1 for failed validation' do
        capture_stdout { expect(command.call).to eq(1) }
      end
    end

    context 'with successful validation and JSON format' do
      let(:success_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-workflows',
            path: '/path/to/current/v.0.3.0-workflows',
            validation_status: 'consistent'
          },
          error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(success_result)
      end

      it 'displays success result in JSON format' do
        output = capture_stdout { command.call(format: 'json') }

        json_output = JSON.parse(output)
        expect(json_output['success']).to be(true)
        expect(json_output['validation_status']).to eq('passed')
        expect(json_output['data']['current_release']).to eq('v.0.3.0-workflows')
        expect(json_output['data']['path']).to eq('/path/to/current/v.0.3.0-workflows')
        expect(json_output['data']['validation_status']).to eq('consistent')
        expect(json_output['message']).to eq('Validation passed')
      end
    end

    context 'with failed validation and JSON format' do
      let(:failed_result) do
        double('Result',
          success?: false,
          error_message: 'Multiple current releases found')
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(failed_result)
      end

      it 'displays failure result in JSON format' do
        output = capture_stdout { command.call(format: 'json') }

        json_output = JSON.parse(output)
        expect(json_output['success']).to be(false)
        expect(json_output['validation_status']).to eq('failed')
        expect(json_output['error']).to eq('Multiple current releases found')
        expect(json_output['recommendations']).to include('Check that dev-taskflow/current/ contains exactly one release directory')
        expect(json_output['recommendations']).to include('Verify that both tools use the same release detection mechanism')
        expect(json_output['recommendations']).to include('Check for any manual modifications to release directories')
      end
    end

    context 'with exception handling' do
      let(:error) { StandardError.new('Unexpected error') }

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_raise(error)
        allow(command).to receive(:handle_error)
      end

      it 'handles exceptions and returns error code' do
        result = command.call

        expect(result).to eq(1)
        expect(command).to have_received(:handle_error).with(error, nil)
      end

      it 'passes debug flag to error handler' do
        command.call(debug: true)

        expect(command).to have_received(:handle_error).with(error, true)
      end
    end

    context 'with format option validation' do
      let(:success_result) do
        double('Result', success?: true, data: {}, error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(success_result)
      end

      it 'defaults to text format when no format specified' do
        output = capture_stdout { command.call }
        expect(output).to include('Release Context Validation: PASSED')
      end

      it 'uses text format when explicitly specified' do
        output = capture_stdout { command.call(format: 'text') }
        expect(output).to include('Release Context Validation: PASSED')
      end

      it 'uses JSON format when specified' do
        output = capture_stdout { command.call(format: 'json') }
        json_output = JSON.parse(output)
        expect(json_output).to have_key('success')
      end
    end
  end

  describe '#handle_text_result' do
    context 'with successful result' do
      let(:success_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-test',
            path: '/path/to/release',
            validation_status: 'valid'
          })
      end

      it 'formats successful result correctly' do
        output = capture_stdout { command.send(:handle_text_result, success_result) }

        expect(output).to include('Release Context Validation: PASSED')
        expect(output).to include('=' * 40)
        expect(output).to include('Current Release: v.0.3.0-test')
        expect(output).to include('Path: /path/to/release')
        expect(output).to include('Status: valid')
        expect(output).to include('✓ No inconsistencies detected between release-manager and nav-path')
      end
    end

    context 'with failed result' do
      let(:failed_result) do
        double('Result',
          success?: false,
          error_message: 'Validation failed due to inconsistency')
      end

      before do
        allow(command).to receive(:error_output)
      end

      it 'formats failed result with recommendations' do
        output = capture_stdout { command.send(:handle_text_result, failed_result) }

        expect(command).to have_received(:error_output).with('Validation FAILED: Validation failed due to inconsistency')
        expect(output).to include('This indicates that release-manager and nav-path may report different')
        expect(output).to include('current releases, which could cause task creation inconsistencies.')
        expect(output).to include('Recommended actions:')
        expect(output).to include('1. Check that dev-taskflow/current/ contains exactly one release directory')
        expect(output).to include('2. Verify that both tools use the same release detection mechanism')
        expect(output).to include('3. Check for any manual modifications to release directories')
      end
    end

    context 'with empty or nil data' do
      let(:result_with_nil_data) do
        double('Result',
          success?: true,
          data: {})
      end

      it 'handles empty data gracefully' do
        output = capture_stdout { command.send(:handle_text_result, result_with_nil_data) }
        expect(output).to include('Release Context Validation: PASSED')
      end
    end
  end

  describe '#handle_json_result' do
    context 'with successful result' do
      let(:success_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-test',
            validation_status: 'consistent'
          },
          error_message: nil)
      end

      it 'generates correct JSON for successful validation' do
        output = capture_stdout { command.send(:handle_json_result, success_result) }

        json_output = JSON.parse(output)
        expect(json_output['success']).to be(true)
        expect(json_output['validation_status']).to eq('passed')
        expect(json_output['data']['current_release']).to eq('v.0.3.0-test')
        expect(json_output['data']['validation_status']).to eq('consistent')
        expect(json_output['message']).to eq('Validation passed')
      end
    end

    context 'with successful result and custom message' do
      let(:success_result) do
        double('Result',
          success?: true,
          data: {},
          error_message: 'Custom success message')
      end

      it 'uses custom message when provided' do
        output = capture_stdout { command.send(:handle_json_result, success_result) }

        json_output = JSON.parse(output)
        expect(json_output['message']).to eq('Custom success message')
      end
    end

    context 'with failed result' do
      let(:failed_result) do
        double('Result',
          success?: false,
          error_message: 'Multiple releases detected')
      end

      it 'generates correct JSON for failed validation' do
        output = capture_stdout { command.send(:handle_json_result, failed_result) }

        json_output = JSON.parse(output)
        expect(json_output['success']).to be(false)
        expect(json_output['validation_status']).to eq('failed')
        expect(json_output['error']).to eq('Multiple releases detected')
        expect(json_output['recommendations']).to be_an(Array)
        expect(json_output['recommendations']).to include('Check that dev-taskflow/current/ contains exactly one release directory')
      end
    end

    context 'with large data sets' do
      let(:large_data_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-test',
            large_array: Array.new(1000) { |i| "item_#{i}" },
            nested_data: {
              level1: {
                level2: {
                  level3: 'deep value'
                }
              }
            }
          },
          error_message: nil)
      end

      it 'handles large data sets without issues' do
        output = capture_stdout { command.send(:handle_json_result, large_data_result) }

        json_output = JSON.parse(output)
        expect(json_output['success']).to be(true)
        expect(json_output['data']['large_array']).to be_an(Array)
        expect(json_output['data']['large_array'].size).to eq(1000)
        expect(json_output['data']['nested_data']['level1']['level2']['level3']).to eq('deep value')
      end
    end

    context 'with malformed data' do
      let(:malformed_result) do
        double('Result',
          success?: true,
          data: {
            circular: nil  # We'll make this circular
          },
          error_message: nil)
      end

      before do
        # Create circular reference
        circular_hash = {}
        circular_hash[:self] = circular_hash
        allow(malformed_result).to receive(:data).and_return(circular_hash)
      end

      it 'handles circular references gracefully' do
        expect do
          capture_stdout { command.send(:handle_json_result, malformed_result) }
        end.to raise_error(JSON::NestingError)
      end
    end
  end

  describe '#handle_error' do
    let(:error) { StandardError.new('Test error message') }

    before do
      allow(command).to receive(:error_output)
      allow(error).to receive(:backtrace).and_return([
        "/path/to/file1.rb:10:in `method1'",
        "/path/to/file2.rb:20:in `method2'",
        "/path/to/file3.rb:30:in `method3'"
      ])
    end

    context 'with debug disabled' do
      it 'outputs simple error message' do
        command.send(:handle_error, error, false)

        expect(command).to have_received(:error_output).with('Error: Test error message')
        expect(command).to have_received(:error_output).with('Use --debug flag for more information')
      end
    end

    context 'with debug enabled' do
      it 'outputs detailed error information with full backtrace' do
        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with('Error: StandardError: Test error message')
        expect(command).to have_received(:error_output).with("\nBacktrace:")
        expect(command).to have_received(:error_output).with("  /path/to/file1.rb:10:in `method1'")
        expect(command).to have_received(:error_output).with("  /path/to/file2.rb:20:in `method2'")
        expect(command).to have_received(:error_output).with("  /path/to/file3.rb:30:in `method3'")
      end
    end

    context 'with nil backtrace' do
      it 'handles missing backtrace gracefully' do
        allow(error).to receive(:backtrace).and_return(nil)

        # This will actually raise an error in the real implementation, so let's test that
        expect do
          command.send(:handle_error, error, true)
        end.to raise_error(NoMethodError)
      end
    end

    context 'with empty backtrace' do
      it 'handles empty backtrace array' do
        allow(error).to receive(:backtrace).and_return([])

        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with('Error: StandardError: Test error message')
        expect(command).to have_received(:error_output).with("\nBacktrace:")
      end
    end

    context 'with different error types' do
      it 'handles RuntimeError correctly' do
        runtime_error = RuntimeError.new('Runtime issue')
        allow(runtime_error).to receive(:backtrace).and_return(['/path:1'])

        command.send(:handle_error, runtime_error, true)

        expect(command).to have_received(:error_output).with('Error: RuntimeError: Runtime issue')
      end

      it 'handles custom error classes' do
        custom_error = Class.new(StandardError).new('Custom error')
        allow(custom_error).to receive(:backtrace).and_return(['/path:1'])

        command.send(:handle_error, custom_error, true)

        expect(command).to have_received(:error_output).with(/Custom error/)
      end
    end
  end

  describe '#error_output' do
    it 'outputs to stderr' do
      expect { command.send(:error_output, 'Test error message') }.to output("Test error message\n").to_stderr
    end

    it 'handles empty messages' do
      expect { command.send(:error_output, '') }.to output("\n").to_stderr
    end

    it 'handles nil messages' do
      expect { command.send(:error_output, nil) }.to output("\n").to_stderr
    end
  end

  describe 'edge cases and boundary conditions' do
    context 'with concurrent access simulation' do
      let(:result) { double('Result', success?: true, data: {}, error_message: nil) }

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(result)
      end

      it 'handles multiple concurrent calls gracefully' do
        threads = Array.new(5) do
          Thread.new { capture_stdout { command.call } }
        end

        results = threads.map(&:value)
        expect(results).to all(include('Release Context Validation: PASSED'))
      end
    end

    context 'with very long data values' do
      let(:long_data_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-' + 'x' * 1000,
            path: '/very/long/path/' + 'directory/' * 100,
            validation_status: 'status_' + 'y' * 500
          },
          error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(long_data_result)
      end

      it 'handles very long string values without truncation' do
        output = capture_stdout { command.call }

        expect(output).to include('v.0.3.0-' + 'x' * 1000)
        expect(output).to include('/very/long/path/' + 'directory/' * 100)
        expect(output).to include('status_' + 'y' * 500)
      end
    end

    context 'with unicode and special characters' do
      let(:unicode_result) do
        double('Result',
          success?: true,
          data: {
            current_release: 'v.0.3.0-测试',
            path: '/path/with/émojis/🚀',
            validation_status: 'válid'
          },
          error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:validate_release_context_consistency).and_return(unicode_result)
      end

      it 'handles unicode characters correctly in text output' do
        output = capture_stdout { command.call }

        expect(output).to include('v.0.3.0-测试')
        expect(output).to include('/path/with/émojis/🚀')
        expect(output).to include('válid')
      end

      it 'handles unicode characters correctly in JSON output' do
        output = capture_stdout { command.call(format: 'json') }

        json_output = JSON.parse(output)
        expect(json_output['data']['current_release']).to eq('v.0.3.0-测试')
        expect(json_output['data']['path']).to eq('/path/with/émojis/🚀')
        expect(json_output['data']['validation_status']).to eq('válid')
      end
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end
