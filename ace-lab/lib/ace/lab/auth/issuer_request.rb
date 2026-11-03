# frozen_string_literal: true

require "json"
require "time"
require "ace/runtime/molecules/protected_socket"
require "ace/lab"
require_relative "../auth"
require_relative "session_peer"
require_relative "session_lifetime"

module Ace
  module Lab
    module Auth
      # One authenticated connection within the singleton issuer invocation.
      # The handler supervises its lease after replying. Failed supervision
      # stops the issuer so ExecStopPost can recover all outstanding leases.
      class IssuerRequest
        MAX_REQUEST = 16_384
        FIELDS = %w[action profile role task assignment repos ttl_minutes].freeze
        REQUIRED = %w[action profile role task assignment repos].freeze
        PUBLIC_LEASE_FIELDS = %w[id profile role task assignment repos use_until provider_expiry state_detail].freeze

        def initialize(authenticate: ->(socket) { SessionPeer.new.authenticate(socket) },
          service_factory: ->(identity, invocation) { Service.new(session: identity, issuer_invocation: invocation) })
          @authenticate, @service_factory = authenticate, service_factory
        end

        def call(socket, invocation:, allow_request: true, supervising: nil)
          lease = nil
          unless invocation.is_a?(String) && invocation.match?(/\A[0-9a-f]{32}\z/) && invocation != "0" * 32
            raise ArgumentError, "invalid issuer invocation"
          end
          identity = @authenticate.call(socket)
          request = read_request(socket)
          if request["action"] == "request" && !allow_request
            raise Refusal, "issuer lease supervision capacity is exhausted"
          end
          service = @service_factory.call(identity, invocation)
          service.store.with_issuer_lifecycle_lock(exclusive: false) do
            unless request.fetch("action") == "request"
              result = case request.fetch("action")
              when "status"
                service.status(lease_id: request["lease"])
              when "revoke"
                cleanup = service.revoke(lease_id: request.fetch("lease"))
                {"lease" => request.fetch("lease"), "cleanup" => cleanup.to_s}
              when "exec"
                with_stdio(socket) { service.exec(lease_id: request.fetch("lease"), argv: request.fetch("argv")) }
              end
              reply(socket, "ok" => true, "result" => result)
              return :completed
            end
            lease = service.request(
              profile_name: request.fetch("profile"), role: request.fetch("role"),
              task: request.fetch("task"), assignment: request.fetch("assignment"),
              repos: request.fetch("repos"), ttl_minutes: request["ttl_minutes"])
            begin
              deadline = Time.iso8601(lease.fetch("use_until"))
              remaining = deadline - Time.now.utc
              raise Error, "issued lease is already expired" unless remaining.positive?
              supervising&.call
              public_lease = lease.select { |key, _| PUBLIC_LEASE_FIELDS.include?(key) }
              reply(socket, "ok" => true, "result" => public_lease)
              socket.close
              supervise(service, identity, lease.fetch("id"), remaining)
            ensure
              outcome = service.revoke(lease_id: lease.fetch("id"))
              unless %i[revoked already_invalid cleared not-issued].include?(outcome)
                raise Error, "lease revocation was not confirmed"
              end
            end
          end
        rescue Refusal => e
          refuse(socket, e.message)
          lease ? :cleanup_failed : :refused
        rescue Error, Ace::Runtime::Error, ArgumentError, KeyError, JSON::ParserError, SystemCallError, IOError
          refuse(socket, "issuer request could not be completed")
          lease ? :cleanup_failed : :refused
        ensure
          socket.close unless socket.closed?
          identity&.close
        end

        private

        # Passed descriptors are only used as stdio for a command that the
        # session runner drops to the authenticated UID before executing.
        # Handlers are forked, so reopening stdio cannot affect another peer.
        def with_stdio(socket)
          received = []
          saved = []
          reply(socket, "stdio" => true)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
          3.times do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise Error, "command descriptors unavailable" unless remaining.positive? && IO.select([socket], nil, nil, remaining)
            packet = socket.recvmsg_nonblock(1, 0, 4096, scm_rights: true, exception: false)
            redo if packet == :wait_readable
            bytes, _, flags, *controls = packet
            rights = controls.flat_map do |control|
              control.cmsg_is?(Socket::SOL_SOCKET, Socket::SCM_RIGHTS) ? control.unix_rights.to_a : []
            end
            unless bytes == "\0" && (flags & Socket::MSG_CTRUNC).zero? && controls.size == 1 && rights.size == 1
              rights.each(&:close)
              raise Error, "invalid command descriptor"
            end
            received << rights.first
          end
          [STDIN, STDOUT, STDERR].each_with_index do |io, index|
            saved << io.dup
            io.reopen(received.fetch(index))
          end
          yield
        ensure
          saved&.each_with_index { |io, index| [STDIN, STDOUT, STDERR][index].reopen(io) }
          (received.to_a + saved.to_a).each(&:close)
        end

        def supervise(service, identity, id, remaining)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + remaining
          loop do
            record = service.status(lease_id: id)
            if record["state"] == "revoked" && !record.key?("execution")
              return :consumed
            end
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            return :expired unless remaining.positive?
            outcome = SessionLifetime.wait(identity.main_pidfd, timeout: [remaining, 1].min)
            return outcome if outcome == :session_ended
          end
        end

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
          raise ArgumentError, "invalid issuer request" unless value.is_a?(Hash)
          if value["action"] != "request"
            fields = {"status" => %w[action lease], "revoke" => %w[action lease], "exec" => %w[action lease argv]}[value["action"]]
            valid = fields && (value.keys - fields).empty? &&
              (value["action"] == "status" && !value.key?("lease") || safe_string?(value["lease"]))
            if value["action"] == "exec"
              valid &&= value["argv"].is_a?(Array) && value["argv"].size.between?(1, 128) &&
                value["argv"].all? { |arg| arg.is_a?(String) && arg.bytesize <= 8192 && !arg.include?("\0") } &&
                !value["argv"].first.empty?
            end
            raise ArgumentError, "invalid issuer request" unless valid
            return value
          end
          unless (value.keys - FIELDS).empty? && (REQUIRED - value.keys).empty? &&
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

        def reply(socket, value)
          transport = Ace::Runtime::Molecules::ProtectedSocket
          transport.write(socket, value, deadline: transport.deadline, limit: transport::LIMIT)
        end

        def refuse(socket, reason)
          reply(socket, "ok" => false, "error" => reason) unless socket.closed?
          :refused
        rescue SystemCallError, IOError, Ace::Runtime::Error
          :refused
        end
      end
    end
  end
end
