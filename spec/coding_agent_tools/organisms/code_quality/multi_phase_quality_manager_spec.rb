# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'coding_agent_tools/organisms/code_quality/multi_phase_quality_manager'

RSpec.describe CodingAgentTools::Organisms::CodeQuality::MultiPhaseQualityManager do
  let(:temp_dir) { Dir.mktmpdir('multi_phase_test') }
  let(:config_path) { File.join(temp_dir, 'config.yml') }
  let(:mock_config) do
    {
      'error_distribution' => {
        'enabled' => true,
        'max_files' => 4
      },
      'ruby' => {
        'standardrb' => { 'enabled' => true }
      },
      'markdown' => {
        'markdownlint' => { 'enabled' => true }
      }
    }
  end
  let(:manager) { described_class.new(config_path: config_path) }

  before do
    FileUtils.mkdir_p(temp_dir)
    File.write(config_path, mock_config.to_yaml)

    # Mock dependencies to avoid actual system calls
    allow_any_instance_of(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
      .to receive(:load).and_return(mock_config)
    allow_any_instance_of(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
      .to receive(:validate).and_return({ valid: true })
    allow_any_instance_of(CodingAgentTools::Atoms::CodeQuality::PathResolver)
      .to receive(:project_root).and_return(temp_dir)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe '#initialize' do
    it 'initializes with config path' do
      expect(manager.config).to eq(mock_config)
    end

    it 'initializes with default config when no path provided' do
      manager_default = described_class.new
      expect(manager_default.config).to be_a(Hash)
    end

    it 'initializes path resolver' do
      expect(manager.path_resolver).to be_a(CodingAgentTools::Atoms::CodeQuality::PathResolver)
    end

    it 'sets dry_run flag' do
      dry_manager = described_class.new(dry_run: true)
      expect(dry_manager.dry_run).to be true
    end

    it 'defaults dry_run to false' do
      expect(manager.dry_run).to be false
    end
  end

  describe '#validate_configuration' do
    it 'returns true for valid configuration' do
      expect(manager.validate_configuration).to be true
    end

    it 'returns false for invalid configuration' do
      allow_any_instance_of(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
        .to receive(:validate).and_return({ valid: false })

      expect(manager.validate_configuration).to be false
    end
  end

  describe '#run' do
    let(:mock_phase1_results) do
      {
        phase: 1,
        timestamp: Time.now,
        ruby: { total_issues: 5, success: false },
        markdown: { total_issues: 2, success: true },
        success: false
      }
    end

    let(:mock_phase2_results) do
      {
        phase: 2,
        timestamp: Time.now,
        autofix_summary: { total_fixed: 3 },
        error_distribution: { files_generated: ['error1.txt', 'error2.txt'] }
      }
    end

    let(:mock_phase3_results) do
      {
        phase: 3,
        timestamp: Time.now,
        agent_ready: true,
        error_files: ['error1.txt', 'error2.txt']
      }
    end

    before do
      allow(manager).to receive(:run_phase1).and_return(mock_phase1_results)
      allow(manager).to receive(:run_phase2).and_return(mock_phase2_results)
      allow(manager).to receive(:prepare_phase3).and_return(mock_phase3_results)
      allow(manager).to receive(:write_detailed_report)
      allow(manager).to receive(:puts) # Suppress output during tests
    end

    it 'executes all three phases' do
      expect(manager).to receive(:run_phase1)
      expect(manager).to receive(:run_phase2)
      expect(manager).to receive(:prepare_phase3)

      manager.run(autofix: true)
    end

    it 'writes detailed report when issues found' do
      expect(manager).to receive(:write_detailed_report).with(mock_phase1_results, 'all')

      manager.run
    end

    it 'skips phase 2 and 3 when autofix disabled' do
      expect(manager).to receive(:run_phase1).and_return(mock_phase1_results)
      expect(manager).not_to receive(:run_phase2)
      expect(manager).not_to receive(:prepare_phase3)

      result = manager.run(autofix: false)
      expect(result).to eq(mock_phase1_results)
    end

    it 'combines results from all phases' do
      result = manager.run(autofix: true)

      expect(result).to include(:success, :phases, :summary)
      expect(result[:phases]).to include(:phase1, :phase2, :phase3)
    end

    it 'handles different target parameters' do
      expect(manager).to receive(:run_phase1).with('ruby', ['.'], true, false)

      manager.run(target: 'ruby', autofix: true)
    end

    it 'passes through show_details parameter' do
      expect(manager).to receive(:run_phase1).with('all', ['.'], false, true)

      manager.run(show_details: true)
    end

    it 'supports custom paths' do
      custom_paths = ['src/', 'lib/']
      expect(manager).to receive(:run_phase1).with('all', custom_paths, false, false)

      manager.run(paths: custom_paths)
    end
  end

  describe '#run_phase1' do
    let(:mock_runner) { double('LanguageRunner') }
    let(:mock_validation_result) { { total_issues: 5, success: false } }
    let(:mock_autofix_result) { { total_issues: 2, success: true } }

    before do
      allow(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
        .to receive(:create_runner).and_return(mock_runner)
      allow(mock_runner).to receive(:validate).and_return(mock_validation_result)
      allow(mock_runner).to receive(:autofix).and_return(mock_autofix_result)
      allow(manager).to receive(:display_phase1_summary)
      allow(manager).to receive(:puts) # Suppress output
    end

    it 'runs validation for ruby target' do
      expect(mock_runner).to receive(:validate).with(paths: ['.'])

      manager.send(:run_phase1, 'ruby', ['.'], false, false)
    end

    it 'runs autofix when requested' do
      expect(mock_runner).to receive(:autofix).with(paths: ['.'])

      manager.send(:run_phase1, 'ruby', ['.'], true, false)
    end

    it 'runs both ruby and markdown for all target' do
      expect(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
        .to receive(:create_runner).with('ruby', anything).and_return(mock_runner)
      expect(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
        .to receive(:create_runner).with('markdown', anything).and_return(mock_runner)

      manager.send(:run_phase1, 'all', ['.'], false, false)
    end

    it 'creates diff snapshot when autofix enabled' do
      mock_diff_analyzer = double('DiffReviewAnalyzer')
      mock_snapshot = { files: ['test.rb'] }

      allow(CodingAgentTools::Molecules::CodeQuality::DiffReviewAnalyzer)
        .to receive(:new).and_return(mock_diff_analyzer)
      allow(mock_diff_analyzer).to receive(:create_snapshot).and_return(mock_snapshot)

      result = manager.send(:run_phase1, 'ruby', ['.'], true, false)
      expect(result[:before_snapshot]).to eq(mock_snapshot)
    end

    it 'calculates overall success based on all results' do
      allow(mock_runner).to receive(:validate).and_return({ success: false })

      result = manager.send(:run_phase1, 'all', ['.'], false, false)
      expect(result[:success]).to be false
    end

    it 'includes timestamp in results' do
      result = manager.send(:run_phase1, 'ruby', ['.'], false, false)
      expect(result[:timestamp]).to be_a(Time)
    end
  end

  describe '#run_phase2' do
    let(:mock_phase1_results) do
      {
        ruby: { total_issues: 5 },
        markdown: { total_issues: 2 },
        before_snapshot: { files: ['test.rb'] }
      }
    end

    let(:mock_autofix_orchestrator) { double('AutofixOrchestrator') }
    let(:mock_error_generator) { double('ErrorFileGenerator') }
    let(:mock_diff_analyzer) { double('DiffReviewAnalyzer') }

    before do
      allow(CodingAgentTools::Molecules::CodeQuality::AutofixOrchestrator)
        .to receive(:new).and_return(mock_autofix_orchestrator)
      allow(CodingAgentTools::Molecules::CodeQuality::ErrorFileGenerator)
        .to receive(:new).and_return(mock_error_generator)
      allow(CodingAgentTools::Molecules::CodeQuality::DiffReviewAnalyzer)
        .to receive(:new).and_return(mock_diff_analyzer)

      allow(mock_autofix_orchestrator).to receive(:apply_fixes).and_return({ total_fixed: 3 })
      allow(mock_autofix_orchestrator).to receive(:validate_fixes).and_return({ success: true })
      allow(mock_error_generator).to receive(:cleanup)
      allow(mock_error_generator).to receive(:generate).and_return({ files_generated: ['error1.txt'] })
      allow(mock_diff_analyzer).to receive(:create_snapshot).and_return({ files: ['test.rb'] })
      allow(mock_diff_analyzer).to receive(:analyze_changes).and_return({ summary: { files_modified: 1 } })
      allow(mock_diff_analyzer).to receive(:format_review).and_return('Review content')

      allow(manager).to receive(:display_phase2_summary)
      allow(manager).to receive(:run_phase1).and_return(mock_phase1_results)
      allow(manager).to receive(:puts) # Suppress output
      allow(File).to receive(:write) # Mock file writing
    end

    it 'applies autofixes using orchestrator' do
      expect(mock_autofix_orchestrator).to receive(:apply_fixes).with(mock_phase1_results)

      manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
    end

    it 're-validates after fixes when fixes applied' do
      allow(mock_autofix_orchestrator).to receive(:apply_fixes).and_return({ total_fixed: 5 })
      expect(manager).to receive(:run_phase1).with('all', ['.'], false, false)

      manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
    end

    it 'skips re-validation when no fixes applied' do
      allow(mock_autofix_orchestrator).to receive(:apply_fixes).and_return({ total_fixed: 0 })
      expect(manager).not_to receive(:run_phase1)

      manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
    end

    it 'generates error distribution files when enabled' do
      expect(mock_error_generator).to receive(:cleanup)
      expect(mock_error_generator).to receive(:generate).with(anything)

      manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
    end

    it 'skips error distribution when disabled' do
      disabled_config = mock_config.merge('error_distribution' => { 'enabled' => false })
      disabled_manager = described_class.new(config_path: config_path)

      # Reset mocks for this specific test
      allow(CodingAgentTools::Molecules::CodeQuality::ErrorFileGenerator).to receive(:new).and_call_original

      # Set the instance variable directly since that's what the code uses
      disabled_manager.instance_variable_set(:@config, disabled_config)
      allow(disabled_manager).to receive(:display_phase2_summary)
      allow(disabled_manager).to receive(:run_phase1).and_return(mock_phase1_results)
      allow(disabled_manager).to receive(:puts)

      # Mock the autofix orchestrator separately for this test
      test_autofix = double('AutofixOrchestrator')
      allow(test_autofix).to receive(:apply_fixes).and_return({ total_fixed: 0 })
      allow(CodingAgentTools::Molecules::CodeQuality::AutofixOrchestrator)
        .to receive(:new).and_return(test_autofix)

      # ErrorFileGenerator should not be instantiated when disabled
      expect(CodingAgentTools::Molecules::CodeQuality::ErrorFileGenerator).not_to receive(:new)

      disabled_manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
      # Test passes successfully - the important thing is ErrorFileGenerator.new wasn't called
    end

    it 'generates diff review when requested' do
      expect(mock_diff_analyzer).to receive(:analyze_changes)
      expect(mock_diff_analyzer).to receive(:format_review)
      expect(File).to receive(:write).with(anything, 'Review content')

      manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], true)
    end

    it 'skips diff review when not requested' do
      expect(mock_diff_analyzer).not_to receive(:analyze_changes)

      manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
    end

    it 'includes timestamp in results' do
      result = manager.send(:run_phase2, mock_phase1_results, 'all', ['.'], false)
      expect(result[:timestamp]).to be_a(Time)
    end
  end

  describe '#prepare_phase3' do
    let(:mock_phase2_results) do
      {
        error_distribution: {
          files_generated: ['error1.txt', 'error2.txt'],
          total_errors: 10
        }
      }
    end

    before do
      allow(manager).to receive(:display_phase3_summary)
      allow(manager).to receive(:puts) # Suppress output
    end

    it 'marks agent as ready when error files exist' do
      result = manager.send(:prepare_phase3, mock_phase2_results)

      expect(result[:agent_ready]).to be true
      expect(result[:error_files]).to eq(['error1.txt', 'error2.txt'])
    end

    it 'marks agent as not ready when no error files' do
      empty_results = { error_distribution: { files_generated: [] } }
      result = manager.send(:prepare_phase3, empty_results)

      expect(result[:agent_ready]).to be false
      expect(result[:error_files]).to eq([])
    end

    it 'prepares agent metadata when ready' do
      result = manager.send(:prepare_phase3, mock_phase2_results)

      expect(result[:agent_metadata]).to include(
        total_errors: 10,
        error_files: 2,
        workflow_instruction: 'dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md',
        parallel_agents: 4
      )
    end

    it 'handles missing error distribution gracefully' do
      result = manager.send(:prepare_phase3, {})

      expect(result[:agent_ready]).to be false
      expect(result[:error_files]).to eq([])
    end

    it 'includes timestamp in results' do
      result = manager.send(:prepare_phase3, mock_phase2_results)
      expect(result[:timestamp]).to be_a(Time)
    end
  end

  describe '#combine_results' do
    let(:phase1) { { success: true } }
    let(:phase2) { { revalidation: { success: true } } }
    let(:phase3) { { agent_ready: true } }

    it 'combines results from all phases' do
      result = manager.send(:combine_results, phase1, phase2, phase3)

      expect(result).to include(:success, :phases, :summary)
      expect(result[:phases]).to eq({ phase1: phase1, phase2: phase2, phase3: phase3 })
    end

    it 'calculates overall success correctly' do
      failing_phase2 = { revalidation: { success: false } }
      result = manager.send(:combine_results, phase1, failing_phase2, phase3)

      expect(result[:success]).to be false
    end

    it 'handles nil phase2' do
      result = manager.send(:combine_results, phase1, nil, phase3)

      expect(result[:success]).to be true
      expect(result[:phases][:phase2]).to be_nil
    end
  end

  describe '#build_final_summary' do
    let(:phase1) do
      {
        ruby: { total_issues: 10 },
        markdown: { total_issues: 5 }
      }
    end

    let(:phase2) do
      {
        autofix_summary: { total_fixed: 8 },
        diff_review: { analysis: { summary: { files_modified: 3 } } },
        error_distribution: { files_generated: ['error1.txt', 'error2.txt'] }
      }
    end

    let(:phase3) { { agent_ready: true } }

    it 'builds comprehensive summary' do
      summary = manager.send(:build_final_summary, phase1, phase2, phase3)

      expect(summary).to include(
        total_issues_found: 15,
        total_issues_fixed: 8,
        total_issues_remaining: 7,
        files_modified: 3,
        error_files_generated: 2,
        agent_ready: true
      )
    end

    it 'handles missing phase data gracefully' do
      summary = manager.send(:build_final_summary, phase1, nil, nil)

      expect(summary[:total_issues_found]).to eq(15)
      expect(summary[:total_issues_fixed]).to eq(0)
      expect(summary[:agent_ready]).to be false
    end

    it 'calculates remaining issues correctly' do
      summary = manager.send(:build_final_summary, phase1, phase2, phase3)
      expect(summary[:total_issues_remaining]).to eq(7) # 15 found - 8 fixed
    end
  end

  describe 'display methods' do
    before do
      allow(manager).to receive(:puts) # Suppress actual output
    end

    describe '#display_phase1_summary' do
      let(:results) do
        {
          success: false,
          ruby: { total_issues: 10 },
          markdown: { total_issues: 5 }
        }
      end

      it 'displays phase 1 summary without raising errors' do
        expect { manager.send(:display_phase1_summary, results) }.not_to raise_error
      end

      it 'handles missing language results' do
        minimal_results = { success: true }
        expect { manager.send(:display_phase1_summary, minimal_results) }.not_to raise_error
      end
    end

    describe '#display_phase2_summary' do
      let(:results) do
        {
          autofix_summary: { total_fixed: 5, total_failed: 1 },
          error_distribution: { files_generated: ['error1.txt', 'error2.txt'] }
        }
      end

      it 'displays phase 2 summary without raising errors' do
        expect { manager.send(:display_phase2_summary, results) }.not_to raise_error
      end
    end

    describe '#display_phase3_summary' do
      let(:results) do
        {
          agent_ready: true,
          error_files: ['error1.txt', 'error2.txt'],
          agent_metadata: { parallel_agents: 4 }
        }
      end

      it 'displays phase 3 summary without raising errors' do
        expect { manager.send(:display_phase3_summary, results) }.not_to raise_error
      end

      it 'handles agent not ready state' do
        not_ready_results = { agent_ready: false }
        expect { manager.send(:display_phase3_summary, not_ready_results) }.not_to raise_error
      end
    end
  end

  describe '#write_detailed_report' do
    let(:results) do
      {
        ruby: {
          total_issues: 5,
          linters: {
            standardrb: {
              findings: [
                { file: '/path/to/file.rb', line: 10, message: 'Style issue', cop: 'Style/Space' }
              ]
            }
          }
        },
        markdown: {
          total_issues: 2,
          linters: {
            markdownlint: {
              findings: [
                { file: '/path/to/file.md', line: 5, message: 'Header issue' }
              ]
            }
          }
        }
      }
    end

    before do
      allow(manager).to receive(:make_path_relative) { |path| path.gsub('/path/to/', '') }
    end

    it 'writes detailed report to file' do
      report_path = File.join(temp_dir, '.lint-report.md')

      manager.send(:write_detailed_report, results, 'all')

      expect(File).to exist(report_path)
      content = File.read(report_path)
      expect(content).to include('# Code Quality Report')
      expect(content).to include('**Total Issues Found**: 7')
    end

    it 'includes findings from all linters' do
      manager.send(:write_detailed_report, results, 'all')

      report_path = File.join(temp_dir, '.lint-report.md')
      content = File.read(report_path)
      expect(content).to include('STANDARDRB')
      expect(content).to include('MARKDOWNLINT')
      expect(content).to include('Style issue')
      expect(content).to include('Header issue')
    end

    it 'handles linters with errors' do
      error_results = {
        ruby: {
          total_issues: 0,
          linters: {
            standardrb: { error: 'Linter failed to run' }
          }
        }
      }

      manager.send(:write_detailed_report, error_results, 'ruby')

      report_path = File.join(temp_dir, '.lint-report.md')
      content = File.read(report_path)
      expect(content).to include('STANDARDRB (ERROR)')
      expect(content).to include('Linter failed to run')
    end

    it 'shows successful linters with no findings' do
      clean_results = {
        ruby: {
          total_issues: 0,
          linters: {
            standardrb: { findings: [] }
          }
        }
      }

      manager.send(:write_detailed_report, clean_results, 'ruby')

      report_path = File.join(temp_dir, '.lint-report.md')
      content = File.read(report_path)
      expect(content).to include('No issues found ✅')
    end
  end

  describe '#format_finding_for_report' do
    it 'formats standardrb findings correctly' do
      finding = {
        file: '/project/path/file.rb',
        line: 10,
        column: 5,
        message: 'Missing space',
        cop: 'Style/Space',
        severity: 'error'
      }

      result = manager.send(:format_finding_for_report, finding, :standardrb)
      expect(result).to include('ERROR:')
      expect(result).to include('10:5')
      expect(result).to include('Missing space')
      expect(result).to include('Style/Space')
    end

    it 'formats security findings correctly' do
      finding = 'Potential SQL injection vulnerability'

      result = manager.send(:format_finding_for_report, finding, :security)
      expect(result).to eq('Security Issue: Potential SQL injection vulnerability')
    end

    it 'formats task metadata findings correctly' do
      finding = { file: '/path/task.md', message: 'Invalid metadata' }

      result = manager.send(:format_finding_for_report, finding, :task_metadata)
      expect(result).to include('Invalid metadata')
    end

    it 'handles unknown linter types' do
      finding = 'Generic finding'

      result = manager.send(:format_finding_for_report, finding, :unknown_linter)
      expect(result).to eq('Generic finding')
    end
  end

  describe '#make_path_relative' do
    before do
      allow(manager.path_resolver).to receive(:project_root).and_return('/project/root')
    end

    it 'makes absolute paths relative' do
      absolute_path = '/project/root/src/file.rb'
      result = manager.send(:make_path_relative, absolute_path)
      expect(result).to eq('src/file.rb')
    end

    it 'returns non-absolute paths unchanged' do
      relative_path = 'src/file.rb'
      result = manager.send(:make_path_relative, relative_path)
      expect(result).to eq('src/file.rb')
    end

    it 'handles paths outside project root' do
      outside_path = '/other/path/file.rb'
      result = manager.send(:make_path_relative, outside_path)
      expect(result).to eq('/other/path/file.rb')
    end

    it 'handles nil paths' do
      result = manager.send(:make_path_relative, nil)
      expect(result).to be_nil
    end
  end

  # Integration test scenarios
  describe 'integration scenarios' do
    let(:mock_runner) { double('LanguageRunner') }

    before do
      allow(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
        .to receive(:create_runner).and_return(mock_runner)
      allow(mock_runner).to receive(:validate).and_return({ total_issues: 0, success: true })
      allow(mock_runner).to receive(:autofix).and_return({ total_issues: 0, success: true })

      # Mock all dependencies to avoid actual system calls
      mock_autofix = double('AutofixOrchestrator')
      allow(CodingAgentTools::Molecules::CodeQuality::AutofixOrchestrator)
        .to receive(:new).and_return(mock_autofix)
      allow(mock_autofix).to receive(:apply_fixes).and_return({ total_fixed: 0 })

      allow(manager).to receive(:puts) # Suppress output
    end

    it 'completes full workflow without autofix' do
      result = manager.run

      expect(result).to include(:timestamp, :ruby, :markdown, :success)
      expect(result[:success]).to be true
    end

    it 'completes full workflow with autofix' do
      result = manager.run(autofix: true)

      expect(result).to include(:success, :phases, :summary)
      expect(result[:phases]).to include(:phase1, :phase2, :phase3)
    end

    it 'handles target-specific runs' do
      result = manager.run(target: 'ruby')

      expect(result[:ruby]).not_to be_nil
      expect(result[:markdown]).to be_nil
    end

    it 'supports dry run mode' do
      dry_manager = described_class.new(dry_run: true)
      allow(dry_manager).to receive(:puts) # Suppress output

      # Should complete without errors in dry run mode
      expect { dry_manager.run }.not_to raise_error
    end
  end

  # Error handling and edge cases
  describe 'error handling and edge cases' do
    it 'handles missing config gracefully' do
      allow_any_instance_of(CodingAgentTools::Atoms::CodeQuality::ConfigurationLoader)
        .to receive(:load).and_return({})

      manager_empty = described_class.new(config_path: '/nonexistent/config.yml')
      expect(manager_empty.config).to eq({})
    end

    it 'handles runner creation failures' do
      allow(CodingAgentTools::Organisms::CodeQuality::LanguageRunnerFactory)
        .to receive(:create_runner).and_raise(StandardError, 'Runner creation failed')

      expect { manager.run(target: 'ruby') }.to raise_error(StandardError, 'Runner creation failed')
    end

    it 'handles file write errors gracefully' do
      allow(File).to receive(:open).and_raise(Errno::EACCES, 'Permission denied')

      # Should not crash the entire workflow
      expect { manager.send(:write_detailed_report, { ruby: { total_issues: 1 } }, 'all') }
        .to raise_error(Errno::EACCES)
    end

    it 'handles missing before_snapshot in phase2' do
      phase1_results = { ruby: { total_issues: 5 } } # No before_snapshot

      expect { manager.send(:run_phase2, phase1_results, 'all', ['.'], true) }
        .not_to raise_error
    end
  end

  # Performance considerations
  describe 'performance considerations' do
    it 'does not create unnecessary objects in phase1' do
      allow(manager).to receive(:puts) # Suppress output

      # Should not create diff analyzer when autofix is false - let's test differently
      result = manager.send(:run_phase1, 'ruby', ['.'], false, false)
      expect(result[:before_snapshot]).to be_nil
    end

    it 'processes large result sets efficiently' do
      large_results = {
        ruby: {
          total_issues: 1000,
          linters: {
            standardrb: {
              findings: Array.new(1000) do |i|
                {
                  file: "file#{i}.rb",
                  line: i,
                  message: "Issue #{i}",
                  cop: 'Style/Test'
                }
              end
            }
          }
        }
      }

      # Performance test - just verify it doesn't crash with large data
      expect { manager.send(:build_final_summary, large_results, nil, nil) }.not_to raise_error
    end
  end

  # Additional coverage for uncovered methods and edge cases
  describe 'display_detailed_results coverage' do
    let(:detailed_results) do
      {
        ruby: {
          linters: {
            standardrb: {
              findings: [
                { file: '/test/file.rb', line: 10, column: 5, message: 'Test', cop: 'Style/Test', severity: 'error' }
              ]
            },
            security: {
              findings: ['Security finding']
            },
            cassettes: {
              findings: [{ path: '/test/cassette.yml', size_formatted: '5MB' }]
            }
          }
        },
        markdown: {
          linters: {
            task_metadata: {
              findings: [{ file: '/test/task.md', message: 'Invalid metadata' }]
            },
            link_validation: {
              findings: [{ file: '/test/doc.md', link: 'http://broken.link' }]
            },
            template_embedding: {
              findings: [{ file: '/test/template.md', template: 'missing_template' }]
            },
            markdownlint: {
              errors: ['Markdown error 1', 'Markdown error 2']
            }
          }
        }
      }
    end

    before do
      allow(manager).to receive(:puts) # Suppress output
      allow(manager).to receive(:display_finding)
    end

    it 'displays detailed results for all linters' do
      manager.send(:display_detailed_results, detailed_results)

      # Verify that display_finding was called for each finding
      expect(manager).to have_received(:display_finding).at_least(6).times
    end

    it 'handles empty findings gracefully' do
      empty_results = {
        ruby: { linters: { standardrb: { findings: [] } } },
        markdown: { linters: { markdownlint: { findings: [] } } }
      }

      expect { manager.send(:display_detailed_results, empty_results) }.not_to raise_error
    end

    it 'handles missing linters section' do
      minimal_results = { ruby: {}, markdown: {} }

      expect { manager.send(:display_detailed_results, minimal_results) }.not_to raise_error
    end
  end

  describe 'display_finding comprehensive coverage' do
    before do
      allow(manager).to receive(:puts) # Suppress output
      allow(manager).to receive(:make_path_relative) { |path| "relative_#{path}" }
    end

    it 'formats standardrb findings with error severity' do
      finding = {
        file: '/test/file.rb',
        line: 10,
        column: 5,
        message: 'Test error',
        cop: 'Style/Test',
        severity: 'error'
      }

      expect(manager).to receive(:puts).with('    ❌ relative_/test/file.rb:10:5 - Test error (Style/Test)')
      manager.send(:display_finding, finding, :standardrb)
    end

    it 'formats standardrb findings with warning severity' do
      finding = {
        file: '/test/file.rb',
        line: 10,
        column: 5,
        message: 'Test warning',
        cop: 'Style/Test',
        severity: 'warning'
      }

      expect(manager).to receive(:puts).with('    ⚠️ relative_/test/file.rb:10:5 - Test warning (Style/Test)')
      manager.send(:display_finding, finding, :standardrb)
    end

    it 'formats security findings' do
      finding = 'SQL injection vulnerability'

      expect(manager).to receive(:puts).with('    ⚠️  Security: SQL injection vulnerability')
      manager.send(:display_finding, finding, :security)
    end

    it 'formats cassette findings' do
      finding = { path: '/test/large.yml', size_formatted: '10MB' }

      expect(manager).to receive(:puts).with('    ⚠️  relative_/test/large.yml - 10MB (threshold exceeded)')
      manager.send(:display_finding, finding, :cassettes)
    end

    it 'formats task_metadata findings with hash structure' do
      finding = { file: '/test/task.md', message: 'Invalid metadata format' }

      expect(manager).to receive(:puts).with('    ❌ relative_/test/task.md - Invalid metadata format')
      manager.send(:display_finding, finding, :task_metadata)
    end

    it 'formats task_metadata findings with unknown file' do
      finding = { message: 'Global metadata issue' }

      expect(manager).to receive(:puts).with('    ❌ unknown - Global metadata issue')
      manager.send(:display_finding, finding, :task_metadata)
    end

    it 'formats link_validation findings' do
      finding = { file: '/test/doc.md', link: 'http://broken.link' }

      expect(manager).to receive(:puts).with('    ❌ relative_/test/doc.md - http://broken.link')
      manager.send(:display_finding, finding, :link_validation)
    end

    it 'formats template_embedding findings' do
      finding = { file: '/test/template.md', template: 'missing_template' }

      expect(manager).to receive(:puts).with('    ❌ relative_/test/template.md - missing_template')
      manager.send(:display_finding, finding, :template_embedding)
    end

    it 'formats task_metadata string findings' do
      finding = 'String-based task metadata error'

      expect(manager).to receive(:puts).with('    ❌ String-based task metadata error')
      manager.send(:display_finding, finding, :task_metadata)
    end

    it 'formats unknown linter findings' do
      finding = 'Unknown linter finding'

      expect(manager).to receive(:puts).with('    • Unknown linter finding')
      manager.send(:display_finding, finding, :unknown_linter)
    end
  end

  describe 'advanced edge cases' do
    before do
      allow(manager).to receive(:puts) # Suppress output
    end

    it 'handles run with no issues found' do
      mock_clean_results = {
        phase: 1,
        timestamp: Time.now,
        ruby: { total_issues: 0, success: true },
        markdown: { total_issues: 0, success: true },
        success: true
      }

      allow(manager).to receive(:run_phase1).and_return(mock_clean_results)
      allow(manager).to receive(:write_detailed_report)

      result = manager.run
      expect(result).to eq(mock_clean_results)
      # write_detailed_report is called if ruby or markdown results exist, regardless of issue count
      expect(manager).to have_received(:write_detailed_report).with(mock_clean_results, 'all')
    end

    it 'handles run with partial target' do
      mock_ruby_results = {
        phase: 1,
        timestamp: Time.now,
        ruby: { total_issues: 5, success: false },
        markdown: nil,
        success: false
      }

      allow(manager).to receive(:run_phase1).and_return(mock_ruby_results)
      allow(manager).to receive(:write_detailed_report)

      result = manager.run(target: 'ruby')
      expect(result[:ruby]).not_to be_nil
      expect(result[:markdown]).to be_nil
    end

    it 'handles dry_run mode throughout phases' do
      dry_manager = described_class.new(dry_run: true)
      allow(dry_manager).to receive(:puts)

      mock_results = {
        phase: 1,
        ruby: { total_issues: 5, success: false },
        success: false
      }

      allow(dry_manager).to receive(:run_phase1).and_return(mock_results)

      # Should complete without calling certain operations in dry run
      expect { dry_manager.run(autofix: true) }.not_to raise_error
      expect(dry_manager.dry_run).to be true
    end
  end

  describe 'format_finding_for_report edge cases' do
    it 'handles standardrb findings with warning severity' do
      finding = {
        file: '/project/path/file.rb',
        line: 15,
        column: 8,
        message: 'Warning message',
        cop: 'Style/Warning',
        severity: 'warning'
      }

      result = manager.send(:format_finding_for_report, finding, :standardrb)
      expect(result).to include('WARNING:')
      expect(result).to include('15:8')
      expect(result).to include('Warning message')
    end

    it 'handles cassette findings formatting' do
      finding = { path: '/project/spec/cassettes/large.yml', size_formatted: '15MB' }

      result = manager.send(:format_finding_for_report, finding, :cassettes)
      expect(result).to include('Cassette Issue:')
      expect(result).to include('15MB')
      expect(result).to include('threshold exceeded')
    end

    it 'handles link_validation findings with complex structure' do
      finding = { file: '/path/doc.md', link: 'https://complex.example.com/path?param=value' }

      result = manager.send(:format_finding_for_report, finding, :link_validation)
      expect(result).to include('https://complex.example.com/path?param=value')
    end

    it 'handles template_embedding findings' do
      finding = { file: '/path/template.md', template: 'complex_template_name' }

      result = manager.send(:format_finding_for_report, finding, :template_embedding)
      expect(result).to include('complex_template_name')
    end

    it 'handles hash findings with missing fields gracefully' do
      finding = {}

      result = manager.send(:format_finding_for_report, finding, :task_metadata)
      expect(result).to include('unknown - issue')
    end
  end

  describe 'write_detailed_report comprehensive scenarios' do
    let(:complex_results) do
      {
        ruby: {
          total_issues: 3,
          linters: {
            standardrb: {
              findings: [
                { file: '/test/file1.rb', line: 5, message: 'Issue 1', cop: 'Style/One' },
                { file: '/test/file2.rb', line: 10, message: 'Issue 2', cop: 'Style/Two' }
              ]
            },
            security: { error: 'Security scanner failed' },
            cassettes: { findings: [] }
          }
        },
        markdown: {
          total_issues: 1,
          linters: {
            markdownlint: {
              errors: ['Config error', 'Parse error']
            },
            task_metadata: { findings: [] }
          }
        }
      }
    end

    before do
      allow(manager).to receive(:make_path_relative) { |path| path.gsub('/test/', '') }
      allow(manager).to receive(:format_finding_for_report) { |finding, _linter| "formatted: #{finding}" }
    end

    it 'writes report with mixed successful and error linters' do
      manager.send(:write_detailed_report, complex_results, 'all')

      report_path = File.join(temp_dir, '.lint-report.md')
      content = File.read(report_path)

      expect(content).to include('# Code Quality Report')
      expect(content).to include('**Total Issues Found**: 4')
      expect(content).to include('SECURITY (ERROR)')
      expect(content).to include('Security scanner failed')
      expect(content).to include('CASSETTES')
      expect(content).to include('No issues found ✅')
      expect(content).to include('MARKDOWNLINT ERRORS')
      expect(content).to include('Config error')
      expect(content).to include('Parse error')
    end

    it 'includes timestamp and target in report' do
      freeze_time = Time.new(2024, 1, 15, 10, 30, 0)
      allow(Time).to receive(:now).and_return(freeze_time)

      manager.send(:write_detailed_report, complex_results, 'ruby')

      report_path = File.join(temp_dir, '.lint-report.md')
      content = File.read(report_path)

      expect(content).to include('**Generated**: 2024-01-15 10:30:00')
      expect(content).to include('**Target**: ruby')
    end

    it 'includes next steps section' do
      manager.send(:write_detailed_report, complex_results, 'all')

      report_path = File.join(temp_dir, '.lint-report.md')
      content = File.read(report_path)

      expect(content).to include('## Next Steps')
      expect(content).to include('code-lint --autofix')
      expect(content).to include('Re-run `code-lint` to verify')
    end
  end

  describe 'make_path_relative boundary conditions' do
    before do
      allow(manager.path_resolver).to receive(:project_root).and_return('/project/root')
    end

    it 'handles empty string paths' do
      result = manager.send(:make_path_relative, '')
      expect(result).to eq('')
    end

    it 'handles relative paths that look absolute' do
      fake_absolute = 'project/root/src/file.rb'
      result = manager.send(:make_path_relative, fake_absolute)
      expect(result).to eq('project/root/src/file.rb')
    end

    it 'handles paths with trailing slashes' do
      absolute_path = '/project/root/src/'
      result = manager.send(:make_path_relative, absolute_path)
      expect(result).to eq('src/')
    end
  end
end
