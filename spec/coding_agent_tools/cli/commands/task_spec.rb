# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/cli/commands/task/next'
require 'coding_agent_tools/cli/commands/task/recent'
require 'coding_agent_tools/cli/commands/task/list'
require 'coding_agent_tools/cli/commands/task/generate_id'

RSpec.describe 'Task CLI Commands' do
  let(:output) { StringIO.new }

  before do
    allow($stdout).to receive(:puts) { |msg| output.puts(msg) }
    allow($stdout).to receive(:print) { |msg| output.print(msg) }
  end

  describe CodingAgentTools::Cli::Commands::Task::Next do
    subject(:command) { described_class.new }

    describe '#call' do
      context 'with valid arguments' do
        it 'validates limit option' do
          allow(command).to receive(:warn)
          result = command.call(limit: -1)
          expect(result).to eq(1)
          expect(command).to have_received(:warn).with(/Limit must be a positive integer/)
        end

        it 'validates limit option with zero' do
          allow(command).to receive(:warn)
          result = command.call(limit: 0)
          expect(result).to eq(1)
          expect(command).to have_received(:warn).with(/Limit must be a positive integer/)
        end

        it 'accepts positive limit values' do
          # Mock the TaskManager to avoid actual file system operations
          mock_task_manager = double('TaskManager')
          mock_result = double('ListTasksResult', success?: true, tasks: [])

          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_result)

          expect { command.call(limit: 1) }.not_to raise_error
        end
      end

      context 'error handling' do
        it 'handles TaskManager errors gracefully' do
          mock_task_manager = double('TaskManager')
          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_raise(StandardError.new('Test error'))

          allow(command).to receive(:warn)
          expect(command.call).to eq(1)
          expect(command).to have_received(:warn).with(/Error: Test error/)
        end

        it 'shows debug information when debug flag is set' do
          mock_task_manager = double('TaskManager')
          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_raise(StandardError.new('Test error'))

          allow(command).to receive(:warn)
          expect(command.call(debug: true)).to eq(1)
          expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
          expect(command).to have_received(:warn).with(/Backtrace:/)
        end
      end

      context 'with mocked successful results' do
        let(:mock_task_manager) { double('TaskManager') }
        let(:mock_task) do
          double('Task',
            id: 'v.0.3.0+task.01',
            title: 'Test Task',
            path: '/path/to/task.md',
            status: 'pending',
            dependencies: [])
        end
        let(:mock_result) { double('ListTasksResult', success?: true, tasks: [mock_task]) }

        before do
          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_result)
        end

        it 'displays task information for single task in compact format' do
          command.call(limit: 1)

          output_content = output.string
          expect(output_content).to include('v.0.3.0+task.01 * PENDING * Test Task')
        end

        it 'displays task information for single task in verbose format' do
          command.call(limit: 1, verbose: true)

          output_content = output.string
          expect(output_content).to include('Title: Test Task')
          expect(output_content).to include('Path: /path/to/task.md')
          expect(output_content).to include('Status: pending')
        end
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Task::Recent do
    subject(:command) { described_class.new }

    describe '#call' do
      context 'with valid arguments' do
        it 'validates limit option' do
          allow(command).to receive(:warn)
          result = command.call(limit: -1)
          expect(result).to eq(1)
          expect(command).to have_received(:warn).with(/Limit must be a positive integer/)
        end

        it 'parses time periods correctly' do
          expect(command.send(:parse_time_period, '2.days')).to eq(2 * 24 * 60 * 60)
          expect(command.send(:parse_time_period, '1.week')).to eq(7 * 24 * 60 * 60)
          expect(command.send(:parse_time_period, '3.hours')).to eq(3 * 60 * 60)
          expect(command.send(:parse_time_period, 'invalid')).to eq(24 * 60 * 60) # default
        end

        it 'accepts valid time period formats' do
          mock_task_manager = double('TaskManager')
          mock_result = double('RecentTasksResult', success?: true, tasks: [])
          mock_list_result = double('ListTasksResult', success?: true, tasks: [])

          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:find_recent_tasks).and_return(mock_result)
          allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_list_result)

          expect { command.call(last: '2.days', limit: 5) }.not_to raise_error
        end
      end

      context 'error handling' do
        it 'handles TaskManager errors gracefully' do
          mock_task_manager = double('TaskManager')
          mock_list_result = double('ListTasksResult', success?: true, tasks: [])

          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_list_result)
          allow(mock_task_manager).to receive(:find_recent_tasks).and_raise(StandardError.new('Test error'))

          allow(command).to receive(:warn)
          expect(command.call).to eq(1)
          expect(command).to have_received(:warn).with(/Error: Test error/)
        end
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Task::List do
    subject(:command) { described_class.new }

    describe '#call' do
      context 'with valid arguments' do
        it 'handles successful results' do
          mock_task_manager = double('TaskManager')
          mock_result = double('ListTasksResult', success?: true, tasks: [], has_cycles?: false, fully_sorted?: true)

          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_result)

          expect(command.call).to eq(0)
        end
      end

      context 'colorization' do
        it 'provides correct colors for different statuses' do
          expect(command.send(:status_color_for, 'done')).to eq(:green)
          expect(command.send(:status_color_for, 'in-progress')).to eq(:blue)
          expect(command.send(:status_color_for, 'pending')).to eq(:yellow)
          expect(command.send(:status_color_for, 'blocked')).to eq(:red)
          expect(command.send(:status_color_for, 'unknown')).to eq(:default)
        end

        it 'provides correct colors for different priorities' do
          expect(command.send(:priority_color_for, 'high')).to eq(:red)
          expect(command.send(:priority_color_for, 'medium')).to eq(:yellow)
          expect(command.send(:priority_color_for, 'low')).to eq(:green)
          expect(command.send(:priority_color_for, 'unknown')).to eq(:default)
        end
      end

      context 'error handling' do
        it 'handles TaskManager errors gracefully' do
          mock_task_manager = double('TaskManager')
          allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
          allow(mock_task_manager).to receive(:get_list_tasks).and_raise(StandardError.new('Test error'))

          allow(command).to receive(:warn)
          expect(command.call).to eq(1)
          expect(command).to have_received(:warn).with(/Error: Test error/)
        end
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Task::GenerateId do
    subject(:command) { described_class.new }

    describe '#call' do
      context 'with valid arguments' do
        it 'validates limit option' do
          allow(command).to receive(:warn)
          result = command.call(limit: -1)
          expect(result).to eq(1)
          expect(command).to have_received(:warn).with(/Limit must be a positive integer/)
        end

        it 'accepts positive limit values' do
          # Mock file system operations
          allow(command).to receive(:find_current_release_directory).and_return('/path/to/release')
          allow(command).to receive(:find_next_task_number).and_return(5)

          expect { command.call(version: 'v.0.3.0', limit: 3) }.not_to raise_error
        end
      end

      context 'version detection' do
        it 'extracts version from directory names correctly' do
          allow(command).to receive(:find_current_release_directory).and_return('/path/to/v.0.3.0-migration')

          version = command.send(:detect_current_version)
          expect(version).to eq('v.0.3.0')
        end

        it 'handles missing version gracefully' do
          allow(command).to receive(:find_current_release_directory).and_return(nil)

          version = command.send(:detect_current_version)
          expect(version).to be_nil
        end
      end

      context 'ID generation' do
        it 'generates single ID correctly' do
          command.send(:generate_task_ids, 'v.0.3.0', 5, 1)

          output_content = output.string
          expect(output_content).to include('v.0.3.0+task.005')
        end

        it 'generates multiple IDs correctly' do
          command.send(:generate_task_ids, 'v.0.3.0', 5, 3)

          output_content = output.string
          expect(output_content).to include('Generated 3 task IDs:')
          expect(output_content).to include('v.0.3.0+task.005')
          expect(output_content).to include('v.0.3.0+task.006')
          expect(output_content).to include('v.0.3.0+task.007')
        end
      end

      context 'error handling' do
        it 'handles missing version error' do
          allow(command).to receive(:detect_current_version).and_return(nil)
          allow(command).to receive(:warn)

          expect(command.call).to eq(1)
          expect(command).to have_received(:warn).with(/Could not determine release version/)
        end

        it 'handles general errors gracefully' do
          allow(command).to receive(:detect_current_version).and_raise(StandardError.new('Test error'))
          allow(command).to receive(:warn)

          expect(command.call(debug: true)).to eq(1)
          expect(command).to have_received(:warn).with(/Error: StandardError: Test error/)
        end
      end
    end
  end
end
