# frozen_string_literal: true

require "test_helper"
require "ace/herdr/molecules/bounded_process"

module Ace
  module Herdr
    module Molecules
      class BoundedProcessCleanupTest < Minitest::Test
        def test_owned_child_cannot_replace_original_identity_after_signal
          child = BoundedProcess::OwnedChild.new(123)
          Process.stub(:kill, 1) { BoundedProcess.kill_group(child) }
          Process.stub(:spawn, ->(*) { flunk "original child cannot be replaced" }) do
            assert_raises(BoundedProcess::PostLaunchError) { child.start!(["replacement"], {}) }
          end
          assert_equal 123, child.pid
          assert child.alive?
          assert child.group_signalled?
        end

        def test_failed_signal_is_not_retained_and_success_belongs_only_to_original_child
          original = BoundedProcess::OwnedChild.new(123)
          fresh = BoundedProcess::OwnedChild.new(456)
          signals = []
          failed = true
          BoundedProcess.stub(:darwin_platform?, false) do
            Process.stub(:kill, ->(*args) { signals << args; raise Errno::EPERM if failed; 1 }) do
              assert_raises(Errno::EPERM) { BoundedProcess.kill_group(original) }
              refute original.group_signalled?
              failed = false
              BoundedProcess.kill_group(original)
              BoundedProcess.kill_group(original)
              BoundedProcess.kill_group(fresh)
            end
          end
          assert_equal [["KILL", -123], ["KILL", -123], ["KILL", -456]], signals
          assert original.group_signalled?
          assert fresh.group_signalled?
        end

        def test_successful_timeout_signal_does_not_upgrade_timeout_outcome
          child = BoundedProcess::OwnedChild.new
          signals = []
          Process.stub(:spawn, 123) do
            BoundedProcess::OwnedChild.stub(:new, child) do
              Process.stub(:kill, ->(*args) { signals << args; 1 }) do
                Process.stub(:waitpid2, [123, :status]) do
                  BoundedProcess.stub(:run_loop, ->(*args, **) {
                    BoundedProcess.kill_group(args.fetch(3))
                    raise Timeout::Error, "original execution deadline"
                  }) do
                    error = assert_raises(Timeout::Error) { BoundedProcess.call(["controlled"], timeout_s: 1) }
                    assert_equal "original execution deadline", error.message
                  end
                end
              end
            end
          end
          assert_equal [["KILL", -123]], signals
          refute child.alive?
        end

        def test_successful_group_signal_is_not_repeated_before_owned_reaping
          child = BoundedProcess::OwnedChild.new(123)
          signals = []
          Process.stub(:kill, ->(*args) { signals << args; 1 }) do
            BoundedProcess.kill_group(child)
            Process.stub(:waitpid2, ->(*) { [123, :status] }) do
              BoundedProcess.cleanup_child!(child)
            end
          end
          assert_equal [["KILL", -123]], signals
          refute child.alive?
          assert_equal :status, child.value
        end

        def test_darwin_eperm_accepts_only_owned_unreaped_singleton_between_exit_checks
          child = BoundedProcess::OwnedChild.new(123)
          events = []
          BoundedProcess.stub(:darwin_platform?, true) do
            BoundedProcess.stub(:nonreaping_exit?, ->(pid) { events << [:exit, pid]; true }) do
              BoundedProcess.stub(:darwin_group_pids, ->(pid) { events << [:group, pid]; [123] }) do
                Process.stub(:kill, ->(*args) { events << [:signal, args]; raise Errno::EPERM }) do
                  BoundedProcess.kill_group(child)
                end
              end
            end
          end
          assert_equal [[:signal, ["KILL", -123]], [:exit, 123], [:group, 123], [:exit, 123]], events
          assert child.alive?, "singleton proof must not reap or detach the pinned child"
        end

        def test_darwin_eperm_preserves_denial_for_incomplete_or_extra_group_members
          [nil, [], [456], [123, 456], [123, 123]].each do |members|
            child = BoundedProcess::OwnedChild.new(123)
            original = Errno::EPERM.new("original denial")
            BoundedProcess.stub(:darwin_platform?, true) do
              BoundedProcess.stub(:nonreaping_exit?, true) do
                BoundedProcess.stub(:darwin_group_pids, members) do
                  Process.stub(:kill, ->(*) { raise original }) do
                    assert_same original, assert_raises(Errno::EPERM) { BoundedProcess.kill_group(child) }
                  end
                end
              end
            end
            assert child.alive?
          end
        end

        def test_darwin_eperm_requires_both_exit_checks_and_original_ownership
          [[false], [true, false], [true, :lost]].each do |observations|
            child = BoundedProcess::OwnedChild.new(123)
            exits = observations.dup
            BoundedProcess.stub(:darwin_platform?, true) do
              BoundedProcess.stub(:nonreaping_exit?, ->(*) { value = exits.shift; raise Errno::ECHILD if value == :lost; value }) do
                BoundedProcess.stub(:darwin_group_pids, [123]) do
                  Process.stub(:kill, ->(*) { raise Errno::EPERM }) do
                    assert_raises(Errno::EPERM) { BoundedProcess.kill_group(child) }
                  end
                end
              end
            end
            assert_equal observations.last != :lost, child.alive?
          end
          child = BoundedProcess::OwnedChild.new(123)
          BoundedProcess.stub(:darwin_platform?, false) do
            BoundedProcess.stub(:darwin_group_pids, ->(*) { flunk "unsupported platform must not enumerate" }) do
              Process.stub(:kill, ->(*) { raise Errno::EPERM }) do
                assert_raises(Errno::EPERM) { BoundedProcess.kill_group(child) }
              end
            end
          end
        end

        def test_darwin_eperm_group_observation_error_remains_original_denial
          [Errno::EPERM, IOError, Fiddle::DLError].each do |error_class|
            child = BoundedProcess::OwnedChild.new(123)
            original = Errno::EPERM.new("signal denial")
            BoundedProcess.stub(:darwin_platform?, true) do
              BoundedProcess.stub(:nonreaping_exit?, true) do
                BoundedProcess.stub(:darwin_group_pids, ->(*) { raise error_class, "snapshot unavailable" }) do
                  Process.stub(:kill, ->(*) { raise original }) do
                    assert_same original, assert_raises(Errno::EPERM) { BoundedProcess.kill_group(child) }
                  end
                end
              end
            end
          end
        end

        def test_darwin_group_snapshot_uses_bounded_complete_native_list_including_zombies
          library = Object.new
          library.define_singleton_method(:[]) { |name| raise "wrong symbol" unless name == "proc_listpids"; 123 }
          capacity = BoundedProcess::DARWIN_GROUP_PID_LIMIT * Fiddle::SIZEOF_INT
          response = [456].pack("i!*")
          size = response.bytesize
          native = Object.new
          native.define_singleton_method(:call) do |kind, pid, buffer, limit|
            raise "wrong group or bound" unless [kind, pid, limit] == [2, 456, capacity]
            buffer[0, response.bytesize] = response
            size
          end
          Fiddle.stub(:dlopen, ->(path) { assert_equal "/usr/lib/libproc.dylib", path; library }) do
            Fiddle::Function.stub(:new, ->(*) { native }) do
              assert_equal [456], BoundedProcess.darwin_group_pids(456)
              [0, -1, capacity, capacity + 4, 3].each do |invalid|
                size = invalid
                assert_nil BoundedProcess.darwin_group_pids(456)
              end
              [[0], [-1], [456, 456]].each do |invalid|
                response = invalid.pack("i!*")
                size = response.bytesize
                assert_nil BoundedProcess.darwin_group_pids(456)
              end
            end
          end
        end

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
