# frozen_string_literal: true

require "ace/runtime/molecules/protected_linux"
require_relative "inbox_context_wire"

module Ace
  module Herdr
    module Molecules
      # Constructor inputs come only from the verified installed context map.
      class InboxContextClient
        def initialize(context_id:, socket_path:, owner_identity:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new,
          wire: Ace::Runtime::Molecules::ProtectedSocket)
          @context_id, @socket_path, @identity, @kernel, @wire = context_id, socket_path, owner_identity, kernel, wire
        end

        def request(operation, params)
          @wire.root_path!(File.dirname(@socket_path), directory: true, owner: @identity.fetch("uid"))
          before = @wire.socket_identity(@socket_path)
          raise ValidationError, "context socket owner differs" unless before[2] == @identity.fetch("uid")
          @kernel.live!(@identity)
          deadline = InboxContextWire.deadline
          @wire.connect(@socket_path, deadline: deadline) do |socket|
            unless @kernel.same?(@identity, @kernel.peer(socket)) && @wire.socket_identity(@socket_path) == before
              raise ValidationError, "context owner incarnation differs"
            end
            InboxContextWire.write(socket, {"version" => 1, "context_id" => @context_id,
              "operation" => operation, "params" => params}, deadline: deadline)
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
