# frozen_string_literal: true

require "pty"
require "io/console"
require "securerandom"
require_relative "session_launch_peer"
require_relative "session_command"
require_relative "session_preparation"
require_relative "session_project_mount"

module Ace
  module Lab
    module Auth
      # Runs in one supervised issuer child. It owns the unit, PTY and
      # lifecycle channel until whole-unit stop and lease cleanup complete.
      class SessionLaunchRequest
        def initialize(peer: SessionLaunchPeer.new, command: SessionCommand.new,
          launcher: SessionLauncher.new, preparation: SessionPreparation.new,
          mount: SessionProjectMount.new, service: -> { Service.new })
          @peer, @command, @launcher, @preparation, @mount, @service = peer, command, launcher, preparation, mount, service
        end

        def call(socket, request:, invocation:, supervising:)
          @peer.with_selection(socket, project: request.fetch("project"), role: request.fetch("role"),
            terminal_id: request["terminal_id"]) do |selection, caller|
            unit = @command.build(selection: selection, id: SecureRandom.hex(8), terminal_id: request["terminal_id"], cwd: request["cwd"])
            supervising.call
            run(socket, request, invocation, unit, selection, caller)
          end
        end

        private

        def run(socket, request, invocation, unit, selection, caller)
          launched = identity = nil
          contained = cleaned = false
          stage = "terminal"
          PTY.open do |master, slave|
            slave.winsize = [request.fetch("rows"), request.fetch("cols")]
            slave.echo = false
            begin
              stage = "start"
              launched = @launcher.start(unit: unit, terminal: slave)
              stage = "identify"
              identity = identify(launched)
              stage = "prepare"
              @preparation.call(identity: identity, selection: selection)
              stage = "mount"
              @mount.call(identity: identity, project: selection.path)
              stage = "release"
              raise Error, "launch caller exited during preparation" if IO.select([caller], nil, nil, 0)
              # Release only after all private mounts and credentials exist.
              master.write("start\n")
              stage = "handoff"
              @launcher.handoff(identity, terminal: master, channel: socket,
                rows: request.fetch("rows"), cols: request.fetch("cols"), directory: unit.directory)
              stage = "wait"
              stopped = await_exit(socket, identity, caller)
              stage = "stop"
              @launcher.stop(identity)
              contained = true
              result = reap(launched.transport_pid)
              launched = nil
              stage = "revoke"
              @service.call.revoke_session(issuer_invocation: invocation, unit: identity.unit,
                invocation: identity.invocation_id)
              cleaned = true
              stage = "reply"
              exit_code = stopped ? 143 : result.exitstatus || 128 + result.termsig.to_i
              wire = Ace::Runtime::Molecules::ProtectedSocket
              wire.write(socket, {"unit" => identity.unit, "invocation" => identity.invocation_id,
                "exit_code" => [exit_code, 255].min, "cleanup_confirmed" => true}, deadline: wire.deadline, limit: 1024)
              :completed
            ensure
              # Failure after spawn must either prove containment or fail the
              # handler. IssuerServer then stops admission; BindsTo contains
              # all session units before issuer recovery runs.
              begin
                if identity && !contained
                  @launcher.stop(identity)
                  contained = true
                end
                if identity && contained && !cleaned
                  @service.call.revoke_session(issuer_invocation: invocation, unit: identity.unit,
                    invocation: identity.invocation_id)
                  cleaned = true
                end
                reap(launched.transport_pid) if launched && contained
                raise Error, "session launch containment is unconfirmed" if launched && !contained
              ensure
                identity&.close
              end
            end
          end
        rescue StandardError => error
          # Never log exception text: parser/provider failures can contain
          # credential bytes. Fixed stages identify the failing boundary.
          warn JSON.generate(event: "session_launch_failed", stage: stage,
            error_class: error.class.name, contained: contained, cleaned: cleaned)
          # A lost terminal/client must not kill unrelated sessions once
          # this unit and its grants are confirmed closed.
          contained && cleaned ? :refused : :cleanup_failed
        end

        def identify(launch)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
          loop do
            begin
              return @launcher.identify(launch)
            rescue Error
              raise if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
              sleep 0.05
            end
          end
        end

        def reap(pid)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 15
          loop do
            result = Process.waitpid2(pid, Process::WNOHANG)
            return result.last if result
            raise Error, "session transport termination is unconfirmed" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            sleep 0.02
          end
        end

        def await_exit(socket, identity, caller)
          pending = +""
          deadline = nil
          loop do
            timeout = deadline && deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise Error, "session control request deadline expired" if timeout && !timeout.positive?
            ready = IO.select([identity.pidfd, caller, socket], nil, nil, timeout)
            raise Error, "session control request deadline expired" unless ready
            return false if ready.first.include?(identity.pidfd)
            return true if ready.first.include?(caller)
            bytes = socket.read_nonblock(1025, exception: false)
            return true if bytes.nil?
            next if bytes == :wait_readable
            deadline ||= Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
            pending << bytes
            raise Error, "session control request exceeds limit" if pending.bytesize > 1024
            next unless pending.include?("\n")
            value = JSON.parse(pending, create_additions: false, allow_duplicate_key: false, max_nesting: 2)
            expected = {"action" => "stop", "unit" => identity.unit, "invocation" => identity.invocation_id}
            raise Error, "session control identity differs" unless value == expected && pending.end_with?("\n")
            return true
          end
        end
      end
    end
  end
end
