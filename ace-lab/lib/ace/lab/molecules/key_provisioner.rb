# frozen_string_literal: true

require_relative "../errors"
require "open3"
require "fileutils"
require "tmpdir"

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
        # Shared by the wet existing path and the dry-run prediction
        # (same condition, same message — the two paths must never
        # report different outcomes for the same pair).
        NOT_USABLE_TEMPLATE = "key pair '%s' is not usable (unreadable or mismatched key files); " \
          "resolve manually and rerun ace-lab prepare"

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
        # Last-resort classifier mirroring DirectoryProvisioner: any
        # other syscall failure on the provision path (e.g. ELOOP on
        # the path-based directory chmod in a race) is a classified
        # failed item, never a raw backtrace that aborts the report.
        rescue SystemCallError => e
          {"account" => account["username"], "path" => key["path"], "status" => "failed",
           "fingerprint" => nil,
           "message" => "key path '#{key["path"]}' could not be prepared (#{e.class.name}); " \
            "rerun ace-lab prepare"}
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

          # Dry-run predicts from read-only filesystem probes and
          # read-only ssh-keygen invocations (-lf/-y in
          # classify_existing_pair), never mutating the pair or the
          # account, and without consulting live passwd: the account
          # phase may report would_create for an account that does not
          # exist yet, and a nil lookup must not turn that prediction
          # into a dependency failure.
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
        #
        # Invariant: EVERY wet-path refusal must have a predict
        # counterpart here — the wet create/existing/predict tripling of
        # guard logic means a refusal added to only one branch silently
        # drifts dry-run fidelity (this happened with the pre-keygen
        # .pub guard in round 5).
        def predict(base, path, stat)
          refusal = unsafe_ssh_dir_refusal(base, path)
          return refusal if refusal

          unless stat
            # Parity with the wet generate path: a pre-existing
            # foreign-owned .ssh would be refused, not predicted
            # would_create (the account must be resolvable for the
            # ownership check; a would-create account has no uid yet).
            entry = account_lookup.call(base["account"])
            if entry
              ssh_stat = lstat(File.dirname(path))
              if ssh_stat
                refusal = ssh_dir_takeover_refusal(base, File.dirname(path), ssh_stat, entry)
                return refusal if refusal
              end
            end

            # Parity with the wet generate path (round 5, S1): a
            # pre-planted <key>.pub symlink makes the wet run refuse
            # before invoking ssh-keygen — the prediction must refuse
            # too, never would_create.
            public_path = "#{path}.pub"
            pub_stat = lstat(public_path)
            return non_regular_public_refusal(base, public_path) if pub_stat && !pub_stat.file?

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

            ssh_stat = lstat(File.dirname(path))
            if ssh_stat
              refusal = ssh_dir_takeover_refusal(base, File.dirname(path), ssh_stat, entry)
              return refusal if refusal
            end
          else
            # Round 5 (C4): entry is nil only when the account phase
            # would create the account, so the pair's ownership cannot
            # be checked against a uid that does not exist yet. A pair
            # owned by neither the installer nor the to-be-created
            # account is conservatively predicted as the wet run's
            # takeover refusal — pessimistic only in the pathological
            # case where useradd reuses the foreign uid, never unsound.
            foreign = [stat, pub_stat].compact.find { |candidate| candidate.uid != Process.euid }
            if foreign
              return base.merge("status" => "failed", "fingerprint" => nil,
                "message" => "key path '#{path}' is owned by uid #{foreign.uid}, which is " \
                  "neither the installer nor the to-be-created account '#{base["account"]}'; " \
                  "the wet run would refuse takeover — resolve ownership manually")
            end
          end

          # Shared pair classification BEFORE the drift branch: the
          # wet run converges modes first and then fails verification
          # on a garbage pair, so the prediction must say failed, not
          # would_fix_mode — mode repair is only ever predicted for a
          # pair that verifies as usable.
          kind, fingerprint = classify_existing_pair(path, public_path)
          case kind
          when :repair_public
            return base.merge("status" => "would_repair_public", "fingerprint" => nil, "message" => nil)
          when :unusable
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => format(NOT_USABLE_TEMPLATE, path))
          end

          if drift?(path, pub_stat, entry)
            return base.merge("status" => "would_fix_mode", "fingerprint" => nil, "message" => nil)
          end

          base.merge("status" => "exists", "fingerprint" => fingerprint, "message" => nil)
        end

        # Shared classification of an existing key pair, used by BOTH
        # the wet existing path and the dry-run prediction so the two
        # can never drift apart: whatever ssh-keygen would verify after
        # the wet convergence steps, the prediction judges read-only up
        # front. @return [Array(Symbol, String|nil)] kind
        #   (:verified/:unusable/:repair_public) and the fingerprint
        #   (nil unless :verified).
        def classify_existing_pair(path, public_path)
          # TOCTOU safety net: callers lstat'd the .pub just before, so
          # a nil here means the file vanished in between — deliberately
          # kept (do not remove as "unreachable") so a race degrades to
          # the same repair verdict the wet path would produce.
          return [:repair_public, nil] if lstat(public_path).nil?

          fingerprint = pair_fingerprint(path, public_path)
          fingerprint ? [:verified, fingerprint] : [:unusable, nil]
        end

        def drift?(path, pub_stat, entry)
          private_stat = File.stat(path)
          (private_stat.mode & 0o7777) != PRIVATE_MODE ||
            (pub_stat.mode & 0o7777) != PUBLIC_MODE ||
            (entry && (private_stat.uid != entry.uid || pub_stat.uid != entry.uid)) ||
            (entry && ssh_dir_drift?(File.dirname(path), entry))
        end

        # The documented ".ssh is 0700" invariant is converged on the
        # existing-key path too, not only at creation: mode drift (or
        # an installer-owned .ssh that should belong to the account)
        # is repaired exactly like key-file drift. Foreign ownership is
        # NOT drift — it is refused (ssh_dir_takeover_refusal).
        def ssh_dir_drift?(ssh_dir, entry)
          stat = File.stat(ssh_dir)
          (stat.mode & 0o7777) != SSH_DIR_MODE || stat.uid != entry.uid
        rescue Errno::ENOENT, Errno::ENOTDIR
          false
        end

        # Path-based directory convergence — the same accepted residual
        # as the create path (Ruby stdlib has no fd-based directory
        # chmod); a mid-flight SystemCallError is classified by the
        # method-level rescue on call.
        def converge_ssh_dir(ssh_dir, ssh_stat, entry)
          return if ssh_stat.nil?
          return if (ssh_stat.mode & 0o7777) == SSH_DIR_MODE && ssh_stat.uid == entry.uid

          FileUtils.chmod(SSH_DIR_MODE, ssh_dir)
          FileUtils.chown(entry.uid, entry.gid, ssh_dir)
        end

        # @return [Hash, nil] refusal when a pre-existing .ssh is owned
        #   by neither the declared account nor the installer
        def ssh_dir_takeover_refusal(base, ssh_dir, stat, entry)
          return nil if stat.uid == entry.uid || stat.uid == Process.euid

          base.merge("status" => "failed", "fingerprint" => nil,
            "message" => "key directory '#{ssh_dir}' is owned by uid #{stat.uid}, " \
              "expected account '#{entry.name}'; refusing takeover — resolve ownership manually")
        end

        def existing(base, path, stat, entry)
          # Same guard as generate: the wet existing path chmods/chowns
          # both key files, and FileUtils.chmod/chown follow a planted
          # intermediate .ssh symlink — lstat(path) only guards the
          # final component (cross-account key theft otherwise).
          refusal = unsafe_ssh_dir_refusal(base, path)
          return refusal if refusal

          ssh_dir = File.dirname(path)
          ssh_stat = lstat(ssh_dir)
          if ssh_stat
            refusal = ssh_dir_takeover_refusal(base, ssh_dir, ssh_stat, entry)
            return refusal if refusal
          end

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

          # Converge the .ssh invariant on the existing path too (M1):
          # 0700 + account ownership, refused never taken over when
          # foreign-owned (checked above).
          converge_ssh_dir(ssh_dir, ssh_stat, entry)

          # The same shared classification the prediction runs —
          # after the wet convergence steps a repair_public outcome is
          # impossible (regenerate_public ran above), so only the
          # usable/unusable verdict remains.
          _kind, fingerprint = classify_existing_pair(path, public_path)
          if fingerprint
            base.merge("status" => "exists", "fingerprint" => fingerprint, "message" => nil)
          else
            base.merge("status" => "failed", "fingerprint" => nil,
              "message" => format(NOT_USABLE_TEMPLATE, path))
          end
        end

        def generate(base, key, account, machine, path, entry)
          ssh_dir = File.dirname(path)
          # An account-controlled home may carry a planted ~/.ssh symlink
          # or non-directory; mkdir_p/chmod/chown would follow it in the
          # privileged context (directory-ownership takeover of an
          # arbitrary path), so refuse before any mutation.
          refusal = unsafe_ssh_dir_refusal(base, path)
          return refusal if refusal

          refusal = ensure_ssh_dir(base, ssh_dir, entry)
          return refusal if refusal

          # Round 5 (S1): a pre-planted <key>.pub symlink must be
          # refused BEFORE ssh-keygen runs — keygen creates the .pub by
          # path and would write through the symlink (root-owned file
          # creation at an account-chosen location). Mirrored in
          # predict's missing-private branch.
          public_path = "#{path}.pub"
          pub_stat = lstat(public_path)
          return non_regular_public_refusal(base, public_path) if pub_stat && !pub_stat.file?

          # Round 5 (S2): only the mode is enforced before keygen; the
          # .ssh ownership transfer is deliberately deferred until the
          # pair is verified below. While ssh-keygen writes by path, a
          # freshly created .ssh stays root-owned 0700 and unwritable
          # by the account, so no symlink can be planted inside it
          # during the keygen window. Remaining residual (documented
          # in usage.md): on a home the account already owns, the
          # account can rename the root-owned .ssh mid-flight and
          # substitute its own (caught by the post-keygen lstat only
          # after the write).
          FileUtils.chmod(SSH_DIR_MODE, ssh_dir)

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
          post = lstat(path)
          post_pub = lstat(public_path)
          unless post && post.file? && post_pub && post_pub.file?
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key '#{path}' was not written as a regular file; " \
                "refusing — rerun ace-lab prepare")
          end

          refusal = enforce_modes_and_ownership(base, path, public_path, entry)
          return refusal if refusal

          # Deferred .ssh ownership transfer (S2): only now, with the
          # pair verified as regular files and the key files already
          # carrying account ownership, does the directory pass to the
          # account.
          FileUtils.chown(entry.uid, entry.gid, ssh_dir)

          verified_result(base, "created", path, public_path,
            "key pair '#{path}' was created but could not be verified as usable; " \
            "rerun ace-lab prepare")
        end

        # A key pair is ready only when it is USABLE: the public file
        # yields a fingerprint AND the key derived from the private
        # file matches it. `ssh-keygen -y -f <private>` regenerates the
        # public half from the private key (garbage files fail here),
        # and its fingerprint is compared against the `.pub` file's —
        # note `-lf <private>` cannot be used for that comparison:
        # ssh-keygen resolves the ADJACENT `.pub` instead of deriving
        # from the private key, so a swapped `.pub` would compare with
        # itself. Only the fingerprint — public key material — ever
        # reaches the report; private bytes stay inside the ssh-keygen
        # subprocess, and the derived public key lives in a private
        # tmpdir for the duration of one read-only comparison. A pair
        # that cannot be verified is a failed item, never exists or
        # created with fingerprint:nil.
        def pair_fingerprint(path, public_path)
          public_fingerprint = read_fingerprint(public_path)
          return nil unless public_fingerprint

          with_derivable_private(path) do |private_path|
            derived_matches_public?(private_path, public_fingerprint)
          end && public_fingerprint
        end

        # Whether the public key ssh-keygen derives from the private
        # half matches the `.pub` file's fingerprint (see
        # pair_fingerprint for why the derivation cannot be shortcut).
        # @return [Boolean]
        def derived_matches_public?(private_path, public_fingerprint)
          derived = runner.call(["ssh-keygen", "-y", "-f", private_path])
          return false unless derived["status"] == "ok"

          Dir.mktmpdir("ace-lab-key") do |tmp|
            derived_path = File.join(tmp, "derived.pub")
            File.write(derived_path, derived["out"])
            read_fingerprint(derived_path) == public_fingerprint
          end
        end

        # ssh-keygen refuses to load a private key whose permission
        # bits are too open ("bad permissions"), even for a read-only
        # derivation. The shared pair classification must judge a
        # mode-drifted pair BEFORE the wet chmod converges it, so the
        # derivation runs against a 0600 copy in a private tmpdir when
        # the mode has drifted — read-only with respect to the
        # provisioned path, and the copy never leaves the tmpdir (a
        # byte-stream via FileUtils.cp, never printed or rendered).
        def with_derivable_private(path)
          if (File.stat(path).mode & 0o7777) == PRIVATE_MODE
            return yield(path)
          end

          Dir.mktmpdir("ace-lab-key") do |tmp|
            copy = File.join(tmp, "private")
            FileUtils.cp(path, copy)
            File.chmod(PRIVATE_MODE, copy)
            yield(copy)
          end
        end

        def verified_result(base, success_status, path, public_path, failure_message)
          fingerprint = pair_fingerprint(path, public_path)
          if fingerprint
            base.merge("status" => success_status, "fingerprint" => fingerprint, "message" => nil)
          else
            base.merge("status" => "failed", "fingerprint" => nil, "message" => failure_message)
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
        def ensure_ssh_dir(base, ssh_dir, entry)
          # Intermediates (e.g. the home directory) are created per the
          # documented policy — mkdir_p follows existing components; the
          # leaf .ssh itself is the account-controlled component that
          # must not be created or accepted through a symlink.
          # mkdir_p re-raises EEXIST when an existing component is not
          # a directory and ENOTDIR for components under a file — both
          # classified here (a leftover regular file at the manifest
          # home must fail the item, not abort the report).
          begin
            FileUtils.mkdir_p(File.dirname(ssh_dir))
          rescue Errno::EEXIST, Errno::ENOTDIR
            return base.merge("status" => "failed", "fingerprint" => nil,
              "message" => "key directory '#{ssh_dir}' could not be created; " \
                "check the parent path and rerun ace-lab prepare")
          end
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
            # A pre-existing .ssh owned by neither the declared account
            # nor the installer is foreign principal material: chmod
            # 0700 + chown would be a takeover, so refuse like key
            # files (the documented blanket policy).
            refusal = ssh_dir_takeover_refusal(base, ssh_dir, stat, entry)
            return refusal if refusal
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
          if result["status"] == "exec_failed"
            return "#{command} could not be executed (#{result['err']}); rerun ace-lab prepare"
          end

          message = "#{command} failed (#{exit_detail(result['status'])})"
          line = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
          line ? "#{message}: #{line}" : message
        end

        # Round 5 (C2): a signal-killed child has no exitstatus (nil) —
        # render the terminating signal instead of a malformed
        # "exit " interpolation.
        def exit_detail(status)
          status.is_a?(Integer) ? "exit #{status}" : status.to_s
        end

        # Walk up from the key path's PHYSICAL location looking for a
        # .git entry: key material must never live inside a git worktree
        # (acceptance criterion). Lexical ancestors are not enough — an
        # ancestor symlink (alias -> /repo/nested) would land the real
        # key inside the repository while this walk sees only the alias
        # spelling. Resolution happens before any generate/mutate step,
        # like the lstat guards above. An unresolvable-for-permission
        # path (nil physical_path) is judged as INSIDE — fail-closed —
        # because an ancestor denying search could hide exactly the
        # symlink the resolution exists to catch.
        def inside_git_worktree?(path)
          physical = physical_path(File.expand_path(path))
          return true if physical.nil?

          current = File.dirname(physical)
          while (parent = File.dirname(current))
            return true if File.exist?(File.join(current, ".git"))
            break if parent == current

            current = parent
          end
          false
        end

        # Resolve where `path` physically lives: realpath the deepest
        # existing ancestor (following symlinks — the same
        # resolve-before-mutate discipline as the lstat guards), then
        # rebuild the not-yet-existing tail on top, so a missing `.ssh`
        # behind an existing alias is judged by the alias target too.
        # Returns nil when an ancestor resolves with EACCES (account
        # denies search to the unprivileged installer): the tail beyond
        # it cannot be verified, so callers must fail closed instead of
        # falling back to the lexical spelling.
        def physical_path(path)
          current = path
          tail = []
          until current == "/"
            resolved = begin
              File.realpath(current)
            rescue Errno::ENOENT, Errno::ENOTDIR
              nil
            rescue Errno::EACCES
              return nil
            end
            return File.join(resolved, *tail) unless resolved.nil?

            tail.unshift(File.basename(current))
            current = File.dirname(current)
          end
          File.join("/", *tail)
        end

        def run_argv(argv)
          out, err, status = Open3.capture3(*argv)
          {"status" => status.success? ? "ok" : (status.exitstatus || "signal #{status.termsig}"),
           "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError => e
          {"status" => "exec_failed", "out" => "", "err" => e.class.name}
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
