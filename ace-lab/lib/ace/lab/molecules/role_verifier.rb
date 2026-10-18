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

        private

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

          base.merge("status" => "verified", "message" => nil)
        rescue Errno::ENOENT
          base.merge("status" => "failed",
            "message" => "instructions file '#{path}' does not exist")
        rescue SystemCallError => e
          base.merge("status" => "failed",
            "message" => "instructions file '#{path}' could not be verified (#{e.class.name})")
        end

        # POSIX access checks do not fall through permission classes: a
        # file owned by the account is governed by the owner bit alone —
        # group/other readability never applies. Short-circuit per
        # class so an owner-readable-bit-clear file can never verify
        # through a gid match. The group class matches ANY group the
        # account is a member of — primary gid or supplementary
        # (round 5): the runtime's group credentials include them, so a
        # supplementary-group-readable file genuinely is readable.
        def readable_by_account?(stat, entry)
          return (stat.mode & 0o400).nonzero? if stat.uid == entry.uid
          if stat.gid == entry.gid || group_source.call(entry.name).include?(stat.gid)
            return (stat.mode & 0o040).nonzero?
          end

          (stat.mode & 0o004).nonzero?
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
