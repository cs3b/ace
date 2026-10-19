# frozen_string_literal: true

require_relative "../errors"
require "etc"

module Ace
  module Lab
    module Molecules
      # Verifies role bindings from the trusted install manifest: the role's
      # account must exist after the account phase, and its instruction
      # source must be either a supported protocol reference (syntactic
      # validation only — context resolution belongs to ace-coworker /
      # ace-nav, see L3.1) or an absolute file path that exists and whose
      # static permission bits allow the account to read it. ACLs are out
      # of scope.
      class RoleVerifier
        PROTOCOL_PREFIXES = %w[wfi:// prompt:// tmpl://].freeze

        attr_reader :account_lookup, :group_source, :dry_run

        def initialize(account_lookup: nil, group_source: nil, dry_run: false)
          @account_lookup = account_lookup || method(:lookup_passwd)
          # Injectable group-membership seam: a callable returning the
          # gids the named account holds beyond its primary gid
          # (Etc.group scan in production). Supplementary groups are
          # ordinary static permission bits — distinct from the ACLs
          # that are out of scope.
          @group_source = group_source || method(:supplementary_gids)
          @dry_run = dry_run
        end

        # @param role [Hash] normalized manifest role entry
        # @return [Hash] {id:, account:, instructions:, status:, message:}
        def call(role:)
          base = {"id" => role["id"], "account" => role["account"],
                  "instructions" => role["instructions"]}

          entry = account_lookup.call(role["account"])
          if entry.nil? && !dry_run
            return base.merge("status" => "failed",
              "message" => "role '#{role['id']}' account '#{role['account']}' is not available; " \
                "fix the account phase first")
          end

          instructions = role["instructions"]
          return base.merge("status" => "verified", "message" => nil) if protocol?(instructions)

          verify_file(base, instructions, entry)
        end

        # Readiness probe for a project/worktree directory used by a
        # target executor (task 8xg.t.sbz.7.4, LAB-2): every ancestor of
        # the RESOLVED path must grant the account search (x) permission
        # and the directory itself must grant read+write+search (the
        # executor clones and provisions worktrees inside it — a
        # directory without x on itself is unusable however rw it is).
        # Returns nil when the account can work in the directory, or a
        # concrete reason. Same governing-class permission logic as the
        # instruction checks so the two can never drift apart.
        def directory_access_reason(path, entry)
          resolved = File.realpath(path)
          current = File.dirname(resolved)
          loop do
            stat = File.stat(current)
            return search_denied(current, entry) if (permission_bits(stat, entry) & 0o1).zero?
            break if current == "/"

            current = File.dirname(current)
          end
          stat = File.stat(resolved)
          return work_denied(resolved, entry) if (permission_bits(stat, entry) & 0o7) != 0o7

          nil
        rescue Errno::ENOENT, Errno::ENOTDIR, Errno::EACCES
          "'#{path}' does not exist or cannot be inspected for account '#{entry.name}'"
        end

        # Readiness probe for an executable the target executor must be
        # able to RUN (PR #393 final audit, FINAL-LAB3): every ancestor
        # of the RESOLVED path must grant search (x) and the file itself
        # must be a regular file granting the account execute through
        # its governing permission class — an installer-owned 0700
        # executable is NOT available to a different-uid executor.
        # Returns nil when the account can execute it, or a concrete
        # reason (same governing-class logic as the other probes).
        def executable_access_reason(path, entry)
          resolved = File.realpath(path)
          current = File.dirname(resolved)
          loop do
            stat = File.stat(current)
            return search_denied(current, entry) if (permission_bits(stat, entry) & 0o1).zero?
            break if current == "/"

            current = File.dirname(current)
          end
          stat = File.stat(resolved)
          return "'#{resolved}' is not a regular file" unless stat.file?
          return execute_denied(resolved, entry) if (permission_bits(stat, entry) & 0o1).zero?

          nil
        rescue Errno::ENOENT, Errno::ENOTDIR, Errno::EACCES
          "'#{path}' does not exist or cannot be inspected for account '#{entry.name}'"
        end

        private

        def search_denied(directory, entry)
          "'#{directory}' denies search permission to account '#{entry.name}'; the target " \
            "executor cannot reach the project through this ancestor"
        end

        def work_denied(directory, entry)
          "'#{directory}' denies read/write/search permission to account '#{entry.name}'; the " \
            "target executor cannot work inside the project"
        end

        def execute_denied(file, entry)
          "'#{file}' denies execute permission to account '#{entry.name}'; the target " \
            "executor cannot run it"
        end

        def protocol?(instructions)
          PROTOCOL_PREFIXES.any? { |prefix| instructions.start_with?(prefix) }
        end

        # entry is nil only in dry-run for an account the account phase
        # would create: readability depends on a uid that does not exist
        # yet, so the binding is predicted verified once the file itself
        # checks out.
        def verify_file(base, path, entry)
          stat = File.stat(path)
          unless stat.file?
            return base.merge("status" => "failed",
              "message" => "instructions '#{path}' is not a regular file")
          end

          if entry && !readable_by_account?(stat, entry)
            return base.merge("status" => "failed",
              "message" => "instructions '#{path}' is not readable by account '#{entry.name}' " \
                "(static permission bits; ACLs are out of scope)")
          end

          # Read bits on the file alone are not enough: POSIX requires
          # the search (x) bit on EVERY ancestor directory of the
          # resolved path, or the account cannot reach the file at all
          # (a 0644 file behind a 0700 directory is unreachable).
          if entry && !reachable_by_account?(path, entry)
            return base.merge("status" => "failed",
              "message" => "instructions '#{path}' is not reachable by account '#{entry.name}' " \
                "(an ancestor directory denies search permission; static permission bits; " \
                "ACLs are out of scope)")
          end

          base.merge("status" => "verified", "message" => nil)
        rescue Errno::ENOENT
          base.merge("status" => "failed",
            "message" => "instructions file '#{path}' does not exist")
        rescue SystemCallError => e
          base.merge("status" => "failed",
            "message" => "instructions file '#{path}' could not be verified (#{e.class.name})")
        end

        # Reachability: every ancestor of the RESOLVED path must grant
        # the account search permission through its governing class.
        # The final component is resolved too (File.realpath(path)):
        # realpath follows both ancestor symlinks AND a symlink at the
        # instruction file itself, mirroring what open(2) traverses —
        # judging only the symlink's own ancestors would miss an
        # unsearchable directory on the target's path. An unresolvable
        # or unstattable ancestor is conservatively unreachable.
        def reachable_by_account?(path, entry)
          current = File.dirname(File.realpath(path))
          loop do
            stat = File.stat(current)
            return false if (permission_bits(stat, entry) & 0o1).zero?
            break if current == "/"

            current = File.dirname(current)
          end
          true
        rescue Errno::ENOENT, Errno::ENOTDIR, Errno::EACCES
          false
        end

        # POSIX access checks do not fall through permission classes: a
        # file owned by the account is governed by the owner bits alone —
        # group/other bits never apply. Short-circuit per class so an
        # owner-permission-bit-clear file can never verify through a
        # gid match. The group class matches ANY group the account is a
        # member of — primary gid or supplementary (round 5): the
        # runtime's group credentials include them, so a
        # supplementary-group-granted permission genuinely applies.
        # Returns the governing class's rwx bits normalized to the low
        # octal (r=4, w=2, x=1), shared by the file-read check and the
        # ancestor search check so the two can never drift apart.
        def permission_bits(stat, entry)
          return (stat.mode >> 6) & 0o7 if stat.uid == entry.uid
          if stat.gid == entry.gid || group_source.call(entry.name).include?(stat.gid)
            return (stat.mode >> 3) & 0o7
          end

          stat.mode & 0o7
        end

        def readable_by_account?(stat, entry)
          (permission_bits(stat, entry) & 0o4).nonzero?
        end

        def supplementary_gids(username)
          gids = []
          Etc.group { |group| gids << group.gid if group.mem.include?(username) }
          gids
        end

        def lookup_passwd(username)
          Etc.getpwnam(username)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
