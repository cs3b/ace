# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The connection-serving half of a lifecycle boundary (spec
      # 8wq.t.34i, reused by the TLS/TCP crossing of spec 8xa.t.nh0):
      # one bounded request frame per dispatch, classified errors cross
      # the wire, idleness and frame size stay bounded. The includer
      # supplies `@idle_seconds`, `@logger` and `store_for(connection)`.
      module FrameServing
        def serve_connection(socket)
          peer = authenticate!(socket)
          store = store_for(peer)
          loop do
            line = read_frame(socket)
            break if line.nil?

            response = dispatch(store, line)
            write_frame(socket, response)
          end
        rescue Lifecycle::Error => e
          write_frame(socket, Protocol.encode_error(e)) rescue nil
        rescue SystemCallError, IOError
          nil
        ensure
          socket.close rescue nil
        end

        private

        # One request frame per dispatch; lifecycle failures return
        # classified error frames, transport/frame failures close the
        # connection (serve_connection's rescues).
        def dispatch(store, line)
          request = Protocol.decode_request(line)
          result = execute(store, request[:op], request[:params])
          Protocol.encode_result(result)
        rescue Protocol::FrameError, Lifecycle::Error, ArgumentError, TypeError => e
          Protocol.encode_error(e)
        end

        def execute(store, op, params)
          case op
          when "ping" then {"pong" => true}
          when "proposal-create" then store.proposal_create(**symbolize(params))
          when "proposal-show" then store.proposal_show(required(params, "id"), project: required(params, "project"), history_after: params.fetch("history_after", 0))
          when "proposal-revise" then store.proposal_revise(required(params, "id"), project: required(params, "project"), expected_revision: required(params, "expected_revision"),
            operation_id: required(params, "operation_id"), document: required(params, "document"))
          when "proposal-ack"
            store.proposal_acknowledge(required(params, "id"), project: required(params, "project"), submitted_at: required(params, "submitted_at"))
          when "proposal-reply"
            store.proposal_reply(required(params, "id"), project: required(params, "project"), answer: required(params, "answer"),
              received_at: required(params, "received_at"), sequence: required(params, "sequence"))
          when "proposal-reconcile"
            store.proposal_reconcile(required(params, "id"), project: required(params, "project"), checkpoint: required(params, "checkpoint"))
          when "proposal-wake" then store.proposal_wake(project: required(params, "project"), after: params["after"])
          when "proposal-due" then store.proposal_due(project: required(params, "project"), after: params["after"])
          when "proposal-history" then store.proposal_history(project: required(params, "project"),
            query: params.fetch("query", ""), after: params["after"])
          when "create" then store.create(**symbolize(params))
          when "read" then store.read(required(params, "id"))
          when "deliver" then store.deliver(required(params, "id"), answer_reader(params))
          when "consume"
            store.consume(required(params, "id"), timeout: Integer(params["timeout"] || 0),
              operation: params["operation"], native_delivery: params.fetch("native_delivery", false))
          when "cancel" then store.cancel(required(params, "id"), reason: params["reason"].to_s)
          when "pending" then store.pending_page(project: params["project"], after: params["after"])
          when "states" then store.states
          end
        end

        def symbolize(params)
          params.transform_keys { |key| key.to_sym }
        end

        def required(params, key)
          value = params[key]
          raise Protocol::FrameError, "boundary parameter '#{key}' is required" if value.nil? || value.to_s.empty?

          value
        end

        def answer_reader(params)
          answer = params["answer"].to_s
          ->(limit) { answer[0, limit] }
        end

        def read_frame(socket)
          data = +""
          loop do
            ready = IO.select([socket], nil, nil, @idle_seconds)
            return nil unless ready

            chunk = socket.read_nonblock(4096, exception: false)
            return nil if chunk.nil?
            next sleep(0.01) if chunk == :wait_readable

            data << chunk
            if data.bytesize > Protocol::MAX_FRAME_BYTES
              write_frame(socket, Protocol.encode_error(Protocol::FrameError.new("request frame is too large"))) rescue nil
              return nil
            end
            return data if data.include?("\n")
          end
        end

        def write_frame(socket, frame)
          socket.write(frame)
          socket.flush
        end

        def log(message)
          @logger&.call("[ace-hitl] #{message}")
        end
      end
    end
  end
end
