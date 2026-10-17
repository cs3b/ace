# frozen_string_literal: true

require "json"
require "timeout"
require_relative "../molecules/worktree_probe"

module Ace
  module Git
    module Worktree
      module Organisms
        # Runs one read-only probe per worktree in isolated child processes.
        #
        # Contract:
        # - one child per worktree, at most {MAX_LIVE_CHILDREN} alive at once;
        # - each child has a hard {PROBE_TIMEOUT} second budget; a timed-out
        #   child is killed together with its process group (no orphan `git`);
        # - children never write repository state or the terminal, and results
        #   are stored by input index so output order never depends on child
        #   completion order;
        # - a failed/timed-out probe yields nil (rendered as `?` by callers);
        # - when `fork` is unavailable, probes run sequentially with the same
        #   per-probe timeout and the same result contract.
        class WorktreeProbeRunner
          # Maximum number of live probe children.
          MAX_LIVE_CHILDREN = 16

          # Per-probe hard timeout in seconds (implementation constant).
          PROBE_TIMEOUT = 5

          # @param project_root [String, nil] project root for probe task signals
          # @param base_ref [String, nil] primary worktree head for merge-base diffs
          # @param probe [Proc, nil] injectable probe callable for tests
          #   (receives a worktree, returns a Hash or nil); runs inside the child
          # @param max_children [Integer] maximum live children
          # @param timeout [Numeric] per-probe timeout in seconds
          # @param fork_supported [Boolean, nil] force the sequential fallback
          #   when false (nil = detect POSIX fork)
          def initialize(project_root: nil, base_ref: nil, probe: nil,
            max_children: MAX_LIVE_CHILDREN, timeout: PROBE_TIMEOUT, fork_supported: nil)
            @project_root = project_root
            @base_ref = base_ref
            @probe = probe
            @max_children = max_children
            @timeout = timeout
            @fork_supported = fork_supported.nil? ? fork_supported? : fork_supported
          end

          # Probe every worktree.
          #
          # @param worktrees [Array<Models::WorktreeInfo>] worktrees in display order
          # @return [Array<Hash, nil>] payload per worktree, aligned with input
          def run(worktrees)
            list = Array(worktrees)
            return [] if list.empty?
            return sequential_all(list) unless @fork_supported

            begin
              fork_all(list)
            rescue NotImplementedError
              # fork exists but is unavailable in this environment (e.g. a
              # restricted container): fall back to sequential probes.
              @fork_supported = false
              sequential_all(list)
            end
          end

          private

          def fork_supported?
            Process.respond_to?(:fork) && !Gem.win_platform?
          end

          # --- Forked pool ---

          def fork_all(worktrees)
            results = Array.new(worktrees.length)
            pending = worktrees.each_with_index.map { |worktree, index| [index, worktree] }
            active = {}

            begin
              until pending.empty? && active.empty?
                start_children(pending, active) while active.length < @max_children && !pending.empty?
                break if active.empty?

                wait_for_results(active, results)
              end
            ensure
              terminate_all(active, results)
            end

            results
          end

          def start_children(pending, active)
            index, worktree = pending.shift
            pipe_read, pipe_write = IO.pipe
            pid = fork do
              child_process(pipe_read, pipe_write, worktree)
              exit!(0)
            end

            pipe_write.close
            pipe_read.binmode
            active[pid] = {
              index: index,
              pipe: pipe_read,
              buffer: +"",
              deadline: monotonic_now + @timeout
            }
          end

          # Body executed in the forked child. Never raises to the parent and
          # never writes to the inherited terminal.
          def child_process(pipe_read, pipe_write, worktree)
            pipe_read.close
            begin
              Process.setpgid(0, 0)
            rescue StandardError
              # Process group isolation is best effort on exotic platforms.
            end
            begin
              STDOUT.reopen(File::NULL)
              STDERR.reopen(File::NULL)
            rescue StandardError
              nil
            end

            payload = execute_probe(worktree)
            pipe_write.write(JSON.generate(payload)) if payload
          rescue Exception # rubocop:disable Lint/RescueException
            nil
          ensure
            begin
              pipe_write.close
            rescue StandardError
              nil
            end
          end

          # Wait for at least one child to finish or for the nearest deadline.
          def wait_for_results(active, results)
            pipes = active.values.map { |job| job[:pipe] }
            nearest_deadline = active.values.map { |job| job[:deadline] }.min
            wait_seconds = [nearest_deadline - monotonic_now, 0].max

            ready = IO.select(pipes, nil, nil, wait_seconds)

            if ready.nil?
              expire_timed_out(active, results)
            else
              ready.first.each { |pipe| drain_child_pipe(pipe, active, results) }
              expire_timed_out(active, results)
            end
          end

          # Read currently available bytes; on EOF parse and reap the child.
          def drain_child_pipe(pipe, active, results)
            job = active.values.find { |candidate| candidate[:pipe] == pipe }
            return unless job

            loop do
              job[:buffer] << pipe.read_nonblock(65_536)
            rescue IO::WaitReadable
              return
            rescue EOFError
              finish_job(active, job, success: true, results: results)
              return
            end
          end

          def finish_job(active, job, success:, results:)
            pid = active.key(job)
            active.delete(pid) if pid

            if success
              results[job[:index]] = parse_payload(job[:buffer])
            end

            begin
              job[:pipe].close unless job[:pipe].closed?
            rescue StandardError
              nil
            end

            reap(pid) if pid
          end

          def expire_timed_out(active, results)
            now = monotonic_now
            active.values.each do |job|
              next if job[:deadline] > now

              pid = active.key(job)
              next unless pid

              terminate(pid)
              results[job[:index]] = nil
              begin
                job[:pipe].close unless job[:pipe].closed?
              rescue StandardError
                nil
              end
              active.delete(pid)
            end
          end

          # Kill a child's process group (TERM, then KILL) and reap it.
          def terminate(pid)
            terminate_process_group(pid, "TERM")
            # Give the child a brief chance to exit cleanly.
            deadline = monotonic_now + 0.2
            loop do
              break if reap_nonblocking(pid)
              break if monotonic_now > deadline

              sleep 0.01
            end
            terminate_process_group(pid, "KILL")
            reap(pid)
          rescue Errno::ESRCH
            nil
          end

          def terminate_all(active, results)
            active.each do |pid, job|
              terminate(pid)
              results[job[:index]] ||= nil
            end
            active.clear
          end

          def terminate_process_group(pid, signal)
            Process.kill("-#{signal}", pid)
          rescue Errno::ESRCH
            # Group already gone.
            nil
          rescue StandardError
            begin
              Process.kill(signal, pid)
            rescue StandardError
              nil
            end
          end

          def reap(pid)
            Process.wait(pid)
          rescue Errno::ECHILD
            nil
          end

          def reap_nonblocking(pid)
            reaped = Process.wait(pid, Process::WNOHANG)
            !reaped.nil?
          rescue Errno::ECHILD
            true
          end

          # --- Sequential fallback ---

          def sequential_all(worktrees)
            worktrees.map do |worktree|
              Timeout.timeout(@timeout) { normalize_payload(execute_probe(worktree)) }
            rescue Timeout::Error, StandardError
              nil
            end
          end

          # --- Probe execution ---

          def execute_probe(worktree)
            if @probe
              @probe.call(worktree)
            else
              WorktreeProbe.new(project_root: @project_root, base_ref: @base_ref).probe(worktree.path)
            end
          end

          def parse_payload(buffer)
            return nil if buffer.to_s.strip.empty?

            normalize_payload(JSON.parse(buffer))
          rescue JSON::ParserError
            nil
          end

          def normalize_payload(payload)
            return nil unless payload.is_a?(Hash)

            deep_symbolize(payload)
          end

          def deep_symbolize(value)
            case value
            when Hash
              value.each_with_object({}) { |(key, item), memo| memo[key.to_sym] = deep_symbolize(item) }
            when Array
              value.map { |item| deep_symbolize(item) }
            else
              value
            end
          end

          def monotonic_now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end
        end
      end
    end
  end
end
