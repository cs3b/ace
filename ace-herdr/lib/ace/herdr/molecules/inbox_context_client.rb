# frozen_string_literal: true

require "ace/runtime/molecules/protected_linux"
require_relative "inbox_context_wire"

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

        def request(operation, params, proof: nil)
          if %w[reconcile_context verify_context_reconciliation].include?(operation)
            unless proof.is_a?(Array) && proof.size == 2 && proof.all? { |part| part.is_a?(String) && part.bytesize.between?(1, InboxContextWire::LIMIT) }
              raise ValidationError, "context proof parts differ"
            end
            params = params.merge("proof_sizes" => proof.map(&:bytesize))
          elsif proof
            raise ValidationError, "context operation does not accept proof bytes"
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
            socket.shutdown(Socket::SHUT_WR)
            result = InboxContextWire.read(socket, deadline: deadline)
            unless @kernel.same?(@identity, @kernel.peer(socket)) && @wire.socket_identity(@socket_path) == before
              raise ValidationError, "context owner incarnation changed"
            end
            unless result.is_a?(Hash) && result["version"].is_a?(Integer) && result["version"] == 1 &&
                result["context_id"] == @context_id && result.keys.sort == %w[context_id result version] && result["result"].is_a?(Hash)
              raise ValidationError, "context operation is blocked or unverifiable"
            end
            result.fetch("result")
          end
        rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError
          raise ValidationError, "fixed context endpoint is unavailable"
        end
      end
    end
  end
end
