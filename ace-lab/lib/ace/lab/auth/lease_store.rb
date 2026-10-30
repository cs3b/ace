# frozen_string_string: true
# frozen_string_literal: true

require "securerandom"
require "json"
require "fileutils"

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
      class LeaseStore
        STATES = %w[issued revoke-pending revoked].freeze

        attr_reader :dir

        def initialize(dir)
          @dir = dir
        end

        # @return [Hash] the created lease record
        def create(profile:, role:, principal:, task:, assignment:, repos:,
          use_until:, provider_expiry:)
          lease = {"id" => "lease-#{SecureRandom.hex(8)}",
                   "profile" => profile, "role" => role, "principal" => principal,
                   "task" => task, "assignment" => assignment, "repos" => repos.sort,
                   "state" => "issued", "requested_at" => now,
                   "use_until" => use_until, "provider_expiry" => provider_expiry,
                   "token_ref" => nil, "cleanup" => nil}
          write(lease)
          lease
        end

        # Idempotency: the LIVE lease for the same task/assignment/
        # profile/role correlation, if any. A finished or scope-changed
        # correlation does not match — that needs a new request.
        def find_live(task:, assignment:, profile:, role:)
          all.filter_map do |lease|
            next unless lease["task"] == task && lease["assignment"] == assignment &&
              lease["profile"] == profile && lease["role"] == role &&
              lease["state"] != "revoked"
            lease
          end.min_by { |lease| lease["requested_at"].to_s }
        end

        def load(id)
          path = lease_path(id)
          raise Error, "unknown lease '#{id}'" unless File.file?(path)

          JSON.parse(File.read(path))
        rescue JSON::ParserError
          raise Error, "lease record '#{id}' is unreadable"
        end

        def all
          return [] unless Dir.exist?(@dir)

          Dir.glob(File.join(@dir, "*.json")).sort.filter_map do |path|
            JSON.parse(File.read(path))
          rescue JSON::ParserError, Errno::EACCES
            nil
          end
        end

        # Atomic update under an exclusive lease lock: transitions and
        # token-ref/cleanup writes never race a concurrent exec/revoke.
        def update(id)
          path = lease_path(id)
          File.open(path, File::RDWR) do |file|
            file.flock(File::LOCK_EX)
            file.rewind
            lease = JSON.parse(file.read)
            yield(lease)
            file.rewind
            file.truncate(0)
            content = JSON.pretty_generate(lease)
            file.write(content)
            file.flush
            file.fsync
            lease
          end
        end

        def write(lease)
          FileUtils.mkdir_p(@dir)
          path = lease_path(lease["id"])
          temporary = "#{path}.#{Process.pid}.tmp"
          File.write(temporary, JSON.pretty_generate(lease))
          File.rename(temporary, path)
          FileUtils.chmod(0o600, path)
          lease
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

        def live?(lease, at: Time.now)
          return false if lease["state"] == "revoked"
          return false if lease["use_until"] && Time.parse(lease["use_until"]) <= at
          if lease["provider_expiry"] && Time.parse(lease["provider_expiry"]) <= at
            return false
          end

          true
        end

        private

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
