# frozen_string_literal: true

require "json"
require "ace/assign/cli"
require "ace/runtime/molecules/process_identity"
require_relative "proposal_tick"
require_relative "../organisms/launch_recovery"

module Ace
  module Overseer
    module Molecules
      # Own one foreground child of the already loaded fixed Assign CLI. The
      # process boundary is injected in controlled tests, never selected by input.
      class OriginalLaunchChild
        LIMIT = 16_384
        DEADLINE = 30
        DRAIN_LIMIT = 65_536
        READY_FIELDS = %w[assignment_id attempt_id generation journal_commit mapping_id original_binding_digest type version].sort.freeze
        class ProcessBoundary
          def supported? = Process.respond_to?(:fork)
          def pipe = IO.pipe
          def fork_loaded(argv:, reader:, writer:)
            Process.fork do
              reader.close
              STDOUT.reopen(writer)
              writer.close
              $stdout = STDOUT
              begin
                code = Ace::Assign::CLI.start(argv)
                Process.exit!(code.is_a?(Integer) ? code : 0)
              rescue SystemExit => error
                Process.exit!(error.status)
              rescue Exception => error
                warn "Original Assign child failed (#{error.class}): #{error.message}"
                Process.exit!(1)
              end
            end
          end
          def wait(pid) = Process.waitpid2(pid, Process::WNOHANG)
          def readable?(reader, timeout) = !!IO.select([reader], nil, nil, timeout)
        end

        attr_reader :pid, :identity, :state, :error, :ready, :exit_status

        def initialize(process: ProcessBoundary.new, kernel: Ace::Runtime::Molecules::ProcessIdentity.new,
          threads: -> { Thread.list }, quiescent: -> { ProposalTick.quiescent? },
          clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
          @process, @kernel, @threads, @quiescent, @clock = process, kernel, threads, quiescent, clock
          @state = "not_started"
        end

        def start(request:, definition_path:, bundle_path:)
          raise Error, "Original child already selected" unless state == "not_started"
          raise Error, "Loaded CLI fork is unsupported" unless @process.supported?
          safe_boundary!
          argv = ["authority", "launch", "--mapping", request.fetch("mapping_id"), "--assignment", request.fetch("assignment_id"),
            "--definition", definition_path, "--prepared-bundle", bundle_path, "--step", request.fetch("scope"),
            "--base-head", request.fetch("base_head"), "--mutation", request.fetch("mutation_id")].freeze
          @request = request
          @reader, writer = @process.pipe
          opened_here = true
          safe_boundary!
          @readiness_deadline = @clock.call + DEADLINE
          @pid = @process.fork_loaded(argv: argv, reader: @reader, writer: writer)
          started_here = true
          @state = "awaiting_ready"
          writer.close
          @identity = @kernel.capture(pid)
          if identity
            identity.each_value(&:freeze)
            identity.freeze
          end
          uncertain!("Original child birth is unavailable") unless identity
          self
        rescue StandardError, NotImplementedError
          if started_here
            uncertain!("Original child startup observation failed")
            self
          else
            @reader&.close if opened_here
            raise
          end
        ensure
          writer&.close unless writer&.closed?
        end

        def await_ready(status:)
          return self unless state == "awaiting_ready"
          bytes = +"".b
          loop do
            remaining = @readiness_deadline - @clock.call
            return uncertain!("Original child readiness timed out") unless remaining.positive? && @process.readable?(@reader, remaining)
            chunk = @reader.read_nonblock(LIMIT + 1 - bytes.bytesize, exception: false)
            next if chunk == :wait_readable
            return uncertain!("Original child ended before readiness") if chunk.nil?
            return uncertain!("Original child readiness timed out after receipt") unless @clock.call < @readiness_deadline
            bytes << chunk
            return uncertain!("Original child readiness exceeds bound") if bytes.bytesize > LIMIT
            next unless bytes.include?("\n")
            return uncertain!("Original child readiness has extra output") unless bytes.end_with?("\n") && bytes.count("\n") == 1
            text = bytes.dup.force_encoding(Encoding::UTF_8)
            raise Error, "Original child readiness is not UTF-8" unless text.valid_encoding?
            ready = JSON.parse(text, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
            unless ready.is_a?(Hash) && ready.keys.sort == READY_FIELDS && ready["version"].is_a?(Integer) && ready["version"] == 1 &&
                ready["type"] == "launch_ready" && ready.values_at("mapping_id", "assignment_id") == @request.values_at("mapping_id", "assignment_id") &&
                @kernel.capture(pid) == identity
              raise Error, "Original child readiness differs from original selection"
            end
            return uncertain!("Original child readiness timed out before canonical join") unless @clock.call < @readiness_deadline
            canonical = status.join_ready!(project: @request.fetch("project_id"), agent: @request.fetch("mapping_id"), ready: ready)
            Organisms::LaunchRecovery.verify_original!(request: @request, row: canonical.fetch("item"))
            return uncertain!("Original child readiness timed out during canonical join") unless @clock.call < @readiness_deadline
            raise Error, "Original child birth changed during readiness join" unless @kernel.capture(pid) == identity
            ready.each_value(&:freeze)
            @ready = ready.freeze
            @state = "ready"
            return self
          end
        rescue StandardError => error
          uncertain!("Original child readiness unavailable: #{error.message}")
        end

        # No lifetime deadline, replacement, signal or detached waiter. Reaping
        # this exact owned child is observation, never canonical release proof.
        def observe
          return self unless pid && state != "exited"
          if %w[ready uncertain].include?(state) && @process.readable?(@reader, 0)
            # Discard at most one bounded chunk per observation, including
            # uncertain children. Never retain arbitrary output or let an
            # ignored stdout pipe deadlock the same original foreground owner.
            extra = @reader.read_nonblock(DRAIN_LIMIT, exception: false)
            uncertain!("Original child emitted output outside readiness") if extra.is_a?(String) && !extra.empty?
          end
          result = @process.wait(pid)
          if result
            raise Error, "Wait selected a different child" unless result.first == pid
            @exit_status = result.last
            @reader.close unless @reader.closed?
            @state = "exited"
          elsif identity && @kernel.capture(pid) != identity
            uncertain!("Original child birth is no longer observable")
          end
          self
        rescue StandardError => error
          uncertain!("Original child observation unavailable: #{error.message}")
        end

        private

        def safe_boundary!
          live = @threads.call.select(&:alive?)
          unless live == [Thread.current] && @quiescent.call
            raise Error, "Loaded CLI fork requires one quiescent coordinator thread with no held coordination lock"
          end
        end

        def uncertain!(message)
          @error = message
          @state = "uncertain"
          self
        end
      end
    end
  end
end
