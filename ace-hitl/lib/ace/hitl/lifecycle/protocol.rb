# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module Lifecycle
      # The bounded, versioned wire protocol of the scoped store boundary
      # (spec 8wq.t.34i): one newline-delimited JSON request frame, one
      # newline-delimited JSON response frame. Failures are classified
      # (Permission/Binding/State/Answer/Transport), never silent: every
      # response names its error class so callers can retry or recover.
      module Protocol
        VERSION = 1
        MAX_FRAME_BYTES = 64 * 1024
        DEFAULT_DEADLINE_SECONDS = 10.0
        OPERATIONS = %w[create read deliver consume cancel pending states ping
          proposal-create proposal-show proposal-revise proposal-ack proposal-reply proposal-reconcile proposal-due proposal-history].freeze

        # Wire failures map to the transport error; classified lifecycle
        # failures pass through under their own names.
        class FrameError < Lifecycle::TransportError; end

        module_function

        def encode_request(op, params = {})
          frame = {"v" => VERSION, "op" => op.to_s, "params" => params}
          line = JSON.generate(frame)
          raise FrameError, "request frame exceeds #{MAX_FRAME_BYTES} bytes" if line.bytesize + 1 > MAX_FRAME_BYTES

          line << "\n"
        end

        # @return [Hash] {op:, params:} for a valid request line
        def decode_request(line)
          frame = parse_frame(line)
          op = frame["op"].to_s
          unless OPERATIONS.include?(op)
            raise FrameError, "unknown boundary operation: #{op.empty? ? "(missing)" : op}"
          end
          params = frame["params"]
          unless params.nil? || params.is_a?(Hash)
            raise FrameError, "boundary parameters must be a mapping"
          end

          {op: op, params: params || {}}
        end

        def encode_result(result)
          frame_line({"ok" => true, "result" => result})
        end

        def encode_error(exception)
          frame_line({"ok" => false,
                      "error" => {"class" => exception.class.name.split("::").last,
                                  "message" => exception.message}})
        end

        # @return [Hash] result hash
        # @raise [Lifecycle::Error] the classified error carried by the frame
        def decode_response(line)
          frame = parse_frame(line)
          return frame["result"] if frame["ok"] == true

          error = frame["error"]
          unless error.is_a?(Hash) && error["message"].is_a?(String)
            raise FrameError, "malformed boundary error frame"
          end
          raise error_class(error["class"].to_s), error["message"]
        end

        def error_class(name)
          known = {
            "BindingError" => Lifecycle::BindingError,
            "EndedAttemptError" => Lifecycle::EndedAttemptError,
            "PermissionError" => Lifecycle::PermissionError,
            "StateError" => Lifecycle::StateError,
            "AnswerError" => Lifecycle::AnswerError,
            "TransportError" => Lifecycle::TransportError,
            "FrameError" => FrameError,
            "MissError" => OtpVault::MissError,
            "ExpiredError" => OtpVault::ExpiredError,
            "DeclarationError" => Effects::DeclarationError
          }
          known.fetch(name, Lifecycle::TransportError)
        end

        def frame_line(frame)
          line = JSON.generate(frame)
          raise FrameError, "response frame exceeds #{MAX_FRAME_BYTES} bytes" if line.bytesize + 1 > MAX_FRAME_BYTES

          line << "\n"
        end

        def parse_frame(line)
          unless line && line.bytesize <= MAX_FRAME_BYTES
            raise FrameError, "boundary frame is missing or too large"
          end

          frame = JSON.parse(line)
          raise FrameError, "boundary frame must be a mapping" unless frame.is_a?(Hash)

          frame
        rescue JSON::ParserError
          raise FrameError, "boundary frame is not valid JSON"
        end
      end
    end
  end
end
