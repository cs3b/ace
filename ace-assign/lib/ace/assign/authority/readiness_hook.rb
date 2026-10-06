# frozen_string_literal: true
require "socket"
require_relative "../errors"
require "ace/runtime/molecules/readiness_configuration"
require "ace/runtime/molecules/server_resource_observation"
require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/protected_socket"
require_relative "transfer_codec"

module Ace
  module Assign
    module Authority
      # Fixed ExecStartPost action, deliberately independent of Deployment.load.
      class ReadinessHook
        def initialize(slot:, configuration: nil, kernel: Ace::Runtime::Molecules::ProtectedLinux.new,
          resources: nil, wire: Ace::Runtime::Molecules::ProtectedSocket)
          @configuration = configuration || Ace::Runtime::Molecules::ReadinessConfiguration.load(slot: slot)
          @kernel, @wire = kernel, wire
          @resources = resources || Ace::Runtime::Molecules::ServerResourceObservation.new(kernel: kernel)
        end

        def run
          config = @configuration.data
          @kernel.supported!
          hook = @kernel.capture(Process.pid)
          expected = config.fetch("worker")
          unless hook.values_at("uid", "gid", "groups") == expected.values_at("uid", "gid", "groups")
            raise AttemptErrors::UnauthorizedIdentity, "readiness hook principal differs"
          end
          deadline = @wire.deadline(10)
          authority = config.fetch("authority")
          path = authority.fetch("socket_path")
          @wire.root_path!(File.dirname(path), directory: true, owner: authority.fetch("uid"))
          endpoint = @wire.socket_identity(path)
          @wire.connect(path) do |socket|
            peer = @kernel.peer(socket)
            unless peer.values_at("uid", "gid", "groups") == authority.values_at("uid", "gid", "groups") &&
                @wire.socket_identity(path) == endpoint
              raise AttemptErrors::UnauthorizedIdentity, "readiness authority peer differs"
            end
            @wire.write(socket, {"version" => 1, "operation" => "native_readiness", "mutation_id" => nil,
              "project_id" => config.fetch("project_id"), "params" => {"mapping_id" => config.fetch("mapping_id")}},
              deadline: deadline, limit: 16_384)
            challenge = @wire.read(socket, deadline: deadline, limit: 16_384)
            unless challenge.is_a?(Hash) && challenge.keys.sort == %w[challenge_id server_identity version] &&
                challenge["version"] == 1 && challenge["challenge_id"].is_a?(String) &&
                challenge["challenge_id"].match?(/\A[0-9a-f]{64}\z/)
              raise AttemptErrors::EvidenceUnavailable, "private readiness challenge differs"
            end
            manifest_bytes = nil
            Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |reader|
              manifest_bytes, = reader.read_path!(config.dig("boundary_manifest", "path"), limit: 65_536)
              unless Digest::SHA256.hexdigest(manifest_bytes) == config.dig("boundary_manifest", "sha256")
                raise AttemptErrors::EvidenceUnavailable, "readiness boundary bytes differ"
              end
              reader.verify_unchanged!
            end
            manifest = JSON.parse(manifest_bytes.force_encoding(Encoding::UTF_8), create_additions: false,
              max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
            entries = manifest.fetch("resources").select { |entry| entry.fetch("worker_visible") }
            server = challenge.fetch("server_identity")
            native_path = config.dig("native", "executable")
            File.open("/proc/#{server.fetch('pid')}/exe", File::RDONLY) do |executable|
              unless Digest::SHA256.hexdigest(executable.read(268_435_457)) == config.dig("native", "executable_sha256") &&
                  File.read("/proc/#{server.fetch('pid')}/cmdline", 16_385).split("\0") == [native_path, "server"]
                raise AttemptErrors::EvidenceUnavailable, "readiness native executable differs"
              end
            end
            report = @resources.observe!(server: server, entries: entries)
            report = report.merge("version" => 1, "challenge_id" => challenge.fetch("challenge_id"),
              "server_identity" => challenge.fetch("server_identity"), "resource_observer_identity" => hook)
            bytes = JSON.generate(report)
            codec = TransferCodec.new
            transfer = codec.descriptor([bytes], purpose: :scope_boundary_observation)
            @wire.write(socket, {"version" => 1, "challenge_id" => challenge.fetch("challenge_id"), "transfer" => transfer},
              deadline: deadline, limit: 16_384)
            codec.send(socket, parts: [bytes], descriptor: transfer, purpose: :scope_boundary_observation, deadline: deadline)
            socket.shutdown(Socket::SHUT_WR)
            acknowledgment = @wire.read(socket, deadline: deadline, limit: 16_384)
            unless acknowledgment == {"version" => 1, "challenge_id" => challenge.fetch("challenge_id"), "status" => "ready"}
              raise AttemptErrors::EvidenceUnavailable, "private readiness acknowledgement differs"
            end
            @kernel.live!(hook)
            @kernel.live!(peer)
            raise AttemptErrors::EvidenceUnavailable, "readiness endpoint changed" unless @wire.socket_identity(path) == endpoint
          end
          true
        rescue SystemCallError, IOError, JSON::ParserError, KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "private readiness observation unavailable"
        end
      end
    end
  end
end
