# frozen_string_literal: true

require "securerandom"
require "json"
require "fileutils"
require "digest"
require "time"

module Ace
  module Lab
    module Auth
      # The ONE owner of the minimal lease record (task 8xs.t.pu0.7):
      # one JSON file per lease under the trusted leases dir (default
      # /var/lib/lab/ace-lab/auth/leases), private to the issuer. The
      # record carries the correlation (task/assignment/profile/role/
      # principal), the provider TOKEN REFERENCE (never the secret
      # value), the deadlines and the cleanup outcome — never task
      # progress, queues, or another tool's state.
      #
      # Lifecycle: a record is born PREPARING (issue in flight — a hard
      # process death in that window leaves a recoverable record, never
      # a phantom "live" grant); it becomes ISSUED only after a
      # complete, usable credential handoff; an unresolved remote
      # outcome (lost response, lost revoke) is REVOKE-PENDING until
      # reconciled; REVOKED is terminal. Every write is atomic
      # (temporary file + fsync + rename) under a STABLE sidecar write
      # lock — a crash mid-write can never truncate or half-replace a
      # record, and an unparseable record surfaces as a visible CORRUPT
      # marker instead of silently vanishing from the inventory.
      class LeaseStore
        STATES = %w[preparing issued revoke-pending revoked].freeze

        attr_reader :dir

        def initialize(dir)
          @dir = dir
        end

        # @param id [String, nil] caller-generated lease id (so the
        #   provider's deterministic token_ref can be computed from it
        #   and written in the SAME atomic creation write)
        # @param token_ref [String, nil] the provider's DETERMINISTIC
        #   remote identity for this lease, written at creation so an
        #   interrupted issue can still be reconciled against the
        #   remote side (the response may never have arrived).
        # @return [Hash] the created (PREPARING) lease record
        def create(profile:, role:, principal:, task:, assignment:, repos:,
          use_until:, provider_expiry:, token_ref: nil, id: nil)
          lease = {"id" => id || "lease-#{SecureRandom.hex(8)}",
                   "profile" => profile, "role" => role, "principal" => principal,
                   "task" => task, "assignment" => assignment, "repos" => repos.sort,
                   "state" => "preparing", "requested_at" => now,
                   "use_until" => use_until, "provider_expiry" => provider_expiry,
                   "token_ref" => token_ref, "cleanup" => nil}
          write(lease)
          lease
        end

        # Idempotency: the LIVE lease for the same task/assignment/
        # profile/role correlation, if any. Only an ISSUED record is
        # live: preparing (issue in flight or dead mid-issue) and
        # revoke-pending (unresolved remote outcome) records are never
        # returned — recovery settles them instead. A finished or
        # scope-changed correlation does not match, and
        # DEADLINE-AWARENESS is part of the match: an issued record
        # past its use_until/provider expiry is not returned, so a
        # retry mints a fresh grant while reconcile retires the expired
        # one — an expired grant is never handed back as "live".
        def find_live(task:, assignment:, profile:, role:)
          all.filter_map do |lease|
            next unless lease["task"] == task && lease["assignment"] == assignment &&
              lease["profile"] == profile && lease["role"] == role &&
              lease["state"] == "issued"
            lease if live?(lease)
          end.min_by { |lease| lease["requested_at"].to_s }
        end

        def load(id)
          path = lease_path(id)
          raise Error, "unknown lease '#{id}'" unless File.file?(path)

          JSON.parse(File.read(path))
        rescue JSON::ParserError
          raise Error, "lease record '#{id}' is unreadable"
        end

        # The full inventory, including CORRUPT records as explicit
        # markers: a record that cannot be parsed is a visible recovery
        # problem (the remote token may still be live) — never a
        # silently skipped entry that disappears from reconcile.
        def all
          return [] unless Dir.exist?(@dir)

          Dir.glob(File.join(@dir, "*.json")).sort.filter_map do |path|
            JSON.parse(File.read(path))
          rescue Errno::EACCES
            nil
          rescue JSON::ParserError
            {"id" => File.basename(path, ".json"), "state" => nil,
             "corrupt" => true, "_path" => path}
          end
        end

        # Atomic update under a STABLE sidecar write lock: the record is
        # read, modified and replaced via temporary-file + fsync +
        # rename. A crash at any point leaves either the old or the new
        # complete record — never a truncated file — and the lock
        # survives the replacement (it is not held on the record inode).
        def update(id)
          path = lease_path(id)
          with_write_lock(id) do
            lease = JSON.parse(File.read(path))
            yield(lease)
            atomic_write(path, lease)
            lease
          end
        end

        def write(lease)
          atomic_write(lease_path(lease["id"]), lease)
          lease
        end

        def with_write_lock(id)
          FileUtils.mkdir_p(@dir)
          File.open(File.join(@dir, "#{id}.write.lock"), File::CREAT | File::RDWR) do |lock|
            lock.flock(File::LOCK_EX)
            yield
          end
        end

        # One request flow at a time per correlation (task/assignment/
        # profile/role): a BLOCKING exclusive lock on the correlation's
        # lockfile so the find_live + create + issue sequence is atomic
        # against a concurrent identical request — the second caller
        # waits and then returns the first caller's live lease.
        def with_correlation_lock(task:, assignment:, profile:, role:)
          FileUtils.mkdir_p(@dir)
          key = Digest::SHA256.hexdigest([task, assignment, profile, role].join("\e"))
          File.open(File.join(@dir, "correlation-#{key}.lock"), File::CREAT | File::RDWR) do |lock|
            lock.flock(File::LOCK_EX)
            yield
          end
        end

        # One exec at a time per lease: an exclusive lock on the lease's
        # exec lockfile, non-blocking — a parallel exec is a refusal.
        def with_exec_lock(id)
          FileUtils.mkdir_p(@dir)
          File.open(File.join(@dir, "#{id}.exec.lock"), File::CREAT | File::RDWR) do |lock|
            unless lock.flock(File::LOCK_EX | File::LOCK_NB)
              raise Error, "lease '#{id}' already has a running exec"
            end

            yield
          end
        end

        # Usable NOW: only an ISSUED record inside its deadlines. A
        # preparing record was never delivered (or the process died
        # mid-issue) and a revoke-pending record has no valid handoff
        # or is mid-revocation — neither is ever usable or "live".
        def live?(lease, at: Time.now)
          return false unless lease["state"] == "issued"
          return false if lease["use_until"] && Time.parse(lease["use_until"]) <= at
          if lease["provider_expiry"] && Time.parse(lease["provider_expiry"]) <= at
            return false
          end

          true
        end

        private

        def atomic_write(path, lease)
          FileUtils.mkdir_p(@dir)
          temporary = "#{path}.#{Process.pid}.tmp"
          File.open(temporary, "w") do |file|
            file.write(JSON.pretty_generate(lease))
            file.flush
            file.fsync
          end
          begin
            File.rename(temporary, path)
          rescue Errno::ENOENT
            FileUtils.mkdir_p(File.dirname(path))
            File.rename(temporary, path)
          end
          FileUtils.chmod(0o600, path)
        end

        def lease_path(id)
          raise Error, "invalid lease id" unless id.to_s.match?(/\Alease-[a-f0-9]{16}\z/)

          File.join(@dir, "#{id}.json")
        end

        def now
          Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        end
      end
    end
  end
end
