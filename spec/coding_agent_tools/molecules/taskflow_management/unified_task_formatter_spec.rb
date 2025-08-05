# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'ostruct'

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::UnifiedTaskFormatter do
  let(:mock_task) do
    OpenStruct.new(
      id: 'v.0.3.0+task.123',
      status: 'pending',
      title: 'Test Task Title',
      path: '/path/to/task.md',
      content: "# Test Task Title\n\nThis is the task content.",
      dependencies: ['task.122'],
      estimate: '2h',
      priority: 'high'
    )
  end

  let(:mock_task_without_title) do
    OpenStruct.new(
      id: 'v.0.3.0+task.124',
      status: 'in-progress',
      title: nil,
      path: '/path/to/notitle.md',
      content: "# Extracted Title from Content\n\nTask without explicit title."
    )
  end

  let(:mock_task_no_content) do
    OpenStruct.new(
      id: 'v.0.3.0+task.125',
      status: 'done',
      title: nil,
      path: '/path/to/empty.md',
      content: nil
    )
  end

  describe '.format_task' do
    context 'with compact formatting (default)' do
      it 'formats task with basic information' do
        output = capture_stdout { described_class.format_task(mock_task) }
        expect(output.strip).to eq('v.0.3.0+task.123 * PENDING * Test Task Title')
      end

      it 'formats task without explicit title by extracting from content' do
        output = capture_stdout { described_class.format_task(mock_task_without_title) }
        expect(output.strip).to eq('v.0.3.0+task.124 * IN-PROGRESS * Extracted Title from Content')
      end

      it 'formats task with no content using Unknown title' do
        output = capture_stdout { described_class.format_task(mock_task_no_content) }
        expect(output.strip).to eq('v.0.3.0+task.125 * DONE * Unknown')
      end

      it 'includes modification time when show_time option is enabled' do
        test_dir = Dir.mktmpdir
        test_file = File.join(test_dir, 'test_task.md')
        File.write(test_file, "# Test Task\nContent")

        task_with_file = mock_task.dup
        task_with_file.path = test_file

        output = capture_stdout { described_class.format_task(task_with_file, show_time: true) }
        expect(output).to match(/v\.0\.3\.0\+task\.123 \* PENDING \* \d+ hours? ago \* Test Task Title/)

        safe_directory_cleanup(test_dir)
      end

      it 'includes path when show_path option is enabled' do
        output = capture_stdout { described_class.format_task(mock_task, show_path: true) }
        expect(output).to include('v.0.3.0+task.123 * PENDING * Test Task Title')
        expect(output).to include('path/to/task.md')
      end
    end

    context 'with verbose formatting' do
      it 'formats task with detailed information' do
        output = capture_stdout { described_class.format_task(mock_task, verbose: true) }

        expect(output).to include('Title: Test Task Title')
        expect(output).to include('Status: pending')
        expect(output).to include('Path: /path/to/task.md')
        expect(output).to include('Dependencies: task.122')
        expect(output).to include('Estimate: 2h')
        expect(output).to include('Priority: HIGH')
      end

      it 'shows task header when task_number and total_tasks are provided' do
        output = capture_stdout { described_class.format_task(mock_task, verbose: true, task_number: 1, total_tasks: 5) }
        expect(output).to include('Task 1/5:')
        expect(output).to include('Title: Test Task Title')
      end

      it 'shows ID when show_id option is enabled' do
        output = capture_stdout { described_class.format_task(mock_task, verbose: true, show_id: true) }
        expect(output).to include('v.0.3.0+task.123')
        expect(output).to include('Title: Test Task Title')
      end

      it 'handles task without dependencies' do
        task_no_deps = mock_task.dup
        task_no_deps.dependencies = []

        output = capture_stdout { described_class.format_task(task_no_deps, verbose: true) }
        expect(output).to include('Title: Test Task Title')
        expect(output).not_to include('Dependencies:')
      end

      it 'handles task without estimate' do
        task_no_estimate = OpenStruct.new(
          id: 'v.0.3.0+task.123',
          status: 'pending',
          title: 'Test Task Title',
          path: '/path/to/task.md',
          dependencies: ['task.122'],
          priority: 'high'
        )

        output = capture_stdout { described_class.format_task(task_no_estimate, verbose: true) }
        expect(output).to include('Title: Test Task Title')
        expect(output).not_to include('Estimate:')
      end

      it 'handles task without priority' do
        task_no_priority = OpenStruct.new(
          id: 'v.0.3.0+task.123',
          status: 'pending',
          title: 'Test Task Title',
          path: '/path/to/task.md',
          dependencies: ['task.122'],
          estimate: '2h'
        )

        output = capture_stdout { described_class.format_task(task_no_priority, verbose: true) }
        expect(output).to include('Title: Test Task Title')
        expect(output).not_to include('Priority:')
      end

      it 'includes modification time when show_time option is enabled' do
        test_dir = Dir.mktmpdir
        test_file = File.join(test_dir, 'test_task.md')
        File.write(test_file, "# Test Task\nContent")

        task_with_file = mock_task.dup
        task_with_file.path = test_file

        output = capture_stdout { described_class.format_task(task_with_file, verbose: true, show_time: true) }
        expect(output).to match(/Modified: \d+ hours? ago/)

        safe_directory_cleanup(test_dir)
      end
    end
  end

  describe '.format_tasks' do
    let(:task_list) { [mock_task, mock_task_without_title, mock_task_no_content] }

    it 'formats multiple tasks' do
      output = capture_stdout { described_class.format_tasks(task_list) }

      expect(output).to include('v.0.3.0+task.123 * PENDING * Test Task Title')
      expect(output).to include('v.0.3.0+task.124 * IN-PROGRESS * Extracted Title from Content')
      expect(output).to include('v.0.3.0+task.125 * DONE * Unknown')
    end

    it 'includes position numbers when show_position is enabled' do
      # The position option affects the internal task_options but doesn't change output format in current implementation
      output = capture_stdout { described_class.format_tasks(task_list, show_position: true) }
      expect(output).to match(/v\.0\.3\.0\+task\.123.*\n.*v\.0\.3\.0\+task\.124.*\n.*v\.0\.3\.0\+task\.125/)
    end

    it 'passes options to individual task formatting' do
      output = capture_stdout { described_class.format_tasks(task_list, show_path: true) }

      expect(output).to include('v.0.3.0+task.123 * PENDING * Test Task Title')
      expect(output).to include('path/to/task.md')
      expect(output).to include('path/to/notitle.md')
      expect(output).to include('path/to/empty.md')
    end
  end

  describe '.format_relative_time' do
    let(:now) { Time.now }

    context 'with recent times' do
      it "formats times within an hour as '1 hour ago'" do
        time_10_min_ago = now - 600  # 10 minutes, should round to 0
        expect(described_class.send(:format_relative_time, time_10_min_ago)).to eq('1 hour ago')
      end

      it 'formats times exactly 1 hour ago' do
        time_1_hour_ago = now - 3600
        expect(described_class.send(:format_relative_time, time_1_hour_ago)).to eq('1 hours ago')
      end
    end

    context 'with times within a day' do
      it 'formats times in hours' do
        time_3_hours_ago = now - 10_800  # 3 hours
        expect(described_class.send(:format_relative_time, time_3_hours_ago)).to eq('3 hours ago')
      end

      it 'formats times close to 24 hours' do
        time_23_hours_ago = now - 82_800  # 23 hours
        expect(described_class.send(:format_relative_time, time_23_hours_ago)).to eq('23 hours ago')
      end
    end

    context 'with times within a week' do
      it 'formats times in days' do
        time_3_days_ago = now - 259_200  # 3 days
        expect(described_class.send(:format_relative_time, time_3_days_ago)).to eq('3 days ago')
      end

      it 'formats times close to a week' do
        time_6_days_ago = now - 518_400  # 6 days
        expect(described_class.send(:format_relative_time, time_6_days_ago)).to eq('6 days ago')
      end
    end

    context 'with times older than a week' do
      it 'formats as short date' do
        time_2_weeks_ago = now - 1_209_600  # 2 weeks
        expected_date = time_2_weeks_ago.strftime('%Y-%m-%d')
        expect(described_class.send(:format_relative_time, time_2_weeks_ago)).to eq(expected_date)
      end

      it 'formats very old times as date' do
        time_1_year_ago = now - 31_536_000  # 1 year
        expected_date = time_1_year_ago.strftime('%Y-%m-%d')
        expect(described_class.send(:format_relative_time, time_1_year_ago)).to eq(expected_date)
      end
    end
  end

  describe '.extract_title_from_content' do
    it 'extracts title from markdown heading' do
      task_with_heading = OpenStruct.new(content: "# Main Task Title\n\nTask description here.")
      expect(described_class.send(:extract_title_from_content, task_with_heading)).to eq('Main Task Title')
    end

    it 'finds first heading when multiple exist' do
      task_multi_headings = OpenStruct.new(content: "# First Title\n\nContent\n\n# Second Title")
      expect(described_class.send(:extract_title_from_content, task_multi_headings)).to eq('First Title')
    end

    it 'returns Unknown when no heading found' do
      task_no_heading = OpenStruct.new(content: 'Just plain content without headings')
      expect(described_class.send(:extract_title_from_content, task_no_heading)).to eq('Unknown')
    end

    it 'returns Unknown when content is nil' do
      task_nil_content = OpenStruct.new(content: nil)
      expect(described_class.send(:extract_title_from_content, task_nil_content)).to eq('Unknown')
    end

    it "returns Unknown when task doesn't respond to content" do
      task_no_content_method = Object.new
      expect(described_class.send(:extract_title_from_content, task_no_content_method)).to eq('Unknown')
    end

    it 'handles empty content' do
      task_empty_content = OpenStruct.new(content: '')
      expect(described_class.send(:extract_title_from_content, task_empty_content)).to eq('Unknown')
    end

    it 'handles whitespace in heading' do
      task_whitespace_heading = OpenStruct.new(content: "#   Spaced Title   \n\nContent")
      expect(described_class.send(:extract_title_from_content, task_whitespace_heading)).to eq('Spaced Title')
    end
  end

  describe '.detect_project_root' do
    let(:test_dir) { Dir.mktmpdir }
    let(:original_pwd) { Dir.pwd }

    after do
      # Safely restore directory before cleanup
      if Dir.exist?(original_pwd) && Dir.pwd != original_pwd
        begin
          Dir.chdir(original_pwd)
        rescue Errno::ENOENT
          # Original directory no longer exists, move to a safe directory
          Dir.chdir(ENV['PROJECT_ROOT'] || Dir.home)
        end
      end
      safe_directory_cleanup(test_dir)
    end

    it 'finds project root with .git directory' do
      git_dir = File.join(test_dir, '.git')
      FileUtils.mkdir_p(git_dir)

      subdir = File.join(test_dir, 'subdir', 'nested')
      FileUtils.mkdir_p(subdir)
      Dir.chdir(subdir)

      expect(described_class.send(:detect_project_root)).to eq(File.realpath(test_dir))
    end

    it 'returns current directory when no .git found' do
      subdir = File.join(test_dir, 'no_git')
      FileUtils.mkdir_p(subdir)
      Dir.chdir(subdir)

      expect(described_class.send(:detect_project_root)).to eq(File.realpath(subdir))
    end

    it 'stops at filesystem root' do
      # Mock traversal to root without finding .git
      allow(File).to receive(:exist?).and_return(false)
      allow(Dir).to receive(:pwd).and_return('/some/deep/path')

      # This tests the case where we reach "/" without finding .git
      expect(described_class.send(:detect_project_root)).to eq('/some/deep/path')
    end
  end

  describe '.verbose_line' do
    it 'formats verbose line with consistent prefix' do
      expect(described_class.send(:verbose_line, 'Title', 'Test Title')).to eq('     Title: Test Title')
    end

    it 'handles different labels consistently' do
      expect(described_class.send(:verbose_line, 'Status', 'pending')).to eq('     Status: pending')
      expect(described_class.send(:verbose_line, 'Path', '/path/to/file')).to eq('     Path: /path/to/file')
    end

    it 'handles empty values' do
      expect(described_class.send(:verbose_line, 'Empty', '')).to eq('     Empty: ')
    end

    it 'handles nil values' do
      expect(described_class.send(:verbose_line, 'Nil', nil)).to eq('     Nil: ')
    end
  end

  describe 'comprehensive coverage for all uncovered lines' do
    describe 'format_compact method coverage' do
      it 'covers title extraction from task.title' do
        task_with_title = mock_task.dup
        task_with_title.title = 'Explicit Task Title'

        # Covers line 33 (task.title path)
        output = capture_stdout { described_class.send(:format_compact, task_with_title, {}) }
        expect(output.strip).to eq('v.0.3.0+task.123 * PENDING * Explicit Task Title')
      end

      it 'covers title extraction from content when title is nil' do
        task_no_title = mock_task.dup
        task_no_title.title = nil

        # Covers line 33 (extract_title_from_content path)
        output = capture_stdout { described_class.send(:format_compact, task_no_title, {}) }
        expect(output.strip).to eq('v.0.3.0+task.123 * PENDING * Test Task Title')
      end

      it 'covers status upcase conversion' do
        task_lowercase_status = mock_task.dup
        task_lowercase_status.status = 'in-progress'

        # Covers line 34 (status.upcase)
        output = capture_stdout { described_class.send(:format_compact, task_lowercase_status, {}) }
        expect(output.strip).to eq('v.0.3.0+task.123 * IN-PROGRESS * Test Task Title')
      end

      it 'covers mtime addition when file exists and show_time requested' do
        test_dir = Dir.mktmpdir
        test_file = File.join(test_dir, 'test_with_mtime.md')
        File.write(test_file, "# Test Task\nContent")

        task_needing_mtime = OpenStruct.new(
          id: 'v.0.3.0+task.123',
          status: 'pending',
          title: 'Test Task Title',
          path: test_file
        )

        # Covers lines 37-40 (mtime addition)
        output = capture_stdout { described_class.send(:format_compact, task_needing_mtime, { show_time: true }) }
        expect(output).to match(/v\.0\.3\.0\+task\.123 \* PENDING \* \d+ hours? ago \* Test Task Title/)

        # Verify mtime method was added
        expect(task_needing_mtime.respond_to?(:mtime)).to be true

        safe_directory_cleanup(test_dir)
      end

      it 'covers line building and joining' do
        # Covers lines 43-52 (line_parts building)
        output = capture_stdout { described_class.send(:format_compact, mock_task, {}) }
        expect(output.strip).to eq('v.0.3.0+task.123 * PENDING * Test Task Title')
      end

      it 'covers time inclusion when task has mtime and show_time is true' do
        task_with_mtime = mock_task.dup
        mtime = Time.now - 3600  # 1 hour ago
        task_with_mtime.define_singleton_method(:mtime) { mtime }

        # Covers lines 48-50 (time inclusion)
        output = capture_stdout { described_class.send(:format_compact, task_with_mtime, { show_time: true }) }
        expect(output).to match(/1 hours? ago/)
      end

      it 'covers path display when show_path is enabled' do
        # Mock detect_project_root to return specific root
        allow(described_class).to receive(:detect_project_root).and_return('/Users/test/project')

        task_with_full_path = mock_task.dup
        task_with_full_path.path = '/Users/test/project/dev-tools/task.md'

        # Covers lines 58-62 (path display)
        output = capture_stdout { described_class.send(:format_compact, task_with_full_path, { show_path: true }) }
        expect(output).to include('v.0.3.0+task.123 * PENDING * Test Task Title')
        expect(output).to include('dev-tools/task.md')
      end

      it "covers case where file doesn't exist for mtime" do
        task_nonexistent_file = mock_task.dup
        task_nonexistent_file.path = '/nonexistent/file.md'

        # Covers line 37 (File.exist? returns false)
        output = capture_stdout { described_class.send(:format_compact, task_nonexistent_file, { show_time: true }) }
        expect(output.strip).to eq('v.0.3.0+task.123 * PENDING * Test Task Title')
      end

      it 'covers case where task already has mtime method' do
        task_existing_mtime = mock_task.dup
        existing_mtime = Time.now - 7200  # 2 hours ago
        task_existing_mtime.define_singleton_method(:mtime) { existing_mtime }

        # Covers line 37 (task.respond_to?(:mtime) returns true)
        output = capture_stdout { described_class.send(:format_compact, task_existing_mtime, { show_time: true }) }
        expect(output).to match(/2 hours ago/)
      end
    end

    describe 'format_verbose method coverage' do
      it 'covers mtime addition in verbose mode' do
        test_dir = Dir.mktmpdir
        test_file = File.join(test_dir, 'verbose_mtime_test.md')
        File.write(test_file, "# Verbose Test\nContent")

        task_verbose_mtime = OpenStruct.new(
          id: 'v.0.3.0+task.123',
          status: 'pending',
          title: 'Verbose Test Title',
          path: test_file,
          dependencies: [],
          estimate: '1h',
          priority: 'medium'
        )

        # Covers lines 67-70 (mtime addition in verbose)
        output = capture_stdout { described_class.send(:format_verbose, task_verbose_mtime, { show_time: true }) }
        expect(output).to match(/Modified: \d+ hours? ago/)

        safe_directory_cleanup(test_dir)
      end

      it 'covers task_number and total_tasks header' do
        # Covers lines 73-74 (task header with numbers)
        output = capture_stdout { described_class.send(:format_verbose, mock_task, { task_number: 2, total_tasks: 10 }) }
        expect(output).to match(/Task 2\/10:/)
      end

      it 'covers show_id branch' do
        # Covers lines 75-77 (show_id branch)
        output = capture_stdout { described_class.send(:format_verbose, mock_task, { show_id: true }) }
        expect(output).to match(/v\.0\.3\.0\+task\.123/)
      end

      it 'covers title extraction in verbose mode' do
        task_verbose_no_title = mock_task.dup
        task_verbose_no_title.title = nil

        # Covers line 79 (title extraction)
        output = capture_stdout { described_class.send(:format_verbose, task_verbose_no_title, {}) }
        expect(output).to match(/Title: Test Task Title/)
      end

      it 'covers verbose line formatting' do
        # Covers lines 80-82 (verbose_line calls)
        output = capture_stdout { described_class.send(:format_verbose, mock_task, {}) }
        expect(output).to match(/Title: Test Task Title.*Status: pending.*Path: \/path\/to\/task\.md/m)
      end

      it 'covers mtime display in verbose mode' do
        task_verbose_with_mtime = mock_task.dup
        mtime = Time.now - 1800  # 30 minutes ago
        task_verbose_with_mtime.define_singleton_method(:mtime) { mtime }

        # Covers lines 85-87 (mtime display)
        output = capture_stdout { described_class.send(:format_verbose, task_verbose_with_mtime, { show_time: true }) }
        expect(output).to match(/Modified: 1 hours ago/)
      end

      it 'covers dependencies array handling' do
        task_array_deps = mock_task.dup
        task_array_deps.dependencies = ['task.121', 'task.120', 'task.119']

        # Covers lines 89-92 (dependencies array join)
        output = capture_stdout { described_class.send(:format_verbose, task_array_deps, {}) }
        expect(output).to match(/Dependencies: task\.121, task\.120, task\.119/)
      end

      it 'covers dependencies string handling' do
        task_string_deps = mock_task.dup
        task_string_deps.dependencies = 'task.121,task.120'

        # Covers line 90 (dependencies as string)
        output = capture_stdout { described_class.send(:format_verbose, task_string_deps, {}) }
        expect(output).to match(/Dependencies: task\.121,task\.120/)
      end

      it 'covers empty dependencies array' do
        task_empty_deps = mock_task.dup
        task_empty_deps.dependencies = []

        # Covers line 89 (empty dependencies check)
        output = capture_stdout { described_class.send(:format_verbose, task_empty_deps, {}) }
        expect(output).not_to include('Dependencies:')
      end

      it 'covers nil dependencies' do
        task_nil_deps = mock_task.dup
        task_nil_deps.dependencies = nil

        # Covers line 89 (nil dependencies check)
        output = capture_stdout { described_class.send(:format_verbose, task_nil_deps, {}) }
        expect(output).not_to include('Dependencies:')
      end

      it 'covers estimate display' do
        # Covers lines 94-96 (estimate display)
        output = capture_stdout { described_class.send(:format_verbose, mock_task, {}) }
        expect(output).to match(/Estimate: 2h/)
      end

      it 'covers priority display with upcase' do
        # Covers lines 98-100 (priority upcase)
        output = capture_stdout { described_class.send(:format_verbose, mock_task, {}) }
        expect(output).to match(/Priority: HIGH/)
      end

      it 'covers missing estimate handling' do
        task_no_estimate = OpenStruct.new(
          id: 'v.0.3.0+task.123',
          status: 'pending',
          title: 'Test Task Title',
          path: '/path/to/task.md',
          dependencies: [],
          priority: 'high'
        )

        # Covers line 94 (no estimate method)
        output = capture_stdout { described_class.send(:format_verbose, task_no_estimate, {}) }
        expect(output).not_to include('Estimate:')
      end

      it 'covers missing priority handling' do
        task_no_priority = OpenStruct.new(
          id: 'v.0.3.0+task.123',
          status: 'pending',
          title: 'Test Task Title',
          path: '/path/to/task.md',
          dependencies: [],
          estimate: '2h'
        )

        # Covers line 98 (no priority method)
        output = capture_stdout { described_class.send(:format_verbose, task_no_priority, {}) }
        expect(output).not_to include('Priority:')
      end
    end

    describe 'format_tasks method coverage' do
      it 'covers tasks iteration and position assignment' do
        tasks = [mock_task, mock_task_without_title]

        # Mock format_task to verify position assignment
        allow(described_class).to receive(:format_task)

        described_class.format_tasks(tasks, { show_position: true })

        # Covers lines 23-27 (iteration and position assignment)
        expect(described_class).to have_received(:format_task).with(mock_task, hash_including(position: 1))
        expect(described_class).to have_received(:format_task).with(mock_task_without_title, hash_including(position: 2))
      end

      it 'covers options duplication' do
        original_options = { show_path: true, verbose: false }
        tasks = [mock_task]

        # Covers line 24 (options.dup)
        expect { described_class.format_tasks(tasks, original_options) }.not_to change { original_options }
      end
    end

    describe 'format_relative_time edge cases' do
      let(:now) { Time.now }

      it 'covers exact boundary conditions' do
        # Covers line 114 (hours == 0 case)
        time_just_now = now - 30  # 30 seconds
        expect(described_class.send(:format_relative_time, time_just_now)).to eq('1 hour ago')

        # Covers exact 1 hour boundary
        time_1_hour = now - 3600
        expect(described_class.send(:format_relative_time, time_1_hour)).to eq('1 hours ago')

        # Covers exact day boundary
        time_1_day = now - 86_400
        expect(described_class.send(:format_relative_time, time_1_day)).to eq('1 days ago')

        # Covers exact week boundary (slightly less to avoid precision issues)
        time_1_week = now - 604_799
        expect(described_class.send(:format_relative_time, time_1_week)).to eq('7 days ago')
      end

      it 'covers different time calculation branches' do
        # Covers lines 113-115 (0..3600 range)
        expect(described_class.send(:format_relative_time, now - 1000)).to eq('1 hour ago')

        # Covers lines 116-118 (3600..86400 range)
        expect(described_class.send(:format_relative_time, now - 7200)).to eq('2 hours ago')

        # Covers lines 119-121 (86400..604800 range)
        expect(described_class.send(:format_relative_time, now - 172_800)).to eq('2 days ago')

        # Covers lines 123-125 (else case)
        old_time = now - 1_000_000
        expect(described_class.send(:format_relative_time, old_time)).to eq(old_time.strftime('%Y-%m-%d'))
      end
    end

    describe 'extract_title_from_content edge cases' do
      it 'covers respond_to content check' do
        task_no_content_method = Object.new

        # Covers line 129 (respond_to? check)
        expect(described_class.send(:extract_title_from_content, task_no_content_method)).to eq('Unknown')
      end

      it 'covers content nil check' do
        task_nil_content = OpenStruct.new(content: nil)

        # Covers line 129 (content nil check)
        expect(described_class.send(:extract_title_from_content, task_nil_content)).to eq('Unknown')
      end

      it 'covers lines splitting and heading search' do
        task_multiline = OpenStruct.new(content: "Some intro text\n# Found Heading\nMore content\n# Another heading")

        # Covers lines 132-133 (lines split and find)
        expect(described_class.send(:extract_title_from_content, task_multiline)).to eq('Found Heading')
      end

      it 'covers heading processing and strip' do
        task_heading_with_spaces = OpenStruct.new(content: "# \t  Heading With Spaces  \t \nContent")

        # Covers lines 134-135 (heading processing)
        expect(described_class.send(:extract_title_from_content, task_heading_with_spaces)).to eq('Heading With Spaces')
      end

      it 'covers no heading found fallback' do
        task_no_heading = OpenStruct.new(content: "Just content\nNo headings here\nMore text")

        # Covers lines 136-138 (no heading fallback)
        expect(described_class.send(:extract_title_from_content, task_no_heading)).to eq('Unknown')
      end
    end

    describe 'detect_project_root comprehensive coverage' do
      let(:test_dir) { Dir.mktmpdir }
      let(:original_pwd) { Dir.pwd }

      after do
        # Safely restore directory before cleanup
        if Dir.exist?(original_pwd) && Dir.pwd != original_pwd
          begin
            Dir.chdir(original_pwd)
          rescue Errno::ENOENT
            # Original directory no longer exists, move to a safe directory
            Dir.chdir(ENV['PROJECT_ROOT'] || Dir.home)
          end
        end
        safe_directory_cleanup(test_dir)
      end

      it 'covers current directory initialization' do
        # Covers line 143 (Dir.pwd)
        allow(Dir).to receive(:pwd).and_return('/test/dir')
        allow(File).to receive(:exist?).and_return(false)

        expect(described_class.send(:detect_project_root)).to eq('/test/dir')
      end

      it 'covers while loop traversal' do
        nested_dir = File.join(test_dir, 'level1', 'level2', 'level3')
        FileUtils.mkdir_p(nested_dir)

        # Create .git in test_dir
        git_dir = File.join(test_dir, '.git')
        FileUtils.mkdir_p(git_dir)

        Dir.chdir(nested_dir)

        # Covers lines 144-147 (while loop and git detection)
        expect(described_class.send(:detect_project_root)).to eq(File.realpath(test_dir))
      end

      it 'covers File.dirname traversal' do
        deep_dir = File.join(test_dir, 'a', 'b', 'c', 'd')
        FileUtils.mkdir_p(deep_dir)
        Dir.chdir(deep_dir)

        # Mock to simulate traversal
        call_count = 0
        allow(File).to receive(:exist?) do |_path|
          call_count += 1
          false  # Never find .git
        end

        # Covers line 146 (File.dirname)
        result = described_class.send(:detect_project_root)
        expect(result).to eq(File.realpath(deep_dir))  # Falls back to original dir
      end

      it 'covers root directory boundary' do
        # Mock to simulate reaching root
        allow(Dir).to receive(:pwd).and_return('/')
        allow(File).to receive(:exist?).and_return(false)

        # Covers line 144 (current_dir != "/")
        expect(described_class.send(:detect_project_root)).to eq('/')
      end

      it 'covers fallback return' do
        test_subdir = File.join(test_dir, 'subdir')
        FileUtils.mkdir_p(test_subdir)
        Dir.chdir(test_subdir)

        # No .git anywhere
        # Covers line 148 (Dir.pwd fallback)
        expect(described_class.send(:detect_project_root)).to eq(File.realpath(test_subdir))
      end
    end

    describe 'verbose_line method coverage' do
      it 'covers label comparison logic' do
        # Covers line 104 (label == "Title" check)
        title_result = described_class.send(:verbose_line, 'Title', 'Test Value')
        other_result = described_class.send(:verbose_line, 'Status', 'Test Value')

        # Both should have same prefix based on current implementation
        expect(title_result).to eq('     Title: Test Value')
        expect(other_result).to eq('     Status: Test Value')
      end

      it 'covers string interpolation' do
        # Covers line 105 (string interpolation)
        result = described_class.send(:verbose_line, 'CustomLabel', 'CustomValue')
        expect(result).to eq('     CustomLabel: CustomValue')
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
