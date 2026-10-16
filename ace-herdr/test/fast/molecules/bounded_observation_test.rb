# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/herdr/molecules/bounded_observation"

module Ace
  module Herdr
    module Molecules
      class BoundedObservationTest < Minitest::Test
        def test_one_budget_covers_native_queries_and_process_ancestry
          budgets = []
          runner = Object.new
          runner.define_singleton_method(:call) do |argv, **options|
            budgets << options
            sleep 0.02
            BoundedProcess::Result.new("{}", "", Struct.new(:success?, :exitstatus).new(true, 0), false)
          end
          probe = BoundedObservation.new(deadline: monotonic + 0.1, binary: "/usr/bin/herdr", process: runner)
          probe.pane_get("w1:p1")
          probe.pane_process_info("w1:p1")
          probe.capture2("ps", "-p", Process.pid.to_s, "-o", "ppid=", stdin_data: "")
          assert_equal 3, budgets.size
          assert budgets.each_cons(2).all? { |a, b| a.fetch(:timeout_s) > b.fetch(:timeout_s) }
          assert budgets.all? { |options| options.fetch(:cleanup_group) && options.fetch(:output_limit) == 65_536 }
          sleep 0.05
          assert_raises(AgentNotReadyError) { probe.pane_get("w1:p1") }
          assert_equal 3, budgets.size
        end

        def test_stalled_native_child_is_killed_and_reaped
          Dir.mktmpdir do |root|
            executable = File.join(root, "herdr")
            pidfile = File.join(root, "pid")
            File.write(executable, "#!/bin/sh\necho $$ > '#{pidfile}'\nexec /bin/sleep 30\n")
            File.chmod(0o700, executable)
            before = monotonic
            probe = BoundedObservation.new(deadline: before + 1, binary: executable)
            assert_raises(AgentNotReadyError) { probe.pane_get("w1:p1") }
            assert_operator monotonic - before, :<, 3
            pid = Integer(File.read(pidfile))
            assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
            assert_raises(Errno::ECHILD) { Process.waitpid(pid, Process::WNOHANG) }
          end
        end

        def test_oversized_observation_cannot_supply_partial_identity
          runner = Object.new
          runner.define_singleton_method(:call) do |*_, **_options|
            BoundedProcess::Result.new("{}", "", Struct.new(:success?, :exitstatus).new(true, 0), true)
          end
          probe = BoundedObservation.new(deadline: monotonic + 1, process: runner)
          assert_raises(AgentNotReadyError) { probe.pane_get("w1:p1") }
          assert_raises(AgentNotReadyError) { probe.capture2("ps", "-p", "1") }
        end

        private

        def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
