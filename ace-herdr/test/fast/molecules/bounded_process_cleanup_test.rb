# frozen_string_literal: true

require "test_helper"
require "ace/herdr/molecules/bounded_process"

module Ace
  module Herdr
    module Molecules
      class BoundedProcessCleanupTest < Minitest::Test
        def test_cleanup_signal_failure_retains_exact_system_error_cause
          original = Errno::EPERM.new("controlled signal")
          original.set_backtrace(["controlled_signal.rb:12"])
          waiter = Object.new
          waiter.define_singleton_method(:alive?) { true }
          waiter.define_singleton_method(:join) { |_| self }
          BoundedProcess.stub(:kill_group, ->(*) { raise original }) do
            error = assert_raises(BoundedProcess::PostLaunchError) { BoundedProcess.cleanup_child!(waiter) }
            assert_same original, error.cause
            assert_equal ["controlled_signal.rb:12"], error.cause.backtrace
          end
        end

        def test_owned_pipe_close_failure_retains_exact_system_error_cause
          original = Errno::EPERM.new("controlled close")
          waiter = Object.new
          waiter.define_singleton_method(:start!) { |*| nil }
          waiter.define_singleton_method(:started?) { true }
          waiter.define_singleton_method(:alive?) { false }
          calls = 0
          BoundedProcess::OwnedChild.stub(:new, waiter) do
            BoundedProcess.stub(:close_handles, ->(handles) {
              handles.each { |io| io.close unless io.closed? }
              calls += 1
              calls == 2 ? original : nil
            }) do
              BoundedProcess.stub(:run_loop, ->(*) { :result }) do
                error = assert_raises(BoundedProcess::PostLaunchError) do
                  BoundedProcess.call(["fixed-fixture"], timeout_s: 1)
                end
                assert_same original, error.cause
              end
            end
          end
        end

        def test_closed_streams_do_not_signal_live_handler_and_exit_is_observed_before_reaping
          events = []
          waiter = Object.new
          waiter.define_singleton_method(:start!) { |command, options| Process.spawn(*command, **options) }
          waiter.define_singleton_method(:started?) { true }
          observations = [false, false, true]
          waiter.define_singleton_method(:exited?) { events << :observe; observations.shift }
          waiter.define_singleton_method(:alive?) { true }
          waiter.define_singleton_method(:pid) { 123 }
          waiter.define_singleton_method(:join) { |timeout| events << [:reap, timeout]; self }
          waiter.define_singleton_method(:value) { :status }
          pipes = 3.times.map { IO.pipe }
          stdin, stdout, stderr = pipes.map(&:first)
          pipes.each { |pair| pair.last.close }
          Process.stub(:kill, ->(*args) { events << [:signal, args]; 1 }) do
            result = BoundedProcess.run_loop(stdin, stdout, stderr, waiter,
              stdin_data: "", timeout_s: 1, output_limit: 16, stderr_limit: 8, cleanup_group: true)
            assert_equal :status, result.status
          end
          assert_equal [:observe, :observe, :observe, [:signal, ["KILL", -123]], [:reap, 0]], events
        ensure
          pipes&.flatten&.each { |io| io.close unless io.closed? }
        end

        def test_generic_success_does_not_signal_group_or_use_nonreaping_native_observation
          waiter = Object.new
          waiter.define_singleton_method(:join) { |_| self }
          waiter.define_singleton_method(:value) { :status }
          waiter.define_singleton_method(:exited?) { raise "generic path must not observe native exit" }
          pipes = 3.times.map { IO.pipe }
          pipes.each { |pair| pair.last.close }
          Process.stub(:kill, ->(*) { raise "successful generic call must not signal group" }) do
            result = BoundedProcess.run_loop(*pipes.map(&:first), waiter,
              stdin_data: "", timeout_s: 1, output_limit: 16, stderr_limit: 8, cleanup_group: false)
            assert_equal :status, result.status
          end
        ensure
          pipes&.flatten&.each { |io| io.close unless io.closed? }
        end

        def test_unconfirmed_cleanup_is_bounded_and_closes_all_owned_pipes
          handles = []
          joins = []
          waiter = Object.new
          waiter.define_singleton_method(:start!) { |command, options| Process.spawn(*command, **options) }
          waiter.define_singleton_method(:started?) { true }
          waiter.define_singleton_method(:alive?) { true }
          waiter.define_singleton_method(:pid) { 123 }
          waiter.define_singleton_method(:join) { |seconds| joins << seconds; nil }
          waiter.define_singleton_method(:release_to_reaper!) { joins << :reaper_transfer }
          original_pipe = IO.method(:pipe)
          IO.stub(:pipe, -> { original_pipe.call.tap { |pair| handles.concat(pair) } }) do
            Process.stub(:spawn, ->(*) { 123 }) do
              Process.stub(:kill, ->(*) { 1 }) do
                BoundedProcess::OwnedChild.stub(:new, waiter) do
                  BoundedProcess.stub(:run_loop, ->(*) { raise Timeout::Error, "controlled timeout" }) do
                    error = assert_raises(BoundedProcess::PostLaunchError) do
                      BoundedProcess.call(["fixed-fixture"], timeout_s: 30)
                    end
                    assert_match(/cleanup could not be confirmed/, error.message)
                  end
                end
              end
            end
          end
          assert_equal [BoundedProcess::CLEANUP_TIMEOUT, :reaper_transfer], joins
          assert_equal 6, handles.length
          assert handles.all?(&:closed?)
        end

        def test_reaped_identity_is_never_signalled_again
          child = BoundedProcess::OwnedChild.new(123)
          Process.stub(:waitpid2, ->(pid, flags) { assert_equal 123, pid; assert_equal Process::WNOHANG, flags; [123, :status] }) do
            assert_same child, child.join(0)
          end
          Process.stub(:kill, ->(*) { raise "must not signal recycled group" }) { BoundedProcess.kill_group(child) }
          assert_equal :status, child.value
        end

        def test_lost_exclusive_child_ownership_refuses_without_signalling_recycled_group
          child = BoundedProcess::OwnedChild.new(123)
          BoundedProcess.stub(:nonreaping_exit?, ->(*) { raise Errno::ECHILD }) do
            assert_raises(BoundedProcess::PostLaunchError) { child.exited? }
          end
          Process.stub(:kill, ->(*) { raise "lost original identity must not be signalled" }) do
            BoundedProcess.kill_group(child)
          end
          refute child.alive?
          assert_raises(BoundedProcess::PostLaunchError) { child.value }
        end

        def test_reaper_transfer_has_no_wait_signal_or_positive_outcome_and_requires_original_ownership
          child = BoundedProcess::OwnedChild.new(123)
          detached = []
          Process.stub(:detach, ->(pid) { detached << pid; Object.new }) { child.release_to_reaper! }
          assert_equal [123], detached
          Process.stub(:kill, ->(*) { raise "transferred identity must never be signalled" }) do
            BoundedProcess.kill_group(child)
          end
          assert_raises(BoundedProcess::PostLaunchError) { child.value }
          assert_raises(BoundedProcess::PostLaunchError) { child.release_to_reaper! }
          assert_equal [123], detached
        end

        def test_nonreaping_observation_uses_exact_child_and_termination_options_without_native_execution
          library = Object.new
          library.define_singleton_method(:[]) { |name| raise "wrong libc symbol" unless name == "waitid"; 123 }
          native = Object.new
          terminal = false
          native.define_singleton_method(:call) do |kind, pid, buffer, options|
            raise "wrong child selection" unless kind == 1 && pid == 456
            expected_nowait = RUBY_PLATFORM.include?("darwin") ? 0x20 : 0x01000000
            raise "reaping or nonterminal observation" unless options == 4 | 1 | expected_nowait
            buffer[0, Fiddle::SIZEOF_INT] = [Signal.list.fetch("CHLD")].pack("i!") if terminal
            0
          end
          Fiddle.stub(:dlopen, library) do
            Fiddle::Function.stub(:new, ->(*) { native }) do
              refute BoundedProcess.nonreaping_exit?(456)
              terminal = true
              assert BoundedProcess.nonreaping_exit?(456)
            end
          end
        end

        def test_close_failure_after_spawn_and_during_ensure_still_cleans_original_child
          [0, 1].each do |failing_index|
            handles = []
            spawned = false
            events = []
            original_pipe = IO.method(:pipe)
            factory = lambda do
              original_pipe.call.tap do |pair|
                pair.each do |handle|
                  index = handles.length
                  handles << handle
                  next unless index == failing_index
                  original_close = handle.method(:close)
                  failed = false
                  handle.define_singleton_method(:close) do
                    if spawned && !failed
                      failed = true
                      raise Errno::EIO, "controlled close failure"
                    end
                    original_close.call
                  end
                end
              end
            end
            IO.stub(:pipe, factory) do
              Process.stub(:spawn, ->(*) { spawned = true; 123 }) do
                Process.stub(:kill, ->(*args) { events << [:signal, args]; 1 }) do
                  Process.stub(:waitpid2, ->(*args) { events << [:reap, args]; [123, :status] }) do
                    BoundedProcess.stub(:run_loop, ->(*) { :controlled_result }) do
                      error = assert_raises(BoundedProcess::PostLaunchError) do
                        BoundedProcess.call(["fixed-selected-child"], timeout_s: 30)
                      end
                      assert_match(/controlled close failure/, error.message)
                    end
                  end
                end
              end
            end
            assert_equal [[:signal, ["KILL", -123]], [:reap, [123, Process::WNOHANG]]], events
            assert handles.all?(&:closed?), "one failed close must not leak other owned handles"
          ensure
            handles&.each { |io| io.close unless io.closed? }
          end
        end

        def test_actual_pipe_loop_retains_separate_stream_caps
          waiter = Object.new
          waiter.define_singleton_method(:join) { |_| self }
          waiter.define_singleton_method(:value) { :status }
          input = IO.pipe
          output = IO.pipe
          errors = IO.pipe
          output.last.write("o" * 17)
          errors.last.write("e" * 9)
          [input.last, output.last, errors.last].each(&:close)
          result = BoundedProcess.run_loop(input.first, output.first, errors.first, waiter,
            stdin_data: "", timeout_s: 1, output_limit: 16, stderr_limit: 8, cleanup_group: false)
          assert_equal "o" * 16, result.stdout
          assert_equal "e" * 8, result.stderr
          assert result.oversized
        ensure
          [input, output, errors].compact.flatten.each { |io| io.close unless io.closed? }
        end
      end
    end
  end
end
