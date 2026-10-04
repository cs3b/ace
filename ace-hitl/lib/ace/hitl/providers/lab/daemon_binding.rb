# frozen_string_literal: true

require "socket"
require "json"
require_relative "../errors"
require_relative "../../lifecycle/errors"

module Ace
  module Hitl
    module Providers
      class Lab
        # The provider=lab binding policy (spec 8wm.t.y21 §1): the
        # minimal client of the lab daemon's read-only `hitl_binding`
        # socket op. The W647 authority and its record semantics stay
        # lab-side; this client consumes the daemon's narrow projection
        # and fails closed on every doubt. Confined here by the A1 §8
        # guard — the generic lifecycle never sees this class.
        class DaemonBinding < Lifecycle::Binding
          LIVE_ATTEMPT_STATES = %w[reserved starting working].freeze
          DAEMON_ATTEMPT_OWNER = "labd"
          MAX_REPLY_BYTES = 64 * 1024
          TIMEOUT_SECONDS = 10.0

          WORK_ID = /\AW[0-9]+\z/
          ATTEMPT_ID = /\AA-[0-9a-f]{24}\z/

          def initialize(socket_path: nil, identity: Lifecycle::Identity)
            @socket_path = socket_path || ENV["ACE_HITL_LABD_SOCKET"] || "/run/lab/labd.sock"
            @identity = identity
          end

          def validate_request(work: nil, assignment: nil, attempt:, project:, requester:)
            raise Lifecycle::BindingError, "the Work binding does not accept managed assignments" if assignment

            work_value, record = query(work, attempt)
            unless work_value["id"] == work && work_value["project"] == project &&
                work_value["active_attempt"] == attempt
              raise Lifecycle::BindingError, "HITL request is not bound to the exact active Work Attempt"
            end
            validate_record(work, attempt, project, requester, record, work_value)
          end

          def require_active(work: nil, assignment: nil, attempt:, project: nil, requester: nil)
            raise Lifecycle::BindingError, "the Work binding does not accept managed assignments" if assignment

            _work_value, record = query(work, attempt)
            unless record["work"] == work && record["id"] == attempt
              raise Lifecycle::EndedAttemptError, "HITL Attempt cannot be verified against its Work"
            end
            unless LIVE_ATTEMPT_STATES.include?(record["state"].to_s)
              raise Lifecycle::EndedAttemptError, "HITL Attempt is no longer active"
            end
            nil
          end

          private

          def validate_record(work, attempt, project, requester, record, work_value)
            daemon_owned = record["owner"].to_s == DAEMON_ATTEMPT_OWNER
            unless record["id"] == attempt && record["work"] == work &&
                ["", project].include?(record["project"].to_s) &&
                LIVE_ATTEMPT_STATES.include?(record["state"].to_s) &&
                record["unix_user"].to_s == requester
              raise Lifecycle::BindingError,
                "HITL request is not owned by one exact live Attempt of the requesting user"
            end
            if daemon_owned
              unless daemon_binding_valid?(record)
                raise Lifecycle::BindingError,
                  "daemon-owned HITL Attempt is missing its ownership and process identity"
              end
              return
            end
            unless interactive_binding_valid?(record, work_value)
              raise Lifecycle::BindingError, "HITL Attempt is missing its pane/terminal binding evidence"
            end
          end

          # A daemon-owned deterministic Attempt is attributable through
          # labd's ownership marker plus its execution/process identity.
          def daemon_binding_valid?(record)
            process = record["process"].is_a?(Hash) ? record["process"] : {}
            record["owner"].to_s == DAEMON_ATTEMPT_OWNER &&
              record["execution"].to_s == "host" &&
              !process["kind"].to_s.empty? &&
              !process["boot_id"].to_s.empty?
          end

          # An interactive agent Attempt keeps its pane/terminal binding
          # evidence; a dispatched assignment also keeps the historical
          # pane/session/start evidence and must agree with the
          # control-store binding.
          def interactive_binding_valid?(record, work_value)
            assignment = work_assignment_for_attempt(work_value, record["id"].to_s)
            return false unless assignment.is_a?(Hash)

            agent = assignment["agent"]
            return false unless agent.is_a?(String) && !agent.empty?

            herdr = record["herdr"].is_a?(Hash) ? record["herdr"] : {}
            return false unless %w[session pane_id terminal_id].all? do |key|
              herdr[key].is_a?(String) && !herdr[key].empty?
            end

            pane_id = assignment["pane_id"]
            return true if pane_id.nil?

            session = assignment["herdr_session"]
            unless pane_id.is_a?(String) && !pane_id.empty? &&
                session.is_a?(String) && !session.empty? &&
                assignment["started_at"]
              return false
            end

            herdr["pane_id"] == pane_id && herdr["session"] == session
          end

          def work_assignment_for_attempt(work_value, attempt)
            dispatch_id = attempt.delete_prefix("A-")
            %w[assignment review_assignment].filter_map do |key|
              candidate = work_value[key]
              if candidate.is_a?(Hash) && candidate["dispatch_id"].to_s == dispatch_id
                candidate
              end
            end.first
          end

          # One exact newline-JSON query over the daemon socket; any
          # unavailability, malformed reply, or daemon-side failure maps
          # to the binding error (fail closed).
          def query(work, attempt)
            unless WORK_ID.match?(work.to_s) && ATTEMPT_ID.match?(attempt.to_s)
              raise Lifecycle::BindingError, "HITL request requires a valid active Work"
            end
            reply = read_reply(work, attempt)
            result = reply["result"].is_a?(Hash) ? reply["result"] : nil
            work_value = result&.fetch("work", nil)
            record = result&.fetch("attempt", nil)
            unless work_value.is_a?(Hash) && record.is_a?(Hash)
              raise Lifecycle::BindingError, "HITL Attempt records are unavailable"
            end

            [work_value, record]
          end

          def read_reply(work, attempt)
            query = JSON.generate({op: "hitl_binding", work: work, attempt: attempt}) + "\n"
            line = nil
            UNIXSocket.open(@socket_path) do |socket|
              socket.write(query)
              line = read_line(socket)
            end
          rescue JSON::GeneratorError, SystemCallError, IOError => e
            raise Lifecycle::BindingError, "HITL Attempt records are unavailable (#{e.class})"
          else
            if line.nil? || line.bytesize > MAX_REPLY_BYTES
              raise Lifecycle::BindingError, "HITL Attempt records are unavailable"
            end
            line, extra = line.split("\n", 2)
            raise Lifecycle::BindingError, "HITL Attempt records are unavailable" unless line
            unless extra.to_s.empty?
              raise Lifecycle::BindingError, "HITL Attempt records are unavailable"
            end

            begin
              reply = JSON.parse(line)
            rescue JSON::ParserError
              # A non-JSON reply is daemon unavailability, never a raw
              # parse error escaping to the caller (review F3 on W696):
              # it fails closed exactly like a short reply, so the ask
              # path surfaces the orphan event and deliver cancels
              # liveness instead of crashing.
              raise Lifecycle::BindingError, "HITL Attempt records are unavailable"
            end
            raise Lifecycle::BindingError, "HITL Attempt records are unavailable" unless reply.is_a?(Hash)
            if reply["ok"] != true
              error = reply["error"].to_s.strip
              raise Lifecycle::BindingError, error.empty? ? "HITL Attempt records are unavailable" : error
            end

            reply
          end

          # Newline-framed read with a bounded deadline; oversized replies
          # fail closed.
          def read_line(socket)
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TIMEOUT_SECONDS
            data = +""
            loop do
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise Lifecycle::BindingError, "HITL Attempt records are unavailable" if remaining <= 0
              ready = IO.select([socket], nil, nil, remaining)
              raise Lifecycle::BindingError, "HITL Attempt records are unavailable" unless ready

              chunk = socket.read_nonblock(4096, exception: false)
              next if chunk == :wait_readable
              return data if chunk.nil? # EOF: a final line without a newline is valid

              data << chunk
              if data.bytesize > MAX_REPLY_BYTES
                raise Lifecycle::BindingError, "hitl binding reply is too large"
              end
              return data if data.include?("\n")
            end
          end
        end
      end
    end
  end
end
