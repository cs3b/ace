# frozen_string_literal: true

module Ace
  module Lab
    module Models
      # Immutable classified result of a topology query (spec 8wq.t.1w4).
      # Either ok with public data, or a classified error with one of the
      # ERROR_CODES. Serialized as the deterministic JSON envelope:
      #   {"status":"ok","data":{...}}
      #   {"status":"error","error":{"code":...,"message":...,...}}
      class QueryResult
        ERROR_CODES = %w[missing ambiguous stale unauthorized invalid_configuration].freeze

        attr_reader :data, :error_code, :message, :context

        def initialize(data: nil, error_code: nil, message: nil, context: {})
          if error_code.nil? && message.nil?
            @data = data
          else
            unless ERROR_CODES.include?(error_code)
              raise ArgumentError, "unknown error code: #{error_code.inspect}"
            end

            @error_code = error_code
            @message = message
            @context = context.dup.freeze
          end
          freeze
        end

        def self.ok(data)
          new(data: data)
        end

        def self.failure(code, message, **context)
          new(error_code: code, message: message, context: context)
        end

        def ok?
          (!error_code.nil?) ? false : true
        end

        def envelope
          if ok?
            {"status" => "ok", "data" => data}
          else
            error = {"code" => error_code, "message" => message}
            error.merge!(context.select { |_k, v| !v.nil? })
            {"status" => "error", "error" => error}
          end
        end
      end
    end
  end
end
