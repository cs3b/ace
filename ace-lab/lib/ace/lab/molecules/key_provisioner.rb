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
        # Filesystem ENOENT only: a missing ssh-keygen binary is already
        # classified via the runner's "enoent" status (command_failure),
        # so the remedy here is a convergence rerun, not installation.
        rescue Errno::ENOENT
          {"account" => account["username"], "path" => key["path"], "status" => "failed",
           "fingerprint" => nil,
           "message" => "key path '#{key["path"]}' disappeared while preparing; rerun ace-lab prepare"}
        end

        private

        def provision(key, account, machine)
          username = account["username"]
          path = key["path"]
          base = {"account" => username, "path" => path}

          if inside_git_worktree?(path)
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key path '#{path}' is inside a git worktree; secrets must not live in Git")
          end

          stat = lstat(path)

          if stat && !stat.file?
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key path '#{path}' exists but is not a regular file; refusing to overwrite")
          end

          # Dry-run predicts from the filesystem alone, before consulting
          # live passwd: the account phase may report would_create for an
          # account that does not exist yet, and a nil lookup must not
          # turn that prediction into a dependency failure.
          return predict(base, path, stat) if dry_run

          entry = account_lookup.call(username)
          unless entry
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "account '#{username}' is not available on this machine; fix the account phase first")
          end

          return existing(base, path, stat, entry) if stat

          generate(base, key, account, machine, path, entry)
        end

        # Prediction contract: dry-run must say what the wet run would do.
        # A missing key pair (behind a safe .ssh) is would_create; an
        # existing private key with a missing .pub is would_repair_public
        # (the wet run regenerates it); mode drift on an owner-matching
        # pair is would_fix_mode (the wet run enforces 0600/0644). The
        # .ssh symlink/non-directory refusal runs unconditionally — the
        # wet run refuses on both the create and the existing path, so a
        # planted .ssh symlink must never predict exists/would_*.
        def predict(base, path, stat)
          refusal = unsafe_ssh_dir_refusal(base, path)
          return refusal if refusal

          unless stat
            return base.merge("status" => "would_create", "fingerprint" => nil, "message" => nil)
          end

          public_path = "#{path}.pub"
          pub_stat = lstat(public_path)
          if pub_stat && !pub_stat.file?
            return non_regular_public_refusal(base, public_path)
          end

          unless pub_stat
            return base.merge("status" => "would_repair_public", "fingerprint" => nil, "message" => nil)
          end

          entry = account_lookup.call(base["account"])
          if entry
            refusal = ownership_refusal(base, [stat, pub_stat], entry)
            return refusal if refusal
          end

          if drift?(path, pub_stat, entry)
            return base.merge("status" => "would_fix_mode", "fingerprint" => nil, "message" => nil)
          end

          with_fingerprint(base.merge("status" => "exists"), public_path,
            "fingerprint of '#{public_path}' could not be read; resolve manually")
        end

        def drift?(path, pub_stat, entry)
          private_stat = File.stat(path)
          (private_stat.mode & 0o7777) != PRIVATE_MODE ||
            (pub_stat.mode & 0o7777) != PUBLIC_MODE ||
            (entry && (private_stat.uid != entry.uid || pub_stat.uid != entry.uid))
        end

        def existing(base, path, stat, entry)
          # Same guard as generate: the wet existing path chmods/chowns
          # both key files, and FileUtils.chmod/chown follow a planted
          # intermediate .ssh symlink — lstat(path) only guards the
          # final component (cross-account key theft otherwise).
          refusal = unsafe_ssh_dir_refusal(base, path)
          return refusal if refusal

          public_path = "#{path}.pub"
          pub_stat = lstat(public_path)
          if pub_stat && !pub_stat.file?
            return non_regular_public_refusal(base, public_path)
          end

          # Ownership-drift policy mirrors DirectoryProvisioner: an
          # existing pair owned by neither the declared account nor the
          # installer is refused, never silently taken over.
          refusal = ownership_refusal(base, [stat, pub_stat], entry)
          return refusal if refusal

          if pub_stat.nil?
            regenerated = regenerate_public(base, path, public_path, entry)
            return regenerated unless regenerated.nil?
          end

          refusal = enforce_modes_and_ownership(base, path, public_path, entry)
          return refusal if refusal

          with_fingerprint(base.merge("status" => "exists"), public_path,
            "fingerprint of '#{public_path}' could not be read; resolve manually")
        end

        def generate(base, key, account, machine, path, entry)
          ssh_dir = File.dirname(path)
          # An account-controlled home may carry a planted ~/.ssh symlink
          # or non-directory; mkdir_p/chmod/chown would follow it in the
          # privileged context (directory-ownership takeover of an
          # arbitrary path), so refuse before any mutation.
          refusal = unsafe_ssh_dir_refusal(base, path)
          return refusal if refusal

          refusal = ensure_ssh_dir(base, ssh_dir)
          return refusal if refusal

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

          # Post-keygen lstat: a keygen writing through a symlink
          # planted after the guards above must be detected and refused
          # before any ownership transfer touches the path.
          public_path = "#{path}.pub"
          post = lstat(path)
          post_pub = lstat(public_path)
          unless post && post.file? && post_pub && post_pub.file?
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key '#{path}' was not written as a regular file; " \
                "refusing — rerun ace-lab prepare")
          end

          refusal = enforce_modes_and_ownership(base, path, public_path, entry)
          return refusal if refusal

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

          # O_NOFOLLOW: a dangling .pub symlink planted by the account
          # must not turn this into an arbitrary privileged write; ELOOP
          # (symlink raced in after the lstat guard) is refused, not
          # raised. chmod/chown are fd-based on the already-verified
          # open handle, so no path-based re-resolution can race the
          # open.
          begin
            File.open(public_path, File::WRONLY | File::CREAT | File::TRUNC | File::NOFOLLOW) do |file|
              file.write(result["out"])
              file.chmod(PUBLIC_MODE)
              file.chown(entry.uid, entry.gid)
            end
          rescue Errno::ELOOP
            return non_regular_public_refusal(base, public_path)
          end
          nil
        end

        # Close the create-time TOCTOU window as far as stdlib allows:
        # the leaf is created with Dir.mkdir, whose EEXIST on a planted
        # symlink never follows it, and the created leaf is re-lstat'd
        # before the caller's chmod/chown — a leaf swapped mid-flight
        # for a symlink or a directory this process did not create is
        # refused instead of mutated. The window between this re-lstat
        # and the path-based chmod/chown that follow is a documented
        # accepted residual (usage.md).
        def ensure_ssh_dir(base, ssh_dir)
          # Intermediates (e.g. the home directory) are created per the
          # documented policy — mkdir_p follows existing components; the
          # leaf .ssh itself is the account-controlled component that
          # must not be created or accepted through a symlink.
          FileUtils.mkdir_p(File.dirname(ssh_dir))
          created = false
          begin
            Dir.mkdir(ssh_dir)
            created = true
          rescue Errno::EEXIST
            stat = lstat(ssh_dir)
            unless stat && stat.directory?
              return base.merge("status" => "failed", "fingerprint" => nil,
                "message" => "key directory '#{ssh_dir}' was replaced while preparing; " \
                  "refusing — rerun ace-lab prepare")
            end
          rescue Errno::ENOENT, Errno::ENOTDIR
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key directory '#{ssh_dir}' could not be created; rerun ace-lab prepare")
          end

          if created
            stat = lstat(ssh_dir)
            unless stat && stat.directory? && stat.uid == Process.euid
              return base.merge("status" => "failed", "fingerprint" => nil,
                "message" => "key directory '#{ssh_dir}' changed while preparing; " \
                  "refusing — rerun ace-lab prepare")
            end
          end
          nil
        end

        # fd-based, the same pattern as regenerate_public: chmod/chown
        # happen on an O_NOFOLLOW-opened handle, so no path
        # re-resolution can race the open with an account-planted
        # symlink (arbitrary chown-to-account). ELOOP — a symlink
        # swapped in after the lstat guards — is refused, not raised.
        # @return [Hash, nil] a refusal report when the file was
        #   replaced by a symlink mid-flight
        def enforce_modes_and_ownership(base, path, public_path, entry)
          begin
            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              file.chmod(PRIVATE_MODE)
              file.chown(entry.uid, entry.gid)
            end
          rescue Errno::ELOOP
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key '#{path}' was replaced by a symbolic link while preparing; " \
                "refusing — rerun ace-lab prepare")
          end

          begin
            File.open(public_path, File::RDONLY | File::NOFOLLOW) do |file|
              file.chmod(PUBLIC_MODE)
              file.chown(entry.uid, entry.gid)
            end
          rescue Errno::ELOOP
            return non_regular_public_refusal(base, public_path)
          rescue Errno::ENOENT
            # Vanished between the lstat guard and here; the next run
            # regenerates it — not worth failing the whole item.
            nil
          end
          nil
        end

        # A pre-existing key file owned by neither the declared account
        # nor the installer is foreign principal material at a
        # deployment-chosen path (e.g. a reused home directory): refuse
        # the takeover, mirroring the directory provisioner's policy.
        # @param stats [Array<File::Stat, nil>] lstats of the pair
        # @return [Hash, nil]
        def ownership_refusal(base, stats, entry)
          foreign = stats.compact.find { |stat| stat.uid != entry.uid && stat.uid != Process.euid }
          return nil unless foreign

          base.merge("status" => "failed", "fingerprint" => nil,
            "message" => "key path '#{base["path"]}' is owned by uid #{foreign.uid}, " \
              "expected account '#{entry.name}'; refusing takeover — resolve ownership manually")
        end

        def non_regular_public_refusal(base, public_path)
          base.merge("status" => "failed", "fingerprint" => nil,
            "message" => "public key '#{public_path}' exists but is not a regular file; refusing")
        end

        # All filesystem probes below are lstat-based: File.exist?
        # follows symlinks and must not gate privileged chmod/chown on
        # account-controlled paths.
        def unsafe_ssh_dir_refusal(base, path)
          ssh_dir = File.dirname(path)
          stat = lstat(ssh_dir)
          return nil unless stat

          if stat.symlink?
            base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key directory '#{ssh_dir}' is a symbolic link; refusing")
          elsif !stat.directory?
            base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key directory '#{ssh_dir}' exists but is not a directory; refusing")
          end
        end

        def lstat(path)
          File.lstat(path)
        rescue Errno::ENOENT, Errno::ENOTDIR
          nil
        end

        # @return [String, nil] SHA256 fingerprint from `ssh-keygen -lf`;
        #   read-only, safe in dry-run
        def read_fingerprint(public_path)
          result = runner.call(["ssh-keygen", "-lf", public_path])
          return nil unless result["status"] == "ok"

          match = result["out"].match(/(SHA256:[A-Za-z0-9+\/=]+)/)
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
