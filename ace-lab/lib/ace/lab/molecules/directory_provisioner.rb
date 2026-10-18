# frozen_string_literal: true

require_relative "../errors"
require "etc"
require "fileutils"

module Ace
  module Lab
    module Molecules
      # Idempotently ensures a manifest-declared directory exists with the
      # declared mode and ownership. Pre-existing directories are never
      # silently taken over: a symlink at the path, a non-directory, or a
      # directory owned by a different account than declared is refused
      # with a resolve-manually message; only mode drift on an
      # owner-matching directory is repaired. Permission failures
      # (EPERM/EACCES) classify as actionable missing-permission reports.
      class DirectoryProvisioner
        attr_reader :account_lookup, :dry_run

        def initialize(account_lookup: nil, dry_run: false)
          @account_lookup = account_lookup || method(:lookup_passwd)
          @dry_run = dry_run
        end

        # @param directory [Hash] normalized manifest directory entry
        # @return [Hash] {path:, owner:, mode:, status:, message:}
        def call(directory:)
          path = directory["path"]
          mode = directory["mode"].to_i(8)
          stat = begin
            File.lstat(path)
          rescue Errno::ENOENT
            nil
          end

          if stat.nil?
            create_missing(path, directory, mode)
          elsif stat.symlink?
            refuse_symlink(path, directory)
          elsif !stat.directory?
            failure(path, "path '#{path}' is occupied by a non-directory; refusing", directory)
          else
            ensure_existing(path, directory, stat, mode)
          end
        rescue Errno::EPERM, Errno::EACCES
          failure(path,
            "insufficient permissions while preparing '#{path}'; rerun ace-lab prepare with sudo " \
            "or adjust ownership manually", directory)
        rescue SystemCallError => e
          failure(path, "path '#{path}' could not be prepared (#{e.class.name})", directory)
        end

        private

        def base(path, directory)
          {"path" => path, "owner" => directory["owner"], "mode" => directory["mode"]}
        end

        # Every failed entry carries the full {path, owner, mode} shape —
        # JSON consumers must see one shape per section, including
        # rescue-path failures.
        def failure(path, message, directory)
          base(path, directory).merge("status" => "failed", "message" => message)
        end

        def refuse_symlink(path, directory)
          failure(path, "path '#{path}' is a symbolic link; refusing", directory)
        end

        # Ownership an existing directory must match: the declared owner
        # account's uid, or the installer's euid when no owner is declared.
        # Returns nil when the declared owner account is not resolvable on
        # this machine (account phase not yet green).
        def expected_owner_uid(directory)
          return Process.euid unless directory["owner"]

          entry = account_lookup.call(directory["owner"])
          entry && entry.uid
        end

        def create_missing(path, directory, mode)
          if dry_run
            return base(path, directory).merge("status" => "would_create", "message" => nil)
          end

          missing = chown_target(directory)
          return owner_unavailable(path, directory) if directory["owner"] && missing.nil?

          refusal = create_leaf(path, directory)
          return refusal if refusal

          FileUtils.chmod(mode, path)
          chown_to_owner(path, directory, missing)
          base(path, directory).merge("status" => "created", "message" => nil)
        end

        # Close the create-time TOCTOU window as far as stdlib allows:
        # intermediate components are created per the documented policy
        # (mkdir_p follows existing components — the manifest is
        # root-owned and only the leaf carries declared values), but the
        # leaf uses Dir.mkdir, whose EEXIST on a planted symlink never
        # follows it, and the leaf is re-lstat'd before any chmod/chown:
        # a leaf that is not a real directory this process just created
        # is refused instead of mutated. The window between this
        # re-lstat and the chmod/chown that follow is a documented
        # accepted residual (usage.md).
        def create_leaf(path, directory)
          FileUtils.mkdir_p(File.dirname(path))
          Dir.mkdir(path)
          post = lstat(path)
          return nil if post && post.directory? && post.uid == Process.euid

          failure(path, "path '#{path}' changed while preparing; refusing — rerun ace-lab prepare",
            directory)
        rescue Errno::EEXIST
          failure(path, "path '#{path}' appeared or was replaced while preparing; " \
            "refusing — rerun ace-lab prepare", directory)
        rescue Errno::ENOENT, Errno::ENOTDIR
          failure(path, "path '#{path}' could not be created; rerun ace-lab prepare", directory)
        end

        def ensure_existing(path, directory, stat, mode)
          expected_uid = expected_owner_uid(directory)
          if directory["owner"] && expected_uid.nil?
            return owner_unavailable(path, directory)
          end

          if stat.uid != expected_uid
            owner = directory["owner"] || "installer"
            return failure(path,
              "directory '#{path}' exists but is owned by uid #{stat.uid} " \
              "(expected account '#{owner}'); refusing takeover — resolve ownership manually " \
              "or rerun ace-lab prepare with sudo", directory)
          end

          if (stat.mode & 0o7777) == mode
            return base(path, directory).merge("status" => "exists", "message" => nil)
          end

          return base(path, directory).merge("status" => "would_fix_mode", "message" => nil) if dry_run

          # Stale-stat re-check: the owner-matching lstat above may be
          # outdated by the time chmod runs; re-lstat and refuse unless
          # the leaf is still a real, owner-matching directory.
          fresh = lstat(path)
          unless fresh && fresh.directory? && fresh.uid == expected_uid
            return failure(path,
              "directory '#{path}' changed while preparing; refusing — rerun ace-lab prepare", directory)
          end

          FileUtils.chmod(mode, path)
          base(path, directory).merge("status" => "mode_fixed", "message" => nil)
        end

        def lstat(path)
          File.lstat(path)
        rescue Errno::ENOENT, Errno::ENOTDIR
          nil
        end

        def owner_unavailable(path, directory)
          remedy = if dry_run
            "the account phase would create it; ownership of existing '#{path}' cannot be " \
              "predicted before the account exists — rerun prepare --dry-run after the account phase"
          else
            "fix the account phase first"
          end
          failure(path,
            "owner account '#{directory["owner"]}' is not available on this machine; " \
            "#{remedy}", directory)
        end

        def chown_target(directory)
          return nil unless directory["owner"]

          account_lookup.call(directory["owner"])
        end

        def chown_to_owner(path, directory, entry)
          FileUtils.chown(entry.uid, entry.gid, path) if entry
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
