# frozen_string_literal: true

require_relative "../test_helper"

class QueueScannerTest < AceCoworkerTestCase
  def setup
    @session = Ace::Coworker::Models::Session.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml"
    )
  end

  def test_scan_empty_directory
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      scanner = Ace::Coworker::Molecules::QueueScanner.new
      state = scanner.scan(jobs_dir, session: @session)

      assert state.empty?
      assert_equal 0, state.size
    end
  end

  def test_scan_with_steps
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      # Create step files
      File.write(File.join(jobs_dir, "010-init.md"), <<~MD)
        ---
        name: init
        status: done
        ---

        Initialize project.
      MD

      File.write(File.join(jobs_dir, "020-build.md"), <<~MD)
        ---
        name: build
        status: in_progress
        ---

        Build project.
      MD

      scanner = Ace::Coworker::Molecules::QueueScanner.new
      state = scanner.scan(jobs_dir, session: @session)

      assert_equal 2, state.size
      assert_equal "010", state.steps.first.number
      assert_equal :done, state.steps.first.status
      assert_equal "020", state.current.number
    end
  end

  def test_scan_sorts_correctly
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      # Create files out of order
      File.write(File.join(jobs_dir, "030-third.md"), "---\nname: third\nstatus: pending\n---\nThird")
      File.write(File.join(jobs_dir, "010-first.md"), "---\nname: first\nstatus: done\n---\nFirst")
      File.write(File.join(jobs_dir, "020-second.md"), "---\nname: second\nstatus: done\n---\nSecond")

      scanner = Ace::Coworker::Molecules::QueueScanner.new
      state = scanner.scan(jobs_dir, session: @session)

      assert_equal ["010", "020", "030"], state.steps.map(&:number)
    end
  end

  def test_step_numbers
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      File.write(File.join(jobs_dir, "010-init.md"), "---\nname: init\nstatus: done\n---\nInit")
      File.write(File.join(jobs_dir, "020-build.md"), "---\nname: build\nstatus: pending\n---\nBuild")

      scanner = Ace::Coworker::Molecules::QueueScanner.new
      numbers = scanner.step_numbers(jobs_dir)

      assert_includes numbers, "010"
      assert_includes numbers, "020"
    end
  end

  def test_current_step
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      File.write(File.join(jobs_dir, "010-init.md"), "---\nname: init\nstatus: done\n---\nInit")
      File.write(File.join(jobs_dir, "020-build.md"), "---\nname: build\nstatus: in_progress\n---\nBuild")

      scanner = Ace::Coworker::Molecules::QueueScanner.new
      current = scanner.current(jobs_dir, session: @session)

      assert_equal "020", current.number
      assert_equal "build", current.name
    end
  end
end
