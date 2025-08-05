# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Task::List do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_task_manager) { instance_double('CodingAgentTools::Organisms::TaskflowManagement::TaskManager') }
  let(:mock_tasks_result) { double('ListTasksResult') }
  let(:mock_sort_result) { double('SortResult') }
  let(:mock_filter_result) { { tasks: [], errors: [] } }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
  end

  describe '#call' do
    context 'with successful task retrieval' do
      let(:mock_task1) do
        double('Task',
          id: 'v.0.3.0+task.001',
          status: 'pending',
          priority: 'high',
          title: 'First task')
      end
      let(:mock_task2) do
        double('Task',
          id: 'v.0.3.0+task.002',
          status: 'done',
          priority: 'medium',
          title: 'Second task')
      end
      let(:mock_tasks) { [mock_task1, mock_task2] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        # Mock sort engine
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:default_list_sort).and_return('implementation-order')
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).and_return({ result: mock_sort_result, errors: [] })

        # Mock sort result
        allow(mock_sort_result).to receive(:sorted_tasks).and_return(mock_tasks)
        allow(mock_sort_result).to receive(:fully_sorted?).and_return(true)
        allow(mock_sort_result).to receive(:has_cycles?).and_return(false)
        allow(mock_sort_result).to receive(:sorted_count).and_return(2)
        allow(mock_sort_result).to receive(:total_count).and_return(2)
        allow(mock_sort_result).to receive(:sort_metadata).and_return({ sort_type: 'implementation-order' })

        # Mock formatter
        allow(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to receive(:format_task)

        allow(command).to receive(:puts)
      end

      it 'executes successfully with default options' do
        result = command.call

        expect(result).to eq(0)
        expect(mock_task_manager).to have_received(:get_list_tasks).with(release_path: nil)
        expect(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to have_received(:apply_sort_string).with(mock_tasks, 'implementation-order')
      end

      it 'uses specified release when provided' do
        result = command.call(release: 'v.0.4.0')

        expect(result).to eq(0)
        expect(mock_task_manager).to have_received(:get_list_tasks).with(release_path: 'v.0.4.0')
      end

      it 'formats tasks correctly with default options' do
        command.call

        expect(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to have_received(:format_task).with(
            mock_task1,
            verbose: nil,
            show_time: true,
            show_path: true
          )
        expect(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to have_received(:format_task).with(
            mock_task2,
            verbose: nil,
            show_time: true,
            show_path: true
          )
      end

      it 'formats tasks with verbose option' do
        command.call(verbose: true)

        expect(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to have_received(:format_task).with(
            mock_task1,
            verbose: true,
            show_time: true,
            show_path: false
          )
      end

      it 'applies custom sort when specified' do
        result = command.call(sort: 'priority:desc,id:asc')

        expect(result).to eq(0)
        expect(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to have_received(:apply_sort_string).with(mock_tasks, 'priority:desc,id:asc')
      end

      it 'displays header with task count' do
        command.call

        expect(command).to have_received(:puts).with('All Tasks (2 total):')
        expect(command).to have_received(:puts).with('=' * 50)
      end

      it 'displays sort metadata when available' do
        command.call

        expect(command).to have_received(:puts).with("\e[34mℹ️  Sorted by: implementation-order\e[0m")
      end
    end

    context 'with task manager failure' do
      it 'returns error when task manager fails to get tasks' do
        failed_result = double('ListTasksResult', success?: false, message: 'Failed to load tasks')
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(failed_result)
        allow(command).to receive(:error_output)

        result = command.call

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with('Error: Failed to load tasks')
      end
    end

    context 'with filtering' do
      let(:mock_tasks) do
        [
          double('Task', id: 'v.0.3.0+task.001', status: 'pending', priority: 'high'),
          double('Task', id: 'v.0.3.0+task.002', status: 'done', priority: 'medium')
        ]
      end
      let(:filtered_tasks) { [mock_tasks.first] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        # Mock filter engine
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine)
          .to receive(:apply_filter_strings).and_return({ tasks: filtered_tasks, errors: [] })

        # Mock sort engine with filtered tasks
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:default_list_sort).and_return('implementation-order')
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).with(filtered_tasks, 'implementation-order')
          .and_return({ result: mock_sort_result, errors: [] })

        allow(mock_sort_result).to receive(:sorted_tasks).and_return(filtered_tasks)
        allow(mock_sort_result).to receive(:fully_sorted?).and_return(true)
        allow(mock_sort_result).to receive(:has_cycles?).and_return(false)
        allow(mock_sort_result).to receive(:sort_metadata).and_return({})

        allow(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to receive(:format_task)
        allow(command).to receive(:puts)
      end

      it 'applies filters when specified' do
        result = command.call(filter: ['status:pending', 'priority:high'])

        expect(result).to eq(0)
        expect(CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine)
          .to have_received(:apply_filter_strings).with(mock_tasks, ['status:pending', 'priority:high'])
        expect(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to have_received(:apply_sort_string).with(filtered_tasks, 'implementation-order')
      end

      it 'handles filter errors' do
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine)
          .to receive(:apply_filter_strings).and_return({
            tasks: [],
            errors: ['Invalid filter: priority:invalid']
          })
        allow(command).to receive(:error_output)

        result = command.call(filter: ['priority:invalid'])

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with('Filter error: Invalid filter: priority:invalid')
      end
    end

    context 'with sorting errors' do
      let(:mock_tasks) { [double('Task', id: 'v.0.3.0+task.001', status: 'pending')] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).and_return({
            result: nil,
            errors: ['Invalid sort criteria: invalid:sort']
          })
        allow(command).to receive(:error_output)
      end

      it 'handles sort errors' do
        result = command.call(sort: 'invalid:sort')

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with('Sort error: Invalid sort criteria: invalid:sort')
      end
    end

    context 'with dependency cycles' do
      let(:mock_tasks) do
        [
          double('Task', id: 'v.0.3.0+task.001', status: 'pending'),
          double('Task', id: 'v.0.3.0+task.002', status: 'in-progress')
        ]
      end

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:default_list_sort).and_return('implementation-order')
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).and_return({ result: mock_sort_result, errors: [] })

        # Mock sort result with cycles
        allow(mock_sort_result).to receive(:sorted_tasks).and_return(mock_tasks)
        allow(mock_sort_result).to receive(:fully_sorted?).and_return(false)
        allow(mock_sort_result).to receive(:has_cycles?).and_return(true)
        allow(mock_sort_result).to receive(:sorted_count).and_return(1)
        allow(mock_sort_result).to receive(:total_count).and_return(2)
        allow(mock_sort_result).to receive(:sort_metadata).and_return({})

        allow(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to receive(:format_task)
        allow(command).to receive(:puts)
      end

      it 'displays cycle warning in header' do
        command.call

        expect(command).to have_received(:puts).with("\e[33m⚠️  WARNING: Dependency cycles detected!\e[0m")
        expect(command).to have_received(:puts).with("\e[33m   1/2 tasks sorted\e[0m")
      end

      it 'displays cycle information in footer when show_cycles is true' do
        command.call(show_cycles: true)

        expect(command).to have_received(:puts).with("\e[31mDependency Cycle Information:\e[0m")
        expect(command).to have_received(:puts).with("\e[32m  • 1 tasks successfully sorted\e[0m")
        expect(command).to have_received(:puts).with("\e[31m  • 1 tasks in cycles\e[0m")
        expect(command).to have_received(:puts).with("\e[33m  • Review task dependencies to resolve cycles\e[0m")
      end

      it 'displays cycle information in footer when cycles exist even without show_cycles flag' do
        command.call(show_cycles: false)

        expect(command).to have_received(:puts).with("\e[31mDependency Cycle Information:\e[0m")
      end
    end

    context 'with empty task list' do
      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return([])
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:default_list_sort).and_return('implementation-order')
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).and_return({ result: mock_sort_result, errors: [] })

        allow(mock_sort_result).to receive(:sorted_tasks).and_return([])
        allow(command).to receive(:puts)
      end

      it 'displays no tasks message' do
        result = command.call

        expect(result).to eq(0)
        expect(command).to have_received(:puts).with('No tasks found matching criteria')
      end
    end

    context 'with exception handling' do
      before do
        allow(mock_task_manager).to receive(:get_list_tasks).and_raise(StandardError, 'Unexpected error')
        allow(command).to receive(:handle_error)
      end

      it 'handles exceptions and returns error code' do
        result = command.call

        expect(result).to eq(1)
        expect(command).to have_received(:handle_error).with(
          instance_of(StandardError),
          nil
        )
      end

      it 'passes debug flag to error handler' do
        result = command.call(debug: true)

        expect(result).to eq(1)
        expect(command).to have_received(:handle_error).with(
          instance_of(StandardError),
          true
        )
      end
    end
  end

  describe '#handle_result' do
    let(:mock_task) { double('Task', id: 'v.0.3.0+task.001') }
    let(:result_with_tasks) { double('SortResult') }
    let(:result_empty) { double('SortResult') }

    before do
      allow(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
        .to receive(:format_task)
      allow(command).to receive(:puts)
      allow(command).to receive(:display_header)
      allow(command).to receive(:display_footer)
    end

    context 'with tasks' do
      before do
        allow(result_with_tasks).to receive(:sorted_tasks).and_return([mock_task])
        allow(result_with_tasks).to receive(:has_cycles?).and_return(false)
      end

      it 'displays header and formats tasks' do
        command.send(:handle_result, result_with_tasks, {})

        expect(command).to have_received(:display_header).with(result_with_tasks, {}, nil)
        expect(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to have_received(:format_task).once
      end

      it 'adds blank lines between tasks in verbose mode' do
        allow(result_with_tasks).to receive(:sorted_tasks).and_return([mock_task, mock_task])

        command.send(:handle_result, result_with_tasks, verbose: true)

        expect(command).to have_received(:puts).with('').once
      end

      it 'does not add blank lines in non-verbose mode' do
        allow(result_with_tasks).to receive(:sorted_tasks).and_return([mock_task, mock_task])

        command.send(:handle_result, result_with_tasks, verbose: false)

        expect(command).not_to have_received(:puts).with('')
      end
    end

    context 'with empty results' do
      before do
        allow(result_empty).to receive(:sorted_tasks).and_return([])
      end

      it 'displays no tasks message' do
        command.send(:handle_result, result_empty, {})

        expect(command).to have_received(:puts).with('No tasks found matching criteria')
        expect(command).not_to have_received(:display_header)
      end
    end

    context 'with cycles' do
      before do
        allow(result_with_tasks).to receive(:sorted_tasks).and_return([mock_task])
        allow(result_with_tasks).to receive(:has_cycles?).and_return(true)
      end

      it 'displays footer when cycles exist' do
        command.send(:handle_result, result_with_tasks, show_cycles: false)

        expect(command).to have_received(:display_footer).with(result_with_tasks, show_cycles: false)
      end

      it 'displays footer when show_cycles is true' do
        allow(result_with_tasks).to receive(:has_cycles?).and_return(false)

        command.send(:handle_result, result_with_tasks, show_cycles: true)

        expect(command).to have_received(:display_footer).with(result_with_tasks, show_cycles: true)
      end
    end
  end

  describe '#display_header' do
    let(:result) { double('SortResult') }

    before do
      allow(command).to receive(:puts)
      allow(command).to receive(:colorize).and_call_original
    end

    context 'with fully sorted results' do
      before do
        allow(result).to receive(:sorted_tasks).and_return([double, double])
        allow(result).to receive(:fully_sorted?).and_return(true)
        allow(result).to receive(:sort_metadata).and_return({ sort_type: 'priority' })
      end

      it 'displays basic header information' do
        command.send(:display_header, result, {})

        expect(command).to have_received(:puts).with('All Tasks (2 total):')
        expect(command).to have_received(:puts).with('=' * 50)
        expect(command).to have_received(:puts).with("\e[34mℹ️  Sorted by: priority\e[0m")
      end
    end

    context 'with partially sorted results due to cycles' do
      before do
        allow(result).to receive(:sorted_tasks).and_return([double, double])
        allow(result).to receive(:fully_sorted?).and_return(false)
        allow(result).to receive(:has_cycles?).and_return(true)
        allow(result).to receive(:sorted_count).and_return(1)
        allow(result).to receive(:total_count).and_return(2)
        allow(result).to receive(:sort_metadata).and_return({})
      end

      it 'displays cycle warning' do
        command.send(:display_header, result, {})

        expect(command).to have_received(:puts).with("\e[33m⚠️  WARNING: Dependency cycles detected!\e[0m")
        expect(command).to have_received(:puts).with("\e[33m   1/2 tasks sorted\e[0m")
      end
    end

    context 'with external dependencies' do
      before do
        allow(result).to receive(:sorted_tasks).and_return([double])
        allow(result).to receive(:fully_sorted?).and_return(false)
        allow(result).to receive(:has_cycles?).and_return(false)
        allow(result).to receive(:sort_metadata).and_return({})
      end

      it 'displays external dependencies info' do
        command.send(:display_header, result, {})

        expect(command).to have_received(:puts).with("\e[34mℹ️  Some tasks may have external dependencies\e[0m")
      end
    end
  end

  describe '#display_footer' do
    let(:result) { double('SortResult') }

    before do
      allow(command).to receive(:puts)
      allow(result).to receive(:has_cycles?).and_return(true)
      allow(result).to receive(:sorted_count).and_return(3)
      allow(result).to receive(:total_count).and_return(5)
    end

    it 'displays cycle information when cycles exist' do
      command.send(:display_footer, result, {})

      expect(command).to have_received(:puts).with('')
      expect(command).to have_received(:puts).with("\e[31mDependency Cycle Information:\e[0m")
      expect(command).to have_received(:puts).with("\e[32m  • 3 tasks successfully sorted\e[0m")
      expect(command).to have_received(:puts).with("\e[31m  • 2 tasks in cycles\e[0m")
      expect(command).to have_received(:puts).with("\e[33m  • Review task dependencies to resolve cycles\e[0m")
    end
  end

  describe '#colorize' do
    it 'applies red color' do
      result = command.send(:colorize, 'test', :red)
      expect(result).to eq("\e[31mtest\e[0m")
    end

    it 'applies green color' do
      result = command.send(:colorize, 'test', :green)
      expect(result).to eq("\e[32mtest\e[0m")
    end

    it 'applies yellow color' do
      result = command.send(:colorize, 'test', :yellow)
      expect(result).to eq("\e[33mtest\e[0m")
    end

    it 'applies blue color' do
      result = command.send(:colorize, 'test', :blue)
      expect(result).to eq("\e[34mtest\e[0m")
    end

    it 'returns unmodified text for unknown colors' do
      result = command.send(:colorize, 'test', :unknown)
      expect(result).to eq('test')
    end
  end

  describe '#handle_error' do
    let(:error) { StandardError.new('Test error message') }

    before do
      allow(command).to receive(:error_output)
      allow(error).to receive(:backtrace).and_return([
        "/path/to/file1.rb:10:in `method1'",
        "/path/to/file2.rb:20:in `method2'"
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
      it 'outputs detailed error information with backtrace' do
        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with('Error: StandardError: Test error message')
        expect(command).to have_received(:error_output).with("\nBacktrace:")
        expect(command).to have_received(:error_output).with("  /path/to/file1.rb:10:in `method1'")
        expect(command).to have_received(:error_output).with("  /path/to/file2.rb:20:in `method2'")
      end
    end

    context 'with nil backtrace' do
      it 'handles missing backtrace gracefully' do
        allow(error).to receive(:backtrace).and_return(nil)

        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with('Error: StandardError: Test error message')
        expect(command).to have_received(:error_output).with("\nBacktrace:")
      end
    end
  end

  describe '#error_output' do
    it 'outputs to stderr' do
      expect { command.send(:error_output, 'Test message') }.to output("Test message\n").to_stderr
    end
  end

  describe 'edge cases and boundary conditions' do
    context 'with conflicting options' do
      let(:mock_tasks) { [double('Task', id: 'v.0.3.0+task.001', status: 'pending')] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:default_list_sort).and_return('implementation-order')
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).and_return({ result: mock_sort_result, errors: [] })

        allow(mock_sort_result).to receive(:sorted_tasks).and_return(mock_tasks)
        allow(mock_sort_result).to receive(:fully_sorted?).and_return(true)
        allow(mock_sort_result).to receive(:has_cycles?).and_return(false)
        allow(mock_sort_result).to receive(:sort_metadata).and_return({})

        allow(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to receive(:format_task)
        allow(command).to receive(:puts)
      end

      it 'handles verbose and debug flags together' do
        result = command.call(verbose: true, debug: true)

        expect(result).to eq(0)
        expect(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to have_received(:format_task).with(
            mock_tasks.first,
            verbose: true,
            show_time: true,
            show_path: false
          )
      end

      it 'handles sort and filter options together' do
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine)
          .to receive(:apply_filter_strings).and_return({ tasks: mock_tasks, errors: [] })

        result = command.call(
          sort: 'priority:desc',
          filter: ['status:pending']
        )

        expect(result).to eq(0)
        expect(CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine)
          .to have_received(:apply_filter_strings).with(mock_tasks, ['status:pending'])
        expect(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to have_received(:apply_sort_string).with(mock_tasks, 'priority:desc')
      end
    end

    context 'with malformed data' do
      let(:mock_tasks) { [double('Task', id: 'malformed-task', status: 'pending')] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)

        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:default_list_sort).and_return('implementation-order')
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine)
          .to receive(:apply_sort_string).and_return({ result: mock_sort_result, errors: [] })

        allow(mock_sort_result).to receive(:sorted_tasks).and_return(mock_tasks)
        allow(mock_sort_result).to receive(:fully_sorted?).and_return(true)
        allow(mock_sort_result).to receive(:has_cycles?).and_return(false)
        allow(mock_sort_result).to receive(:sort_metadata).and_return({})

        allow(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to receive(:format_task)
        allow(command).to receive(:puts)
      end

      it 'handles tasks with malformed IDs gracefully' do
        result = command.call

        expect(result).to eq(0)
        expect(CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter)
          .to have_received(:format_task).with(
            mock_tasks.first,
            verbose: nil,
            show_time: true,
            show_path: true
          )
      end
    end
  end
end
