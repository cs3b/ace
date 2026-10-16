# frozen_string_literal: true

require "fiddle"

module Ace
  module Runtime
    module Molecules
      # One ephemeral single-thread helper owns every child in this scope.
      # Linux reparents detached orphans to this subreaper, not container PID1.
      # Unreaped direct children pin their PIDs until this owner reaps them.
      class OwnedChildScope
        class CleanupUncertain < StandardError; end

        def initialize
          unless RUBY_PLATFORM.include?("linux") && Thread.list.count(&:alive?) == 1
            raise CleanupUncertain, "child scope requires a sole Linux helper thread"
          end
          @owner = Process.pid
          raise CleanupUncertain, "child scope has preexisting children" unless children.empty?
          # An inherited ignore/custom reaper could discard a child's wait
          # status and unpin its PID. This sole ephemeral helper owns the
          # disposition; establish it while the verified child set is empty.
          Signal.trap("CHLD", "DEFAULT")
          prctl = Fiddle::Function.new(Fiddle::Handle::DEFAULT["prctl"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG], Fiddle::TYPE_INT)
          raise CleanupUncertain, "cannot establish child subreaper" unless prctl.call(36, 1, 0, 0, 0).zero?
        end

        # Preserve the leader's wait status for the executor. Kill/reap only
        # kernel-owned direct children; adoption closes setsid/double-fork escape.
        def cleanup!(leader:, timeout: 5)
          unless Process.pid == @owner && Thread.list.count(&:alive?) == 1 &&
              timeout.is_a?(Numeric) && timeout.finite? && timeout.positive? && timeout <= 5
            raise CleanupUncertain, "child scope ownership is unavailable"
          end
          deadline = monotonic + timeout
          owned = children
          raise CleanupUncertain, "original child is no longer owned" unless owned.include?(leader)
          signal("TERM", -leader)
          loop do
            owned = children
            raise CleanupUncertain, "original child was reaped outside its scope" unless owned.include?(leader)
            owned.each do |pid|
              signal("KILL", pid)
              Process.waitpid(pid, Process::WNOHANG) unless pid == leader
            end
            remaining = children
            return if remaining == [leader] && zombie?(leader)
            raise CleanupUncertain, "owned child cleanup deadline elapsed" if monotonic >= deadline
            IO.select(nil, nil, nil, 0.01)
          end
        rescue Errno::ECHILD, Errno::ENOENT, IOError
          raise CleanupUncertain, "owned child cleanup cannot be confirmed"
        end

        private

        def children
          File.open("/proc/self/task/#{@owner}/children", "r") do |file|
            bytes = file.read(65_537) || ""
            raise CleanupUncertain, "owned child inventory exceeds bound" if bytes.bytesize > 65_536
            values = bytes.split.map { |value| Integer(value, 10) }
            unless values.uniq == values && values.all?(&:positive?)
              raise CleanupUncertain, "owned child inventory is invalid"
            end
            values.sort
          end
        end

        def signal(name, pid)
          Process.kill(name, pid)
        rescue Errno::ESRCH
          nil
        end

        def zombie?(pid) = File.read("/proc/#{pid}/stat").rpartition(")").last.split.first == "Z"
        def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
