# frozen_string_literal: true

require_relative "../test_helper"

class QueueScannerTest < AceAssignTestCase
  def setup
    super
    @assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml"
    )
  end

  def test_scan_empty_directory
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(steps_dir, assignment: @assignment)

      assert state.empty?
      assert_equal 0, state.size
    end
  end

  def test_scan_with_steps
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      # Create step files
      File.write(File.join(steps_dir, "010-init.st.md"), <<~MD)
        ---
        name: init
        status: done
        ---

        Initialize project.
      MD

      File.write(File.join(steps_dir, "020-build.st.md"), <<~MD)
        ---
        name: build
        status: in_progress
        ---

        Build project.
      MD

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(steps_dir, assignment: @assignment)

      assert_equal 2, state.size
      assert_equal "010", state.steps.first.number
      assert_equal :done, state.steps.first.status
      assert_equal "020", state.current.number
    end
  end

  def test_scan_sorts_correctly
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      # Create files out of order
      File.write(File.join(steps_dir, "030-third.st.md"), "---\nname: third\nstatus: pending\n---\nThird")
      File.write(File.join(steps_dir, "010-first.st.md"), "---\nname: first\nstatus: done\n---\nFirst")
      File.write(File.join(steps_dir, "020-second.st.md"), "---\nname: second\nstatus: done\n---\nSecond")

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(steps_dir, assignment: @assignment)

      assert_equal ["010", "020", "030"], state.steps.map(&:number)
    end
  end

  def test_step_numbers
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      File.write(File.join(steps_dir, "010-init.st.md"), "---\nname: init\nstatus: done\n---\nInit")
      File.write(File.join(steps_dir, "020-build.st.md"), "---\nname: build\nstatus: pending\n---\nBuild")

      scanner = Ace::Assign::Molecules::QueueScanner.new
      numbers = scanner.step_numbers(steps_dir)

      assert_includes numbers, "010"
      assert_includes numbers, "020"
    end
  end

  def test_current_step
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      File.write(File.join(steps_dir, "010-init.st.md"), "---\nname: init\nstatus: done\n---\nInit")
      File.write(File.join(steps_dir, "020-build.st.md"), "---\nname: build\nstatus: in_progress\n---\nBuild")

      scanner = Ace::Assign::Molecules::QueueScanner.new
      current = scanner.current(steps_dir, assignment: @assignment)

      assert_equal "020", current.number
      assert_equal "build", current.name
    end
  end
end
