# frozen_string_literal: true

require_relative "../errors"
require "open3"
require "fileutils"

module Ace
  module Lab
    module Molecules
      # Idempotently ensures an ed25519 key pair exists for a manifest
      # account, with .ssh 0700, the private key 0600, the public key 0644
      # and ownership assigned to the account. Secret hygiene is an
      # acceptance criterion: the public fingerprint is the ONLY key
      # material fact that ever appears in a status, message or report —
      # private key bytes are never read into Ruby, printed, or passed as a
      # diagnostic argument; key paths inside a git worktree are refused
      # outright.
      class KeyProvisioner
        SSH_DIR_MODE = 0o700
        PRIVATE_MODE = 0o600
        PUBLIC_MODE = 0o644

        attr_reader :runner, :account_lookup, :dry_run

        def initialize(runner: nil, account_lookup: nil, dry_run: false)
          @runner = runner || method(:run_argv)
          @account_lookup = account_lookup || method(:lookup_passwd)
          @dry_run = dry_run
        end

        # @param key [Hash] normalized manifest key entry (path resolved)
        # @param account [Hash] normalized manifest account entry
        # @param machine [String] lab machine identity (key comment)
        # @return [Hash] {account:, path:, status:, fingerprint:, message:}
        def call(key:, account:, machine:)
          provision(key, account, machine)
        rescue Errno::EPERM, Errno::EACCES
          {"account" => account["username"], "path" => key["path"], "status" => "failed",
           "fingerprint" => nil,
           "message" => "insufficient permissions while preparing '#{key["path"]}'; " \
            "rerun ace-lab prepare with sudo or adjust ownership manually"}
        rescue Errno::ENOENT
          {"account" => account["username"], "path" => key["path"], "status" => "failed",
           "fingerprint" => nil,
           "message" => "ssh-keygen not found in PATH; install it and rerun ace-lab prepare"}
        end

        private

        def provision(key, account, machine)
          username = account["username"]
          path = key["path"]
          base = {"account" => username, "path" => path}

          entry = account_lookup.call(username)
          unless entry
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "account '#{username}' is not available on this machine; fix the account phase first")
          end

          if inside_git_worktree?(path)
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key path '#{path}' is inside a git worktree; secrets must not live in Git")
          end

          stat = begin
            File.lstat(path)
          rescue Errno::ENOENT
            nil
          end

          if stat && !stat.file?
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key path '#{path}' exists but is not a regular file; refusing to overwrite")
          end

          return existing(base, path, entry) if stat

          if dry_run
            return base.merge("status" => "would_create", "fingerprint" => nil, "message" => nil)
          end

          generate(base, key, account, machine, path, entry)
        end

        def existing(base, path, entry)
          public_path = "#{path}.pub"
          unless File.exist?(public_path)
            if dry_run
              return base.merge("status" => "failed", "fingerprint" => nil,
                "message" => "public key '#{public_path}' is missing; refusing to regenerate over an " \
                "unverifiable private key — resolve manually")
            end

            regenerated = regenerate_public(base, path, public_path, entry)
            return regenerated unless regenerated.nil?
          end

          enforce_modes_and_ownership(path, public_path, entry) unless dry_run
          with_fingerprint(base.merge("status" => "exists"), public_path,
            "fingerprint of '#{public_path}' could not be read; resolve manually")
        end

        def generate(base, key, account, machine, path, entry)
          ssh_dir = File.dirname(path)
          FileUtils.mkdir_p(ssh_dir)
          FileUtils.chmod(SSH_DIR_MODE, ssh_dir)
          FileUtils.chown(entry.uid, entry.gid, ssh_dir)

          comment = "#{account['username']}@#{machine}"
          result = runner.call(
            ["ssh-keygen", "-q", "-t", key["type"], "-N", "", "-C", comment, "-f", path]
          )
          unless result["status"] == "ok"
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => command_failure("ssh-keygen", result))
          end

          public_path = "#{path}.pub"
          enforce_modes_and_ownership(path, public_path, entry)
          with_fingerprint(base.merge("status" => "created"), public_path,
            "key pair '#{path}' was created but its fingerprint could not be read")
        end

        def with_fingerprint(base, public_path, failure_message)
          fingerprint = read_fingerprint(public_path)
          if fingerprint
            base.merge("fingerprint" => fingerprint, "message" => nil)
          else
            base.merge("fingerprint" => nil, "message" => failure_message)
          end
        end

        # Regenerate a missing .pub from the existing private key. The
        # derived public key is written straight to the .pub file — never
        # printed, never placed in a message.
        def regenerate_public(base, path, public_path, entry)
          result = runner.call(["ssh-keygen", "-y", "-f", path])
          if result["status"] != "ok"
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "public key '#{public_path}' is missing and could not be regenerated " \
              "(#{command_failure('ssh-keygen', result)})")
          end

          File.write(public_path, result["out"])
          FileUtils.chmod(PUBLIC_MODE, public_path)
          FileUtils.chown(entry.uid, entry.gid, public_path)
          nil
        end

        def enforce_modes_and_ownership(path, public_path, entry)
          FileUtils.chmod(PRIVATE_MODE, path)
          FileUtils.chmod(PUBLIC_MODE, public_path) if File.exist?(public_path)
          FileUtils.chown(entry.uid, entry.gid, path)
          FileUtils.chown(entry.uid, entry.gid, public_path) if File.exist?(public_path)
        end

        # @return [String, nil] SHA256 fingerprint from `ssh-keygen -lf`;
        #   read-only, safe in dry-run
        def read_fingerprint(public_path)
          result = runner.call(["ssh-keygen", "-lf", public_path])
          return nil unless result["status"] == "ok"

          match = result["out"].match(/(SHA256:[A-Za-z0-9+\/=+]+)/)
          match && match[1]
        end

        # Classified one-line command failure: status plus the first stderr
        # line only — never command output bodies (secret hygiene).
        def command_failure(command, result)
          if result["status"] == "enoent"
            return "#{command} not found in PATH; install it and rerun ace-lab prepare"
          end

          message = "#{command} failed (exit #{result['status']})"
          line = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
          line ? "#{message}: #{line}" : message
        end

        # Walk up from the key path looking for a .git entry: key material
        # must never live inside a git worktree (acceptance criterion).
        def inside_git_worktree?(path)
          current = File.expand_path(File.dirname(path))
          while (parent = File.dirname(current))
            return true if File.exist?(File.join(current, ".git"))
            break if parent == current

            current = parent
          end
          false
        end

        def run_argv(argv)
          out, err, status = Open3.capture3(*argv)
          {"status" => status.success? ? "ok" : status.exitstatus, "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError => e
          {"status" => "failed", "out" => "", "err" => e.class.name}
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
