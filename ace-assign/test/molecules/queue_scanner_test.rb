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
      phases_dir = File.join(cache_dir, "phases")
      FileUtils.mkdir_p(phases_dir)

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(phases_dir, assignment: @assignment)

      assert state.empty?
      assert_equal 0, state.size
    end
  end

  def test_scan_with_phases
    with_temp_cache do |cache_dir|
      phases_dir = File.join(cache_dir, "phases")
      FileUtils.mkdir_p(phases_dir)

      # Create phase files
      File.write(File.join(phases_dir, "010-init.ph.md"), <<~MD)
        ---
        name: init
        status: done
        ---

        Initialize project.
      MD

      File.write(File.join(phases_dir, "020-build.ph.md"), <<~MD)
        ---
        name: build
        status: in_progress
        ---

        Build project.
      MD

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(phases_dir, assignment: @assignment)

      assert_equal 2, state.size
      assert_equal "010", state.phases.first.number
      assert_equal :done, state.phases.first.status
      assert_equal "020", state.current.number
    end
  end

  def test_scan_sorts_correctly
    with_temp_cache do |cache_dir|
      phases_dir = File.join(cache_dir, "phases")
      FileUtils.mkdir_p(phases_dir)

      # Create files out of order
      File.write(File.join(phases_dir, "030-third.ph.md"), "---\nname: third\nstatus: pending\n---\nThird")
      File.write(File.join(phases_dir, "010-first.ph.md"), "---\nname: first\nstatus: done\n---\nFirst")
      File.write(File.join(phases_dir, "020-second.ph.md"), "---\nname: second\nstatus: done\n---\nSecond")

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(phases_dir, assignment: @assignment)

      assert_equal ["010", "020", "030"], state.phases.map(&:number)
    end
  end

  def test_phase_numbers
    with_temp_cache do |cache_dir|
      phases_dir = File.join(cache_dir, "phases")
      FileUtils.mkdir_p(phases_dir)

      File.write(File.join(phases_dir, "010-init.ph.md"), "---\nname: init\nstatus: done\n---\nInit")
      File.write(File.join(phases_dir, "020-build.ph.md"), "---\nname: build\nstatus: pending\n---\nBuild")

      scanner = Ace::Assign::Molecules::QueueScanner.new
      numbers = scanner.phase_numbers(phases_dir)

      assert_includes numbers, "010"
      assert_includes numbers, "020"
    end
  end

  def test_current_phase
    with_temp_cache do |cache_dir|
      phases_dir = File.join(cache_dir, "phases")
      FileUtils.mkdir_p(phases_dir)

      File.write(File.join(phases_dir, "010-init.ph.md"), "---\nname: init\nstatus: done\n---\nInit")
      File.write(File.join(phases_dir, "020-build.ph.md"), "---\nname: build\nstatus: in_progress\n---\nBuild")

      scanner = Ace::Assign::Molecules::QueueScanner.new
      current = scanner.current(phases_dir, assignment: @assignment)

      assert_equal "020", current.number
      assert_equal "build", current.name
    end
  end
end
