# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Coverage::Analyze do
  let(:command) { described_class.new }
  let(:input_file) { '/fake/path/coverage.resultset.json' }
  let(:mock_workflow) { instance_double('CodingAgentTools::Ecosystems::CoverageAnalysisWorkflow') }

  before do
    allow(CodingAgentTools::Ecosystems::CoverageAnalysisWorkflow).to receive(:new).and_return(mock_workflow)
  end

  describe '#call' do
    context 'with recommend mode' do
      let(:recommend_result) do
        {
          file_validation: {
            frameworks_detected: ['RSpec'],
            total_files: 50,
            lib_files: 30,
            test_files: 20
          },
          analysis_recommendations: {
            suggested_threshold: 85,
            recommended_focus: 'lib files',
            estimated_analysis_time: '2-3 minutes',
            suggested_output_formats: ['text', 'json']
          },
          workflow_suggestions: {
            include_method_analysis: true,
            enable_create_path: false,
            focus_patterns: ['**/lib/**/*.rb', '**/app/**/*.rb']
          }
        }
      end

      before do
        allow(mock_workflow).to receive(:analyze_and_recommend).and_return(recommend_result)
      end

      it 'executes recommendation analysis and displays results' do
        output = capture_stdout { command.call(input_file: input_file, recommend: true) }

        expect(output).to include('🔍 Analyzing SimpleCov file for recommendations...')
        expect(output).to include('📋 File Validation Results:')
        expect(output).to include('Status: ✅ Valid SimpleCov file')
        expect(output).to include('Frameworks: RSpec')
        expect(output).to include('Total files: 50')
        expect(output).to include('💡 Analysis Recommendations:')
        expect(output).to include('Suggested threshold: 85%')
        expect(output).to include('⚙️  Workflow Suggestions:')
        expect(output).to include('Include method analysis: ✅')
        expect(mock_workflow).to have_received(:analyze_and_recommend).with(input_file)
      end

      it 'displays focus patterns when present' do
        output = capture_stdout { command.call(input_file: input_file, recommend: true) }

        expect(output).to include('Suggested focus patterns:')
        expect(output).to include('- **/lib/**/*.rb')
        expect(output).to include('- **/app/**/*.rb')
      end

      it 'returns early without executing other analysis modes' do
        allow(mock_workflow).to receive(:execute_quick_analysis)
        allow(mock_workflow).to receive(:execute_full_analysis)

        command.call(input_file: input_file, recommend: true)

        expect(mock_workflow).not_to have_received(:execute_quick_analysis)
        expect(mock_workflow).not_to have_received(:execute_full_analysis)
      end
    end

    context 'with quick analysis mode' do
      let(:quick_result) do
        {
          overall_coverage: 87.5,
          threshold: 85.0,
          status: 'good',
          files_under_threshold: 3,
          total_files: 25,
          critical_files: [
            { path: 'lib/important.rb', coverage: 45.2, uncovered_lines: 12 },
            { path: 'lib/core.rb', coverage: 52.1, uncovered_lines: 8 }
          ],
          recommendations: [
            'Focus on improving coverage in critical files',
            'Consider adding integration tests'
          ]
        }
      end

      before do
        allow(mock_workflow).to receive(:execute_quick_analysis).and_return(quick_result)
      end

      it 'executes quick analysis and displays results' do
        output = capture_stdout { command.call(input_file: input_file, quick: true) }

        expect(output).to include('⚡ Executing quick coverage analysis...')
        expect(output).to include('📊 Quick Analysis Results:')
        expect(output).to include('Overall Coverage: 87.5%')
        expect(output).to include('Threshold: 85.0%')
        expect(output).to include('Status: 🟡 Good')
        expect(output).to include('Files under threshold: 3/25')
        expect(mock_workflow).to have_received(:execute_quick_analysis)
      end

      it 'displays critical files when present' do
        output = capture_stdout { command.call(input_file: input_file, quick: true) }

        expect(output).to include('🚨 Critical Files (Top 5):')
        expect(output).to include('1. lib/important.rb: 45.2% (12 uncovered lines)')
        expect(output).to include('2. lib/core.rb: 52.1% (8 uncovered lines)')
      end

      it 'displays recommendations' do
        output = capture_stdout { command.call(input_file: input_file, quick: true) }

        expect(output).to include('📝 Quick Recommendations:')
        expect(output).to include('• Focus on improving coverage in critical files')
        expect(output).to include('• Consider adding integration tests')
      end

      it 'handles empty critical files list' do
        quick_result[:critical_files] = []
        output = capture_stdout { command.call(input_file: input_file, quick: true) }

        expect(output).not_to include('🚨 Critical Files')
      end
    end

    context 'with focused analysis mode' do
      let(:focused_result) do
        {
          focus_patterns: ['**/lib/**', '**/app/**'],
          summary: {
            files_found: 15,
            files_under_threshold: 4,
            coverage_distribution: {
              min_coverage: 23.4,
              max_coverage: 98.7,
              average_coverage: 78.2,
              files_under_50: 2,
              files_under_75: 6
            }
          }
        }
      end

      before do
        allow(mock_workflow).to receive(:execute_focused_analysis).and_return(focused_result)
      end

      it 'executes focused analysis with parsed patterns' do
        output = capture_stdout { command.call(input_file: input_file, focus: '**/lib/**,**/app/**') }

        expect(output).to include('🎯 Executing focused analysis on: **/lib/**, **/app/**')
        expect(mock_workflow).to have_received(:execute_focused_analysis)
          .with(input_file, ['**/lib/**', '**/app/**'], anything)
      end

      it 'displays focused analysis results' do
        output = capture_stdout { command.call(input_file: input_file, focus: '**/lib/**,**/app/**') }

        expect(output).to include('🎯 Focused Analysis Results:')
        expect(output).to include('Focus patterns: **/lib/**, **/app/**')
        expect(output).to include('Files found: 15')
        expect(output).to include('Files under threshold: 4')
      end

      it 'displays coverage distribution when present' do
        output = capture_stdout { command.call(input_file: input_file, focus: '**/lib/**,**/app/**') }

        expect(output).to include('📈 Coverage Distribution:')
        expect(output).to include('Range: 23.4% - 98.7%')
        expect(output).to include('Average: 78.2%')
        expect(output).to include('Files under 50%: 2')
        expect(output).to include('Files under 75%: 6')
      end

      it 'handles missing coverage distribution' do
        focused_result[:summary][:coverage_distribution] = nil
        output = capture_stdout { command.call(input_file: input_file, focus: '**/lib/**') }

        expect(output).not_to include('📈 Coverage Distribution:')
      end
    end

    context 'with full analysis mode' do
      let(:successful_result) do
        {
          success: true,
          execution_summary: {
            execution_time: 125.7,
            output_directory: './coverage_analysis',
            analysis_summary: {
              overall_coverage: 92.3,
              threshold: 85.0,
              coverage_status: 'excellent',
              total_files: 45,
              under_covered_files: 2
            },
            undercovered_summary: {
              critical_files: 1,
              high_priority_files: 3,
              total_recommendations: 8
            }
          },
          generated_reports: {
            text: './coverage_analysis/report.txt',
            json: './coverage_analysis/report.json'
          },
          create_path_results: {
            output_file: './coverage_analysis/create_path.md',
            action_required: true,
            critical_items_count: 3
          }
        }
      end

      before do
        allow(mock_workflow).to receive(:execute_full_analysis).and_return(successful_result)
      end

      it 'executes full analysis and displays comprehensive results' do
        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).to include('🔄 Executing full coverage analysis...')
        expect(output).to include('✅ Full Analysis Complete!')
        expect(output).to include('Execution time: 2m 6s')
        expect(output).to include('Output directory: ./coverage_analysis')
        expect(mock_workflow).to have_received(:execute_full_analysis)
      end

      it 'displays analysis summary' do
        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).to include('📊 Analysis Summary:')
        expect(output).to include('Overall Coverage: 92.3%')
        expect(output).to include('Threshold: 85.0%')
        expect(output).to include('Status: 🟢 Excellent')
        expect(output).to include('Files analyzed: 45')
        expect(output).to include('Files under threshold: 2')
      end

      it 'displays generated reports' do
        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).to include('📄 Generated Reports:')
        expect(output).to include('TEXT: ./coverage_analysis/report.txt')
        expect(output).to include('JSON: ./coverage_analysis/report.json')
      end

      it 'displays priority summary when there are critical files' do
        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).to include('🚨 Priority Summary:')
        expect(output).to include('Critical files: 1')
        expect(output).to include('High priority files: 3')
        expect(output).to include('Total recommendations: 8')
      end

      it 'displays create-path integration results when present' do
        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).to include('🔗 Create-Path Integration:')
        expect(output).to include('Output file: ./coverage_analysis/create_path.md')
        expect(output).to include('Action required: ✅')
        expect(output).to include('Critical items: 3')
      end

      it 'skips priority summary when no critical files' do
        successful_result[:execution_summary][:undercovered_summary] = {
          critical_files: 0,
          high_priority_files: 0,
          total_recommendations: 0
        }

        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).not_to include('🚨 Priority Summary:')
      end

      it 'skips create-path results when not present' do
        successful_result[:create_path_results] = nil

        output = capture_stdout { command.call(input_file: input_file) }

        expect(output).not_to include('🔗 Create-Path Integration:')
      end
    end

    context 'with failed full analysis' do
      let(:failed_result) do
        {
          success: false,
          error: {
            type: 'FileNotFound',
            message: 'SimpleCov file not found',
            suggestions: [
              'Ensure the file path is correct',
              'Run your test suite first to generate coverage data'
            ]
          }
        }
      end

      before do
        allow(mock_workflow).to receive(:execute_full_analysis).and_return(failed_result)
      end

      it 'displays workflow error and exits with status 1' do
        expect do
          capture_stdout { command.call(input_file: input_file) }
        end.to raise_error(SystemExit)

        expect(mock_workflow).to have_received(:execute_full_analysis)
      end

      it 'displays error details' do
        stderr_output = capture_stderr do
          expect { command.call(input_file: input_file) }.to raise_error(SystemExit)
        end

        expect(stderr_output).to include('❌ Analysis failed:')
        expect(stderr_output).to include('Error: FileNotFound - SimpleCov file not found')
      end

      it 'displays suggestions when present' do
        stderr_output = capture_stderr do
          expect { command.call(input_file: input_file) }.to raise_error(SystemExit)
        end

        expect(stderr_output).to include('💡 Suggestions:')
        expect(stderr_output).to include('• Ensure the file path is correct')
        expect(stderr_output).to include('• Run your test suite first to generate coverage data')
      end
    end

    context 'with exceptions' do
      it 'handles file not found errors' do
        allow(mock_workflow).to receive(:execute_full_analysis).and_raise(Errno::ENOENT, 'No such file')

        expect do
          capture_stderr { command.call(input_file: input_file) }
        end.to raise_error(SystemExit)
      end

      it 'handles JSON parsing errors' do
        allow(mock_workflow).to receive(:execute_full_analysis).and_raise(JSON::ParserError, 'Invalid JSON')

        stderr_output = capture_stderr do
          expect { command.call(input_file: input_file) }.to raise_error(SystemExit)
        end

        expect(stderr_output).to include('❌ Error analyzing coverage:')
        expect(stderr_output).to include('Error: JSON::ParserError - Invalid JSON')
        expect(stderr_output).to include('💡 The input file is not valid JSON')
      end

      it 'handles argument errors' do
        allow(mock_workflow).to receive(:execute_full_analysis).and_raise(ArgumentError, 'Invalid argument')

        stderr_output = capture_stderr do
          expect { command.call(input_file: input_file) }.to raise_error(SystemExit)
        end

        expect(stderr_output).to include('💡 Please check your command-line arguments and try again.')
      end

      it 'handles general errors' do
        allow(mock_workflow).to receive(:execute_full_analysis).and_raise(StandardError, 'Unknown error')

        stderr_output = capture_stderr do
          expect { command.call(input_file: input_file) }.to raise_error(SystemExit)
        end

        expect(stderr_output).to include('💡 Please check file permissions and paths, then try again.')
      end
    end
  end

  describe '#prepare_workflow_options' do
    it 'prepares default workflow options' do
      options = {
        threshold: 'auto',
        output_dir: './coverage_analysis',
        format: 'text,json',
        include_patterns: '**/lib/**/*.rb',
        exclude_patterns: '**/spec/**,**/test/**',
        detailed: false,
        create_path: false,
        max_files: 20,
        comprehensive: false,
        compact: true,
        verbose: false
      }

      result = command.send(:prepare_workflow_options, options)

      expect(result).to include(
        threshold: 85.0,
        adaptive_threshold: true,
        output_dir: './coverage_analysis',
        formats: ['text', 'json'],
        include_patterns: ['**/lib/**/*.rb'],
        exclude_patterns: ['**/spec/**', '**/test/**'],
        detailed_analysis: false,
        create_path_integration: false,
        max_files: 20,
        include_comprehensive: false,
        report_format: :compact
      )
    end

    it 'handles verbose format precedence over compact' do
      options = { compact: true, verbose: true, threshold: 'auto' }

      result = command.send(:prepare_workflow_options, options)

      expect(result[:report_format]).to eq(:verbose)
    end

    it 'uses compact format when verbose is false' do
      options = { compact: true, verbose: false, threshold: 'auto' }

      result = command.send(:prepare_workflow_options, options)

      expect(result[:report_format]).to eq(:compact)
    end

    it 'parses numeric threshold correctly' do
      options = { threshold: '92.5' }

      result = command.send(:prepare_workflow_options, options)

      expect(result[:threshold]).to eq(92.5)
      expect(result[:adaptive_threshold]).to be false
    end
  end

  describe '#parse_comma_separated' do
    it 'parses comma-separated values correctly' do
      result = command.send(:parse_comma_separated, 'value1,value2,value3')

      expect(result).to eq(['value1', 'value2', 'value3'])
    end

    it 'strips whitespace from values' do
      result = command.send(:parse_comma_separated, ' value1 , value2 , value3 ')

      expect(result).to eq(['value1', 'value2', 'value3'])
    end

    it 'rejects empty values' do
      result = command.send(:parse_comma_separated, 'value1,,value2,  ,value3')

      expect(result).to eq(['value1', 'value2', 'value3'])
    end

    it 'returns empty array for nil input' do
      result = command.send(:parse_comma_separated, nil)

      expect(result).to eq([])
    end

    it 'returns empty array for empty string' do
      result = command.send(:parse_comma_separated, '')

      expect(result).to eq([])
    end

    it 'handles single value without commas' do
      result = command.send(:parse_comma_separated, 'single_value')

      expect(result).to eq(['single_value'])
    end
  end

  describe '#parse_threshold_option' do
    it "parses 'auto' as adaptive threshold" do
      threshold, adaptive = command.send(:parse_threshold_option, 'auto')

      expect(threshold).to eq(85.0)
      expect(adaptive).to be true
    end

    it 'parses empty string as adaptive threshold' do
      threshold, adaptive = command.send(:parse_threshold_option, '')

      expect(threshold).to eq(85.0)
      expect(adaptive).to be true
    end

    it 'parses nil as adaptive threshold' do
      threshold, adaptive = command.send(:parse_threshold_option, nil)

      expect(threshold).to eq(85.0)
      expect(adaptive).to be true
    end

    it 'parses numeric string as fixed threshold' do
      threshold, adaptive = command.send(:parse_threshold_option, '92.5')

      expect(threshold).to eq(92.5)
      expect(adaptive).to be false
    end

    it 'parses integer string as fixed threshold' do
      threshold, adaptive = command.send(:parse_threshold_option, '85')

      expect(threshold).to eq(85.0)
      expect(adaptive).to be false
    end

    it 'raises error for invalid threshold value' do
      expect do
        command.send(:parse_threshold_option, 'invalid')
      end.to raise_error(ArgumentError, "Invalid threshold value: 'invalid'. Use a number (0-100) or 'auto'")
    end

    it "handles case-insensitive 'auto'" do
      threshold, adaptive = command.send(:parse_threshold_option, 'AUTO')

      expect(threshold).to eq(85.0)
      expect(adaptive).to be true
    end
  end

  describe 'format methods' do
    describe '#format_percentage' do
      it 'formats percentage correctly' do
        result = command.send(:format_percentage, 87.567)
        expect(result).to eq('87.6%')
      end

      it 'handles nil values' do
        result = command.send(:format_percentage, nil)
        expect(result).to eq('N/A')
      end

      it 'handles zero values' do
        result = command.send(:format_percentage, 0.0)
        expect(result).to eq('0.0%')
      end

      it 'handles 100 percent' do
        result = command.send(:format_percentage, 100.0)
        expect(result).to eq('100.0%')
      end
    end

    describe '#format_status' do
      it 'formats excellent status' do
        result = command.send(:format_status, 'excellent')
        expect(result).to eq('🟢 Excellent')
      end

      it 'formats good status' do
        result = command.send(:format_status, 'good')
        expect(result).to eq('🟡 Good')
      end

      it 'formats needs_improvement status' do
        result = command.send(:format_status, 'needs_improvement')
        expect(result).to eq('🟠 Needs Improvement')
      end

      it 'formats critical status' do
        result = command.send(:format_status, 'critical')
        expect(result).to eq('🔴 Critical')
      end

      it 'handles unknown status' do
        result = command.send(:format_status, 'unknown')
        expect(result).to eq('Unknown')
      end

      it 'handles symbol status' do
        result = command.send(:format_status, :good)
        expect(result).to eq('🟡 Good')
      end
    end

    describe '#format_duration' do
      it 'formats milliseconds for very short durations' do
        result = command.send(:format_duration, 0.125)
        expect(result).to eq('125ms')
      end

      it 'formats seconds for short durations' do
        result = command.send(:format_duration, 5.7)
        expect(result).to eq('5.7s')
      end

      it 'formats minutes and seconds for longer durations' do
        result = command.send(:format_duration, 125.3)
        expect(result).to eq('2m 5s')
      end

      it 'handles exact minute boundaries' do
        result = command.send(:format_duration, 120.0)
        expect(result).to eq('2m 0s')
      end

      it 'handles very long durations' do
        result = command.send(:format_duration, 3725.7)
        expect(result).to eq('62m 6s')
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
