# frozen_string_literal: true

require "json"
require "digest"
require "websocket/driver"
require "ace/runtime/molecules/protected_socket"
require_relative "../errors"

module Ace
  module Herdr
    module Molecules
      # Framing on the socket already held/authenticated by CodexRuntimeSelection.
      # This owner opens no endpoint and exposes no generic caller RPC.
      class CodexAppServerTransport
        MESSAGE_LIMIT = 262_144
        TOTAL_LIMIT = 1_048_576
        HEADER_LIMIT = 16_384
        MESSAGE_COUNT = 128
        UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
        CLIENT_ID = /\Aace-[0-9a-f]{32}\z/
        class Unavailable < ExecutorError; end

        class Writer
          def initialize(socket, deadline)
            @socket, @deadline = socket, deadline
          end

          def url = "ws://localhost/rpc"

          def write(bytes)
            remaining = bytes.b
            until remaining.empty?
              wait = @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              unless wait.positive? && IO.select(nil, [@socket], nil, wait)
                raise Unavailable, "Codex transport deadline expired"
              end
              count = @socket.write_nonblock(remaining, exception: false)
              next if count == :wait_writable
              remaining = remaining.byteslice(count..)
            end
            bytes.bytesize
          end
        end

        def submit(socket:, thread:, client_id:, payload:, deadline:)
          @submission_started = false
          unless deadline.is_a?(Numeric) && deadline.finite? && thread.is_a?(String) && UUID.match?(thread) && client_id.is_a?(String) &&
              CLIENT_ID.match?(client_id) && payload.is_a?(String) && payload.encoding == Encoding::UTF_8 &&
              payload.valid_encoding? && payload.bytesize.between?(1, 65_536) && !payload.include?("\0")
            raise Unavailable, "Codex submission fields differ"
          end
          @socket, @deadline = socket, deadline
          @messages, @open, @error, @count, @total, @header = [], false, nil, 0, 0, 0
          @ingress = Ace::Runtime::Molecules::ProtectedSocket::Ingress.new(socket)
          @driver = WebSocket::Driver.client(Writer.new(socket, deadline), max_length: MESSAGE_LIMIT)
          @driver.on(:open) { @open = true }
          @driver.on(:error) { @error = "Codex WebSocket protocol is unavailable" }
          @driver.on(:close) { @error = "Codex WebSocket closed" }
          @driver.on(:message) { |event| receive_message!(event.data) }
          @driver.start
          pump! until @open
          request!(1, "initialize", {"clientInfo" => {"name" => "ace-herdr", "version" => "1"},
            "capabilities" => {"experimentalApi" => true}})
          response!(1)
          send_json!({"method" => "initialized"})
          # Conservatively crosses the boundary before the driver can write OR
          # buffer add. Every subsequent failure remains uncertain.
          @submission_started = true
          request!(2, "thread/queue/add", {"threadId" => thread, "clientUserMessageId" => client_id,
            "input" => [{"type" => "text", "text" => payload}]})
          result = response!(2)
          queued = result.fetch("queuedSubmission")
          unless result.keys == ["queuedSubmission"] && queued.is_a?(Hash) &&
              queued.keys.sort == %w[clientUserMessageId id input] && queued["clientUserMessageId"] == client_id &&
              queued["id"].is_a?(String) && UUID.match?(queued["id"]) && queued["input"].is_a?(Array) &&
              queued["input"].one?
            raise Unavailable, "Codex queue correlation differs"
          end
          text = queued.fetch("input").first
          unless text.is_a?(Hash) && (text.keys - %w[type text text_elements]).empty? &&
              text["type"] == "text" && text["text"] == payload &&
              (!text.key?("text_elements") || text["text_elements"] == [])
            raise Unavailable, "Codex queue payload differs"
          end
          {"accepted" => true, "queued_submission_id" => queued.fetch("id"),
            "client_user_message_id" => client_id, "payload_sha256" => Digest::SHA256.hexdigest(payload)}
        rescue Unavailable, Ace::Runtime::RuntimeUnavailableError, SecurityError, IOError, SystemCallError,
            JSON::ParserError, KeyError, TypeError
          {"accepted" => false, "pre_submit" => !@submission_started,
            "error" => @submission_started ? "Codex submission unconfirmed" : "Codex transport unavailable before submission"}
        ensure
          @driver = @socket = @ingress = @messages = nil
        end

        private

        def request!(id, method, params)
          send_json!({"id" => id, "method" => method, "params" => params})
        end

        def send_json!(value)
          check_deadline!
          raise Unavailable, @error if @error
          @driver.text(JSON.generate(value))
          raise Unavailable, @error if @error
        end

        def receive_message!(bytes)
          @count += 1
          unless bytes.is_a?(String) && bytes.encoding == Encoding::UTF_8 && bytes.valid_encoding? &&
              bytes.bytesize <= MESSAGE_LIMIT && @count <= MESSAGE_COUNT
            raise Unavailable, "Codex message bounds differ"
          end
          value = JSON.parse(bytes, create_additions: false, max_nesting: 32,
            allow_duplicate_key: false, allow_comments: false)
          raise Unavailable, "Codex message envelope differs" unless value.is_a?(Hash)
          @messages << value
        end

        def response!(id)
          loop do
            while (message = @messages.shift)
              # Native server requests never execute local actions.
              raise Unavailable, "Codex server request is unsupported" if message.key?("id") && message.key?("method")
              next unless message.key?("id")
              unless message["id"].is_a?(Integer) && message["id"] == id &&
                  message.keys.sort == %w[id result] && message["result"].is_a?(Hash)
                raise Unavailable, "Codex response correlation differs"
              end
              return message.fetch("result")
            end
            pump!
          end
        end

        def check_deadline!
          raise Unavailable, "Codex transport deadline expired" unless @deadline.is_a?(Numeric) &&
            @deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def pump!
          check_deadline!
          raise Unavailable, @error if @error
          remaining = @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise Unavailable, "Codex transport deadline expired" unless IO.select([@socket], nil, nil, remaining)
          bytes = @ingress.read_nonblock(2048, exception: false)
          return if bytes == :wait_readable
          raise Unavailable, "Codex transport disconnected" unless bytes
          @total += bytes.bytesize
          @header += bytes.bytesize unless @open
          raise Unavailable, "Codex transport byte budget exceeded" if @total > TOTAL_LIMIT || @header > HEADER_LIMIT
          @driver.parse(bytes)
          raise Unavailable, @error if @error
        end
      end
    end
  end
end
