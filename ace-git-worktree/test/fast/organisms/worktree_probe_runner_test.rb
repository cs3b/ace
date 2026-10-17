# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"

class WorktreeProbeRunnerTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo
  WorktreeProbeRunner = Ace::Git::Worktree::Organisms::WorktreeProbeRunner

  def setup
    @tmp = Dir.mktmpdir("probe-runner-test")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def worktrees(count)
    Array.new(count) { |index| WorktreeInfo.new(path: "/wt/#{index}", commit: "abc#{index}") }
  end

  def test_results_follow_input_order_not_completion_order
    probe = lambda do |worktree|
      index = worktree.path.split("/").last.to_i
      sleep(index.zero? ? 0.2 : 0.01)
      {sha: worktree.commit, index: index}
    end

    results = WorktreeProbeRunner.new(probe: probe).run(worktrees(5))

    assert_equal 5, results.length
    assert_equal (0..4).to_a, results.map { |payload| payload[:index] }
    assert_equal "abc3", results[3][:sha]
  end

  def test_timed_out_probe_renders_nil_and_kills_process_group
    grandchild_pid_file = File.join(@tmp, "grandchild.pid")
    probe = lambda do |worktree|
      if worktree.path.end_with?("/hang")
        pid = spawn("sleep", "30")
        File.write(grandchild_pid_file, pid.to_s)
        sleep 30
      end
      {sha: worktree.commit}
    end

    hanging = WorktreeInfo.new(path: "/wt/hang", commit: "abc")
    healthy = WorktreeInfo.new(path: "/wt/ok", commit: "def")
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    results = WorktreeProbeRunner.new(probe: probe, timeout: 0.2).run([hanging, healthy])
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    assert_nil results.first
    assert_equal({sha: "def"}, results.last)
    assert_operator elapsed, :<, 3.0

    grandchild = wait_for_pid_file(grandchild_pid_file)
    refute_nil grandchild, "probe grandchild did not start"
    refute process_alive?(grandchild), "probe process group was not killed"
  end

  def test_at_most_max_children_are_alive
    marker = File.join(@tmp, "events.log")
    probe = lambda do |_worktree|
      stamp = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      File.open(marker, "a") { |file| file.puts("S #{stamp}") }
      sleep 0.05
      stamp = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      File.open(marker, "a") { |file| file.puts("E #{stamp}") }
      {ok: true}
    end

    results = WorktreeProbeRunner.new(probe: probe, max_children: 4, timeout: 5).run(worktrees(24))

    assert_equal 24, results.length
    assert results.all? { |payload| payload[:ok] }

    peak = peak_concurrency(File.readlines(marker).map(&:split))
    assert_operator peak, :<=, 4
    assert_operator peak, :>, 1
  end

  def test_sequential_fallback_preserves_order_and_timeout
    probe = lambda do |worktree|
      sleep 0.5 if worktree.path.end_with?("/slow")
      {path: worktree.path}
    end
    slow = WorktreeInfo.new(path: "/wt/slow", commit: "abc")
    fast = WorktreeInfo.new(path: "/wt/fast", commit: "def")

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    results = WorktreeProbeRunner.new(probe: probe, fork_supported: false, timeout: 0.1).run([fast, slow])
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    assert_equal({path: "/wt/fast"}, results.first)
    assert_nil results.last
    assert_operator elapsed, :<, 3.0
  end

  def test_child_terminal_output_is_discarded
    probe = lambda do |_worktree|
      puts "child stdout noise"
      warn "child stderr noise"
      {ok: true}
    end

    output = capture_io do
      @result = WorktreeProbeRunner.new(probe: probe).run(worktrees(2))
    end

    assert_equal "", output.first
    assert_equal "", output.last
    assert_equal [true, true], @result.map { |payload| payload[:ok] }
  end

  def test_empty_worktree_list
    assert_equal [], WorktreeProbeRunner.new(probe: ->(_) { {} }).run([])
  end

  def test_nil_payload_is_preserved
    results = WorktreeProbeRunner.new(probe: ->(_) { nil }).run(worktrees(2))

    assert_equal [nil, nil], results
  end

  private

  def wait_for_pid_file(path)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3
    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      return Integer(File.read(path).strip, 10) if File.exist?(path) && !File.read(path).strip.empty?

      sleep 0.01
    end
    nil
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end

  def peak_concurrency(events)
    active = 0
    peak = 0
    events.sort_by { |_kind, stamp| stamp.to_f }.each do |kind, _stamp|
      if kind == "S"
        active += 1
        peak = [peak, active].max
      else
        active -= 1
      end
    end
    peak
  end
end
