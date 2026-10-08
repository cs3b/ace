# frozen_string_literal: true

require "ace/runtime/molecules/protected_linux"
require_relative "inbox_context_wire"
require_relative "inbox_direct_result"

module Ace
  module Herdr
    module Molecules
      # Constructor inputs come only from the verified installed context map.
      class InboxContextClient
        def self.selected(context_id:, socket_path:, owner_credentials:, **options)
          new(context_id: context_id, socket_path: socket_path, owner_identity: nil,
            owner_credentials: owner_credentials, **options)
        end

        def initialize(context_id:, socket_path:, owner_identity:, owner_credentials: nil, kernel: Ace::Runtime::Molecules::ProtectedLinux.new,
          wire: Ace::Runtime::Molecules::ProtectedSocket)
          @context_id, @socket_path, @identity, @kernel, @wire = context_id, socket_path, owner_identity, kernel, wire
          @credentials = owner_credentials || owner_identity&.slice("uid", "gid", "groups")
          unless @credentials.is_a?(Hash) && @credentials.keys.sort == %w[gid groups uid] &&
              @credentials.values_at("uid", "gid").all? { |value| value.is_a?(Integer) && value.positive? } &&
              @credentials["groups"].is_a?(Array) && @credentials["groups"].size <= 64 &&
              @credentials["groups"].all? { |value| value.is_a?(Integer) && value.positive? } && @credentials["groups"] == @credentials["groups"].sort.uniq
            raise ValidationError, "context fixed owner credentials differ"
          end
          @selection_mutex = Mutex.new
        end

        def request(operation, params, proof: nil, payload: nil)
          if %w[reconcile_context verify_context_reconciliation].include?(operation)
            unless proof.is_a?(Array) && proof.size == 2 && proof.all? { |part| part.is_a?(String) && part.bytesize.between?(1, InboxContextWire::LIMIT) }
              raise ValidationError, "context proof parts differ"
            end
            params = params.merge("proof_sizes" => proof.map(&:bytesize))
          elsif proof
            raise ValidationError, "context operation does not accept proof bytes"
          end
          if operation == "enqueue_context"
            unless payload.is_a?(String) && payload.bytesize.between?(1, 65_536) &&
                params["payload_bytes"] == payload.bytesize && params["payload_sha256"] == Digest::SHA256.hexdigest(payload)
              raise ValidationError, "context payload differs"
            end
          elsif payload
            raise ValidationError, "context operation does not accept payload"
          end
          @wire.root_path!(File.dirname(@socket_path), directory: true, owner: @credentials.fetch("uid"))
          before = @wire.socket_identity(@socket_path)
          raise ValidationError, "context socket owner differs" unless before[2] == @credentials.fetch("uid")
          @kernel.live!(@identity) if @identity
          deadline = InboxContextWire.deadline
          @wire.connect(@socket_path, deadline: deadline) do |socket|
            observed = @kernel.peer(socket)
            unless observed.values_at("uid", "gid", "groups") == @credentials.values_at("uid", "gid", "groups")
              raise ValidationError, "context fixed owner principal differs"
            end
            @selection_mutex.synchronize { @identity ||= JSON.parse(JSON.generate(observed)).freeze }
            @kernel.live!(@identity)
            unless @kernel.same?(@identity, observed) && @wire.socket_identity(@socket_path) == before
              raise ValidationError, "context owner incarnation differs"
            end
            InboxContextWire.write(socket, {"version" => 1, "context_id" => @context_id,
              "operation" => operation, "params" => params}, deadline: deadline)
            InboxContextWire.write_proof(socket, parts: proof, deadline: deadline) if proof
            if payload
              # Same bounded writer; a one-part raw ingress has the larger native payload bound.
              offset = 0
              while offset < payload.bytesize
                remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
                raise ValidationError, "context payload deadline expired" unless remaining.positive? && IO.select(nil, [socket], nil, remaining)
                sent = socket.write_nonblock(payload.byteslice(offset..), exception: false)
                next if sent == :wait_writable
                offset += sent
              end
            end
            socket.shutdown(Socket::SHUT_WR)
            result = InboxContextWire.read(socket, deadline: deadline)
            unless @kernel.same?(@identity, @kernel.peer(socket)) && @wire.socket_identity(@socket_path) == before
              raise ValidationError, "context owner incarnation changed"
            end
            unless result.is_a?(Hash) && result["version"].is_a?(Integer) && result["version"] == 1 &&
                result["context_id"] == @context_id && result.keys.sort == %w[context_id result version] && result["result"].is_a?(Hash)
              raise ValidationError, "context operation is blocked or unverifiable"
            end
            data = result.fetch("result")
            if %w[enqueue_context deliver_context status_context].include?(operation)
              InboxDirectResult.verify!(data, operation: operation, event_id: params.fetch("event_id"), attempt_id: params.fetch("attempt_id"), original: params.fetch("original"))
            end
            data
          end
        rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError
          raise ValidationError, "fixed context endpoint is unavailable"
        end
      end
    end
  end
end
