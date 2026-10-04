# frozen_string_literal: true

require "securerandom"

module Ace
  module Hitl
    module Lifecycle
      # Where OTP answer bytes live between delivery and consumption
      # (spec 8wq.t.34i). The vault is a seam with exactly two shapes:
      #
      # - FileVault (library/test default): the pre-boundary behavior —
      #   one 0600 file inside the service-owned secrets directory. Never
      #   exposed to another identity; the boundary mediates every read.
      # - MemoryVault (service): bounded, TTL-bound, ONE-TIME read from
      #   process memory. Secret bytes are persisted nowhere; a service
      #   restart or expiry deliberately loses the OTP and the requester
      #   is prompted again. No persisted verifier exists for a six-digit
      #   challenge — a stored hash would be brute-forceable offline.
      module OtpVault
        MAX_ENTRIES = 256
        DEFAULT_TTL_SECONDS = 15 * 60

        # Raised by the store when an operation needs the vault and it
        # cannot serve the secret (absent, expired, or already consumed).
        class MissError < Lifecycle::StateError; end

        module FileVault
          module_function

          # Persist via the store's atomic writer mechanics; the store
          # owns paths and modes, the vault only handles bytes.
          def write(store, value, answer)
            path = store.answer_path(value)
            temporary = path.parent.join(".#{store.safe_id(value["id"])}.#{$PROCESS_ID}.#{SecureRandom.hex(4)}")
            flags = File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW
            fd = IO.sysopen(temporary, flags, Store::ANSWER_MODE)
            begin
              io = IO.for_fd(fd, mode: "w")
              io.write(answer)
              io.flush
              io.fsync
              io.close
            rescue
              begin
                temporary.unlink
              rescue
                nil
              end
              raise
            end
            File.rename(temporary, path)
          ensure
            temporary.unlink if temporary&.exist?
          end

          def read(store, value)
            path = store.answer_path(value)
            return nil unless path.exist?

            answer = path.read
            Kinds.check_answer!(value["kind"].to_s, answer)
            answer
          end

          def discard(store, value)
            path = store.answer_path(value)
            path.unlink if path.exist?
            nil
          end
        end

        # Process-memory vault: keyed by request id + incarnation so a
        # cancelled-and-recreated id can never read a predecessor's
        # secret. Reads are destructive; entries expire; the bounded
        # entry count evicts the oldest challenge under pressure.
        class MemoryVault
          Entry = Struct.new(:answer, :expires_at)

          def initialize(ttl_seconds: DEFAULT_TTL_SECONDS, max_entries: MAX_ENTRIES, clock: Time)
            @ttl_seconds = ttl_seconds
            @max_entries = max_entries
            @clock = clock
            @entries = {}
          end

          def write(_store, value, answer)
            key = key_for(value)
            @entries.shift while @entries.length >= @max_entries
            @entries[key] = Entry.new(answer.dup.freeze, @clock.now.to_i + @ttl_seconds)
            nil
          end

          # One-time read: the bytes leave memory exactly once, and only
          # for the request incarnation that delivered them.
          def read(store, value)
            entry = @entries[key_for(value)]
            raise MissError, "no OTP is pending for this request" unless entry
            raise MissError, "the OTP challenge has expired; request a new one" if entry.expires_at <= @clock.now.to_i

            @entries.delete(key_for(value))
            entry.answer.dup
          end

          # Non-destructive presence probe for the duplicate-delivery
          # check; expired entries do not count.
          def peek_present(store, value)
            entry = @entries[key_for(value)]
            !entry.nil? && entry.expires_at > @clock.now.to_i
          end

          def discard(store, value)
            @entries.delete(key_for(value))
            nil
          end

          private

          def key_for(value)
            "#{value["id"]}:#{value["incarnation"]}"
          end
        end
      end
    end
  end
end
