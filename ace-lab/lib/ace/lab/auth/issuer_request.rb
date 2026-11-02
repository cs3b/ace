# frozen_string_literal: true

require "json"
require "time"
require "ace/lab"
require_relative "../auth"
require_relative "session_peer"
require_relative "session_lifetime"

module Ace
  module Lab
    module Auth
      # One socket-activated request. A successful response closes the client
      # socket immediately; the root issuer stays alive on the session-main
      # pidfd until that session ends or the lease expires. Its systemd
      # ExecStopPost owns cleanup, including a killed issuer process.
      class IssuerRequest
        MAX_REQUEST = 16_384
        FIELDS = %w[profile role task assignment repos ttl_minutes].freeze
        REQUIRED = %w[profile role task assignment repos].freeze
        PUBLIC_LEASE_FIELDS = %w[id profile role task assignment repos use_until provider_expiry state_detail].freeze

        def initialize(authenticate: ->(socket) { SessionPeer.new.authenticate(socket) },
          service_factory: ->(identity, invocation) { Service.new(session: identity, issuer_invocation: invocation) })
          @authenticate, @service_factory = authenticate, service_factory
        end

        def call(socket, invocation:)
          unless invocation.is_a?(String) && invocation.match?(/\A[0-9a-f]{32}\z/) && invocation != "0" * 32
            raise ArgumentError, "invalid issuer invocation"
          end
          identity = @authenticate.call(socket)
          request = read_request(socket)
          service = @service_factory.call(identity, invocation)
          service.store.with_issuer_lifecycle_lock(exclusive: false) do
            lease = service.request(
              profile_name: request.fetch("profile"), role: request.fetch("role"),
              task: request.fetch("task"), assignment: request.fetch("assignment"),
              repos: request.fetch("repos"), ttl_minutes: request["ttl_minutes"])
            deadline = Time.iso8601(lease.fetch("use_until"))
            remaining = deadline - Time.now.utc
            raise Error, "issued lease is already expired" unless remaining.positive?
            public_lease = lease.select { |key, _| PUBLIC_LEASE_FIELDS.include?(key) }
            socket.write(JSON.generate("ok" => true, "lease" => public_lease) + "\n")
            socket.close
            SessionLifetime.wait(identity.main_pidfd, timeout: remaining)
          end
        rescue Refusal => e
          refuse(socket, e.message)
        rescue Error, Ace::Runtime::Error, ArgumentError, KeyError, JSON::ParserError, SystemCallError, IOError
          refuse(socket, "issuer request could not be completed")
        ensure
          socket.close unless socket.closed?
          identity&.close
        end

        private

        def read_request(socket)
          bytes = +""
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise ArgumentError, "request deadline exceeded" unless remaining.positive? && IO.select([socket], nil, nil, remaining)
            bytes << socket.readpartial(4096)
            raise ArgumentError, "request too large" if bytes.bytesize > MAX_REQUEST
            next unless (newline = bytes.index("\n"))
            raise ArgumentError, "multiple requests are not allowed" unless newline == bytes.bytesize - 1
            break
          end
          value = JSON.parse(bytes, create_additions: false, allow_duplicate_key: false, max_nesting: 5)
          unless value.is_a?(Hash) && (value.keys - FIELDS).empty? && (REQUIRED - value.keys).empty? &&
              %w[profile role task assignment].all? { |key| safe_string?(value[key]) } &&
              value["repos"].is_a?(Array) && value["repos"].size.between?(1, 64) && value["repos"].all? { |repo| safe_string?(repo) } &&
              (!value.key?("ttl_minutes") || value["ttl_minutes"].is_a?(Integer) && value["ttl_minutes"].positive?)
            raise ArgumentError, "invalid issuer request"
          end
          value
        rescue EOFError
          raise ArgumentError, "incomplete issuer request"
        end

        def safe_string?(value)
          value.is_a?(String) && value.bytesize.between?(1, 512) && value.valid_encoding? && !value.match?(/[[:cntrl:]]/)
        end

        def refuse(socket, reason)
          socket.write(JSON.generate("ok" => false, "error" => reason) + "\n") unless socket.closed?
          :refused
        rescue SystemCallError, IOError
          :refused
        end
      end
    end
  end
end
