# frozen_string_literal: true

require "json"
require "securerandom"
require "fileutils"
require "base64"
require "io/console"
require "ace/assign/authority/ordinary_client"
require_relative "../molecules/ordinary_owner_config"
require_relative "../molecules/command_policy"

module Ace
  module Lab
    module Organisms
      class CommandRunClient
        def initialize(project:)
          @project = project
          @config = Molecules::OrdinaryOwnerConfig.load(project: project)
        end

        def owner(scratch_root: nil)
          Ace::Assign::Authority::OrdinaryClient.new(project_id: @project, service: @config.service,
            verify_selection: @config.method(:verify_owner!), scratch_root: scratch_root)
        end

        def status(reference)
          owner.call("command_status", {"execution_id" => reference}).data
        end

        def run(argv:, executor:, services:, pane: nil, candidate: nil)
          id = SecureRandom.hex(16)
          selection = {"argv" => argv, "executor" => executor, "services" => services, "pane" => pane}
          selection["candidate"] = candidate if candidate
          request = {"project" => @project, "execution_id" => id, "selection" => selection,
            "mutation_id" => "command-admit.#{id}"}
          parent = File.expand_path(".ace-local/lab-commands")
          FileUtils.mkdir_p(parent, mode: 0o700)
          directory = File.join(parent, id)
          Dir.mkdir(directory, 0o700)
          File.open(File.join(directory, "request.json"), File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
            file.write(JSON.generate(request) + "\n")
            file.flush
            file.fsync
          end
          File.open(directory, File::RDONLY) { |parent_io| parent_io.fsync }
          $stderr.puts "Execution #{id}; inspect with ace-lab run-status --project #{@project} --reference #{id}"
          reply = owner.call("command_admit", {"execution_id" => id, "selection" => selection}, mutation_id: request.fetch("mutation_id"))
          raise Ace::Assign::AttemptErrors::Conflict, "original command admission must be reconciled" if reply.replayed
          stream(id)
        end

        private

        def stream(id)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          policy = Molecules::CommandPolicy.load(project: @project)
          path = policy.launcher.fetch("socket_path")
          wire.root_path!(File.dirname(path), directory: true)
          endpoint = wire.socket_identity(path, mode: 0o660)
          raise SecurityError, "command launcher endpoint owner differs" unless endpoint.last.zero?
          expected = JSON.parse(Molecules::GrantResolver.read_verified(policy.launcher.fetch("identity_path")) || "null")
          wire.connect(path, deadline: wire.deadline(5)) do |socket|
            peer = Ace::Assign::Authority::OrdinaryPeer.new.capture(socket)
            unless expected.is_a?(Hash) && expected["schema"] == "labd-command-launcher/v1" && expected["identity"] == peer
              raise SecurityError, "command launcher generation differs"
            end
            interactive = $stdin.tty? && $stdout.tty?
            rows, cols = interactive ? $stdin.winsize : [24, 80]
            wire.write(socket, {"op" => "command_run", "project" => @project, "execution_id" => id,
              "tty" => interactive, "rows" => rows, "cols" => cols}, deadline: wire.deadline(5), limit: 16_384)
            if interactive
              $stdin.raw { pump(socket, id, interactive: true) }
            else
              pump(socket, id, interactive: false)
            end
          end
        end

        def pump(socket, id, interactive:)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          ingress = wire::Ingress.new(socket)
          inputs = [socket]
          resize = false
          old_winch = Signal.trap("WINCH") { resize = true } if interactive
          loop do
            if resize
              resize = false
              rows, cols = $stdin.winsize
              wire.write(socket, {"type" => "resize", "rows" => rows, "cols" => cols}, deadline: wire.deadline(5), limit: 131_072)
            end
            ready = IO.select(inputs, nil, nil, 0.25)
            next unless ready
            if ready.first.include?(socket)
              frame = wire.read(ingress, deadline: wire.deadline(5), limit: 131_072)
              case frame["type"]
              when "started"
                raise SecurityError, "invalid command start frame" unless frame.keys.sort == %w[execution_id type]
                raise SecurityError, "command reference differs" unless frame["execution_id"] == id
                inputs << $stdin unless inputs.include?($stdin)
              when "output"
                raise SecurityError, "invalid command output frame" unless frame.keys.sort == %w[data stream type] && %w[stdout stderr terminal].include?(frame["stream"])
                destination = frame["stream"] == "stderr" ? $stderr : $stdout
                destination.write(Base64.strict_decode64(frame.fetch("data")))
                destination.flush
              when "result"
                raise SecurityError, "invalid command result frame" unless frame.keys.sort == %w[execution_id exit_status signal type]
                raise SecurityError, "command reference differs" unless frame["execution_id"] == id
                exited, signal = frame.values_at("exit_status", "signal")
                if exited.is_a?(Integer) && exited.between?(0, 255) && signal.nil?
                  return exited
                elsif exited.nil? && signal.is_a?(Integer) && signal.between?(1, 127)
                  return 128 + signal
                end
                raise SecurityError, "command termination is invalid"
              else
                raise SecurityError, "command stream is incomplete"
              end
            end
            next unless ready.first.include?($stdin)
            bytes = $stdin.read_nonblock(8192, exception: false)
            next if bytes == :wait_readable
            frame = bytes ? {"type" => "input", "data" => Base64.strict_encode64(bytes)} : {"type" => "eof"}
            wire.write(socket, frame, deadline: wire.deadline(5), limit: 131_072)
            inputs.delete($stdin) unless bytes
          end
        ensure
          Signal.trap("WINCH", old_winch) if old_winch
        end
      end
    end
  end
end
