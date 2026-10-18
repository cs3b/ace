# frozen_string_literal: true

require_relative "../errors"

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

        attr_reader :account_lookup

        def initialize(account_lookup: nil)
          @account_lookup = account_lookup || method(:lookup_passwd)
        end

        # @param role [Hash] normalized manifest role entry
        # @return [Hash] {id:, account:, instructions:, status:, message:}
        def call(role:)
          base = {"id" => role["id"], "account" => role["account"],
                  "instructions" => role["instructions"]}

          entry = account_lookup.call(role["account"])
          unless entry
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

        def verify_file(base, path, entry)
          stat = File.stat(path)
          unless stat.file?
            return base.merge("status" => "failed",
              "message" => "instructions '#{path}' is not a regular file")
          end

          unless readable_by_account?(stat, entry)
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

        def readable_by_account?(stat, entry)
          return true if stat.uid == entry.uid && (stat.mode & 0o400).nonzero?
          return true if stat.gid == entry.gid && (stat.mode & 0o040).nonzero?

          (stat.mode & 0o004).nonzero?
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
