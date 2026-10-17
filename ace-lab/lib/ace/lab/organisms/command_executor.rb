# frozen_string_literal: true

require "json"
require "pty"
require "etc"
require "fiddle"
require "base64"
require "io/console"
require "ace/runtime/molecules/owned_child_scope"
require_relative "command_run_client"
require_relative "command_candidate_view"

module Ace
  module Lab
    module Organisms
      # Short-lived execution child of the installed root labd, not a listener
      # or another journal owner. A single Ruby thread forks the gated executor.
      class CommandExecutor
        def initialize(project:, owner: nil)
          @project = project
          @owner = owner || CommandRunClient.new(project: project).owner
        end

        def run(socket:, request:)
          raise SecurityError, "command executor requires Linux root" unless RUBY_PLATFORM.include?("linux") && Process.uid.zero? && Process.euid.zero?
          strict!(request, %w[execution_id caller tty rows cols])
          id = request.fetch("execution_id")
          raise ArgumentError, "invalid command reference" unless id.is_a?(String) && Molecules::CommandPolicy::ID.match?(id)
          interactive = request.fetch("tty")
          raise ArgumentError, "invalid terminal mode" unless [true, false].include?(interactive)
          rows, cols = geometry(request)
          params = {"execution_id" => id}
          initial = @owner.call("command_status", params).data
          unless initial["phase"] == "admitted" && initial.dig("definition", "requester") == request.fetch("caller")
            raise SecurityError, "original command already claimed or requester differs"
          end
          definition = initial.fetch("definition")
          unless definition.fetch("secret_references").empty?
            raise SecurityError, "secret command execution capability is not installed"
          end
          claimed = @owner.call("command_claim", params.merge("caller" => request.fetch("caller")), mutation_id: "command-claim.#{id}")
          raise SecurityError, "claim replay cannot execute" if claimed.replayed
          if definition["materialization"]
            CommandCandidateView.new(project: @project, definition: definition).prepare! do |scratch|
              client = CommandRunClient.new(project: @project).owner(scratch_root: scratch)
              client.call("command_candidate", params, download: true, purpose: :candidate).parts.fetch(0)
            end
          end
          launch(socket, id, definition, interactive, rows, cols)
        end

        private

        def launch(socket, id, definition, interactive, rows, cols)
          raise SecurityError, "command fork requires a single-thread helper" unless Thread.list.count(&:alive?) == 1
          scope = Ace::Runtime::Molecules::OwnedChildScope.new
          executor = definition.fetch("executor")
          user = Etc.getpwuid(executor.fetch("uid"))
          environment = {"HOME" => executor.fetch("home"), "USER" => user.name, "LOGNAME" => user.name,
            "PATH" => executor.fetch("path").join(":")}.merge(executor.fetch("environment"))
          if interactive
            parent_input, child_output = PTY.open
            parent_output, child_input = parent_input, child_output
            child_output.winsize = [rows, cols]
          else
            child_input, parent_input = IO.pipe
            parent_output, child_output = IO.pipe
            parent_error, child_error = IO.pipe
          end
          gate_read, gate_write = IO.pipe
          ready_read, ready_write = IO.pipe
          child = fork do
            begin
              socket.close
              [parent_input, parent_output, parent_error, gate_write, ready_read].compact.uniq.each(&:close)
              Process.setsid
              child_input.ioctl(0x540E, 0) if interactive # Linux TIOCSCTTY
              $stdin.reopen(child_input)
              $stdout.reopen(child_output)
              $stderr.reopen(child_error || child_output)
              [child_input, child_output, child_error].compact.uniq.each(&:close)
              Process.groups = executor.fetch("groups")
              Process::GID.change_privilege(executor.fetch("gid"))
              Process::UID.change_privilege(executor.fetch("uid"))
              File.umask(0o077)
              prctl = Fiddle::Function.new(Fiddle::Handle::DEFAULT["prctl"],
                [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG], Fiddle::TYPE_INT)
              raise SecurityError, "cannot inhibit privilege gain" unless prctl.call(38, 1, 0, 0, 0).zero?
              Dir.chdir(executor.fetch("cwd"))
              ready_write.write("R")
              ready_write.close
              exit! 125 unless IO.select([gate_read], nil, nil, 35) && gate_read.read(1) == "E"
              gate_read.close
              argv = definition.fetch("argv")
              exec(environment, [File.expand_path(argv.first), argv.first], *argv.drop(1), unsetenv_others: true)
            rescue Exception
              exit! 126
            end
          end
          [child_input, child_output, child_error, gate_read, ready_write].compact.uniq.each(&:close)
          unless IO.select([ready_read], nil, nil, 10) && ready_read.read(1) == "R"
            raise SecurityError, "child did not reach admission gate"
          end
          ready_read.close
          witness = child_witness(child)
          bound = @owner.call("command_bind", {"execution_id" => id, "child" => witness}, mutation_id: "command-bind.#{id}")
          raise SecurityError, "binding replay cannot execute" if bound.replayed
          gate_write.write("E")
          gate_write.close
          send_frame(socket, {"type" => "started", "execution_id" => id})
          outputs = {parent_output => interactive ? "terminal" : "stdout"}
          outputs[parent_error] = "stderr" if parent_error
          pump(socket, parent_input, outputs, child, interactive)
          scope.cleanup!(leader: child)
          _, result = Process.waitpid2(child)
          reaped = true
          termination = {"exit_status" => result.exitstatus, "signal" => result.termsig}
          @owner.call("command_complete", {"execution_id" => id, "result" => termination}, mutation_id: "command-complete.#{id}")
          send_frame(socket, termination.merge("type" => "result", "execution_id" => id))
          result.exitstatus || 128 + result.termsig
        ensure
          [gate_write, ready_read, parent_input, parent_output, parent_error].compact.uniq.each { |io| io.close unless io.closed? }
          if child && !reaped
            scope.cleanup!(leader: child)
            deadline = monotonic + 5
            loop do
              break if Process.waitpid(child, Process::WNOHANG)
              break if monotonic >= deadline
              IO.select(nil, nil, nil, 0.01)
            end
          end
        end

        def pump(socket, input, outputs, child, interactive)
          pending = "".b
          pending_input = "".b
          input_open = true
          input_finished = false
          terminal_at = nil
          loop do
            terminal_at ||= monotonic if zombie?(child)
            break if terminal_at && (outputs.empty? || monotonic - terminal_at >= 1)
            readers = (pending_input.bytesize < 131_072 ? [socket] : []) + outputs.keys
            ready = IO.select(readers, pending_input.empty? || input.closed? ? [] : [input], nil, 0.1)
            next unless ready
            if ready.first.include?(socket)
              bytes = socket.read_nonblock(65_536, exception: false)
              next if bytes == :wait_readable
              raise IOError, "command client disconnected" unless bytes
              pending << bytes
              raise ArgumentError, "command frame exceeds bound" if pending.bytesize > 131_072
              while (newline = pending.index("\n"))
                frame = JSON.parse(pending.slice!(0, newline + 1))
                case frame.fetch("type")
                when "input"
                  strict!(frame, %w[type data])
                  raise ArgumentError, "command input after EOF" unless input_open
                  pending_input << Base64.strict_decode64(frame.fetch("data"))
                  raise ArgumentError, "command buffered input exceeds bound" if pending_input.bytesize > 131_072
                when "resize"
                  strict!(frame, %w[type rows cols])
                  raise ArgumentError, "resize requires a terminal" unless interactive
                  input.winsize = geometry(frame)
                when "eof"
                  strict!(frame, %w[type])
                  raise ArgumentError, "duplicate input EOF" unless input_open
                  pending_input << "\x04" if interactive
                  input_open = false
                else raise ArgumentError, "invalid command input"
                end
              end
            end
            if ready[1].include?(input)
              written = input.write_nonblock(pending_input, exception: false)
              pending_input.slice!(0, written) if written.is_a?(Integer)
            end
            if !input_open && pending_input.empty? && !input_finished
              input.close unless interactive
              input_finished = true
            end
            outputs.keys.each do |output|
              next unless ready.first.include?(output)
              begin
                bytes = output.read_nonblock(65_536, exception: false)
              rescue Errno::EIO
                bytes = nil
              end
              next if bytes == :wait_readable
              if bytes
                send_frame(socket, {"type" => "output", "stream" => outputs.fetch(output), "data" => Base64.strict_encode64(bytes)})
              else
                outputs.delete(output)
              end
            end
          end
        end

        def child_witness(pid)
          observer = Ace::Runtime::Molecules::ProcessIdentity.new(executor:
            Ace::Herdr::Molecules::BoundedObservation.new(deadline: monotonic + 5))
          identity = observer.capture(pid)
          raise SecurityError, "child generation unavailable" unless identity
          status = File.readlines("/proc/#{pid}/status").filter_map { |line| line.include?(":") && line.split(":", 2) }.to_h
          identity.merge("gid" => status.fetch("Gid").split.first.to_i, "groups" => status.fetch("Groups").split.map(&:to_i).sort,
            "cwd" => File.readlink("/proc/#{pid}/cwd"), "process_group" => Process.getpgid(pid),
            "no_new_privs" => Integer(status.fetch("NoNewPrivs").strip, 10),
            "capabilities" => %w[CapInh CapPrm CapEff CapAmb].to_h { |key| [key, status.fetch(key).strip] })
        end

        def zombie?(pid) = File.read("/proc/#{pid}/stat").split(")").last.split.first == "Z"
        def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        def geometry(value)
          rows, cols = value.values_at("rows", "cols")
          raise ArgumentError, "invalid command geometry" unless [rows, cols].all? { |v| v.is_a?(Integer) && v.between?(1, 65_535) }
          [rows, cols]
        end
        def strict!(value, keys)
          raise ArgumentError, "invalid command fields" unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end
        def send_frame(socket, frame)
          Ace::Runtime::Molecules::ProtectedSocket.write(socket, frame,
            deadline: Ace::Runtime::Molecules::ProtectedSocket.deadline(5), limit: 131_072)
        end
      end
    end
  end
end
