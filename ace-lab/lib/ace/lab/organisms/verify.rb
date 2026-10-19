# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/install_manifest_loader"
require_relative "../molecules/key_provisioner"
require_relative "../molecules/role_verifier"
require_relative "../molecules/caller_authorizer"
require "open3"
require "yaml"
require "date"

module Ace
  module Lab
    module Organisms
      # Read-only end-of-install readiness verification (L8.5, task
      # 8xg.t.sbz.7.4): checks that the installed lab is ready UNDER
      # THE TARGET ACCOUNTS — not merely for the installer's own
      # account. For every account, directory, key, role, project and
      # grant declared in the trusted install manifest it recomputes
      # the facts from the SAME artifacts install/resume derive truth
      # from (the manifest, the filesystem's permission bits and
      # ownership, the repositories, the per-project registry and the
      # trusted authorization document): no journal, no second state
      # owner, nothing written anywhere.
      #
      # Every check reports pass / fail / unknown with a concrete
      # reason; a failure beside healthy data never hides the healthy
      # data and never prevents the remaining checks from running. The
      # overall verdict (`ready`) is false when ANY check failed — a
      # missing file, wrong permission, unreadable role instructions,
      # an unreachable origin, a principal without grants or a
      # committable `_overseer` folder each block lab readiness.
      # `unknown` (a network remote the read-only verifier does not
      # dial) is reported and counted but does not block: it is not a
      # failure, and pretending it were one would make `verify`
      # unusable offline.
      #
      # Because verification reads only converged artifacts, a fresh
      # install and a resumed one verify identically — there is no
      # hidden gap after resume.
      class Verify
        PASS = "pass"
        FAIL = "fail"
        UNKNOWN = "unknown"

        attr_reader :manifest_path, :platform

        # @param manifest_path [String, nil] trusted manifest location
        # @param runner [Proc, nil] argv runner seam (git / ssh-keygen)
        # @param account_lookup [Proc, nil] passwd lookup seam
        # @param group_source [Proc, nil] supplementary-group seam
        #   (RoleVerifier)
        # @param trusted_read [Proc, nil] trusted-document read seam
        #   (defaults to GrantResolver.read_verified)
        # @param authorization_path [String, nil] trusted grants
        #   location (defaults to the fixed deployment path)
        # @param platform [String, nil] "darwin" / "linux"
        def initialize(manifest_path: nil, runner: nil, account_lookup: nil,
          group_source: nil, trusted_read: nil, authorization_path: nil, platform: nil)
          @manifest_path = manifest_path || Ace::Lab.install_manifest_path
          @runner = runner || method(:run_argv)
          @account_lookup = account_lookup || method(:lookup_passwd)
          @group_source = group_source
          @trusted_read = trusted_read || ->(path) { Molecules::GrantResolver.read_verified(path) }
          @authorization_path = authorization_path || Ace::Lab.authorization_path
          @platform = platform
        end

        # @return [Hash] {ready:, machine:, manifest:,
        #   authorization_path:, checks: {accounts:, directories:,
        #   keys:, roles:, repositories:, grants:, registry:,
        #   overseer:}, counts: {pass:, fail:, unknown:}}
        # @raise [Ace::Lab::InvalidConfigurationError] missing,
        #   untrusted or schema-invalid manifest — same classification
        #   as install/prepare
        def call
          manifest = Molecules::InstallManifestLoader.load(path: manifest_path, platform: platform)
          entries = manifest["accounts"].to_h { |a| [a["username"], @account_lookup.call(a["username"])] }

          checks = {
            "accounts" => check_accounts(manifest, entries),
            "directories" => check_directories(manifest, entries),
            "keys" => check_keys(manifest, entries),
            "roles" => check_roles(manifest),
            "repositories" => check_repositories(manifest),
            "grants" => check_grants(manifest),
            "registry" => check_registry(manifest),
            "overseer" => check_overseer(manifest)
          }
          flat = checks.values.flatten(1)
          {
            "ready" => flat.none? { |check| check["status"] == FAIL },
            "machine" => manifest["machine"],
            "manifest" => manifest_path,
            "authorization_path" => @authorization_path,
            "checks" => checks,
            "counts" => {
              PASS => flat.count { |check| check["status"] == PASS },
              FAIL => flat.count { |check| check["status"] == FAIL },
              UNKNOWN => flat.count { |check| check["status"] == UNKNOWN }
            }
          }
        end

        private

        def check_accounts(manifest, entries)
          manifest["accounts"].map do |account|
            username = account["username"]
            entry = entries[username]
            if entry.nil?
              next {"account" => username, "status" => FAIL,
                "reason" => "account '#{username}' does not exist on this machine; " \
                  "fix the account phase (ace-lab prepare) first",
                "uid" => nil, "shell" => nil}
            end

            reason = if entry.dir != account["home"]
              "account '#{username}' home is '#{entry.dir}' but the manifest declares " \
                "'#{account["home"]}' (the manifest home is authoritative for key paths)"
            elsif non_login_shell?(entry)
              "account '#{username}' has non-login shell '#{shell_of(entry)}'; " \
                "the target executor cannot log in"
            end
            {"account" => username, "status" => reason ? FAIL : PASS, "reason" => reason,
             "uid" => entry.uid, "shell" => shell_of(entry)}
          end
        end

        def check_directories(manifest, entries)
          manifest["directories"].map do |directory|
            path = directory["path"]
            stat = lstat(path)
            reason = if stat.nil?
              "directory '#{path}' is missing"
            elsif stat.symlink?
              "directory '#{path}' is a symbolic link"
            elsif !stat.directory?
              "'#{path}' exists but is not a directory"
            elsif (stat.mode & 0o7777) != directory["mode"].to_i(8)
              "directory '#{path}' mode is #{format('%04o', stat.mode & 0o7777)} " \
                "but the manifest declares #{directory["mode"]}"
            else
              owner_reason(directory, stat, entries)
            end
            {"directory" => path, "status" => reason ? FAIL : PASS, "reason" => reason}
          end
        end

        def check_keys(manifest, entries)
          provisioner = Molecules::KeyProvisioner.new(runner: @runner)
          by_username = manifest["accounts"].to_h { |a| [a["username"], a] }
          manifest["keys"].map do |key|
            username = key["account"]
            path = key["path"]
            entry = entries[username]
            reason = if entry.nil?
              "account '#{username}' does not exist; fix the account phase (ace-lab prepare) first"
            else
              key_pair_reason(path, entry)
            end
            fingerprint = if reason
              nil
            else
              provisioner.pair_fingerprint(path, "#{path}.pub")
            end
            if reason.nil? && fingerprint.nil?
              reason = "key pair '#{path}' is not usable (unreadable or mismatched key files); " \
                "resolve manually and rerun ace-lab prepare"
            end
            {"account" => username, "path" => path,
             "status" => reason ? FAIL : PASS, "reason" => reason, "fingerprint" => fingerprint}
          end
        end

        def check_roles(manifest)
          verifier = Molecules::RoleVerifier.new(
            account_lookup: @account_lookup, group_source: @group_source
          )
          manifest["roles"].map do |role|
            report = verifier.call(role: role)
            {"id" => role["id"], "account" => role["account"],
             "instructions" => role["instructions"],
             "status" => report["status"] == "verified" ? PASS : FAIL,
             "reason" => report["message"]}
          end
        end

        def check_repositories(manifest)
          manifest["projects"].map do |project|
            path = project["path"]
            remote = project["remote"]
            origin = origin_url(path)

            reason = repo_structure_reason(path)
            if reason.nil? && remote && origin != remote
              reason = if origin.nil?
                "'#{path}' has no origin remote configured but the manifest declares '#{remote}'"
              else
                "'#{path}' origin is '#{origin}' but the manifest declares '#{remote}'"
              end
            end

            status, reach = if reason
              [FAIL, nil]
            elsif remote.nil?
              [PASS, "no remote declared (offline repository)"]
            elsif (local = local_remote_path(remote))
              ls_remote(local) ? [PASS, "origin reachable at '#{remote}'"] : [FAIL,
                "origin '#{remote}' is not reachable (git ls-remote failed)"]
            else
              [UNKNOWN, "origin '#{remote}' is not a local-path remote; not probed by the " \
                "read-only verifier"]
            end

            {"project" => project["id"], "path" => path, "remote" => remote,
             "origin" => origin, "status" => status,
             "reason" => reason || (status == PASS ? nil : reach)}
          end
        end

        # Project visibility through grants: read the SAME trusted
        # document every grant reader verifies, and evaluate it with
        # the real read-side mechanics (CallerAuthorizer) as the
        # manifest principals' identities.
        def check_grants(manifest)
          document_check = installed_principles
          return [document_check] if document_check["status"] == FAIL

          principals = document_check.delete("principals") # internal only — keep JSON schema uniform
          [document_check] + manifest["grants"].map do |principal, projects|
            granted = Molecules::CallerAuthorizer.new(
              principals: principals, identity: [principal]
            ).authorized_project_ids
            missing = projects - granted
            if missing.empty?
              {"principal" => principal, "status" => PASS,
               "reason" => nil, "projects" => projects}
            else
              {"principal" => principal, "status" => FAIL,
               "reason" => "principal '#{principal}' is granted #{granted.sort.inspect} but the " \
                 "manifest declares #{projects.sort.inspect} (missing: #{missing.sort.join(', ')}); " \
                 "rerun ace-lab install",
               "projects" => granted.sort}
            end
          end
        end

        # On failure returns a synthetic failed check carrying the
        # classified reason (document-level failure). An UNTRUSTED but
        # present document fails the same synthetic check (a failed
        # check never hides the healthy data around it) instead of
        # aborting the whole report.
        def installed_principles
          path = @authorization_path
          begin
            content = @trusted_read.call(path)
          rescue Ace::Lab::InvalidConfigurationError => e
            return {"principal" => "(document)", "status" => FAIL,
              "reason" => "trusted authorization file #{path} failed verification: #{e.message}",
              "projects" => nil}
          end
          if content.nil?
            return {"principal" => "(document)", "status" => FAIL,
              "reason" => "trusted authorization file #{path} is missing; no principal can see " \
                "the installed projects — rerun ace-lab install", "projects" => nil}
          end

          begin
            document = YAML.safe_load(content, permitted_classes: [Date], aliases: true)
            unless document.is_a?(Hash)
              raise Ace::Lab::InvalidConfigurationError, "#{path} must contain a YAML mapping"
            end
            principals = Molecules::GrantResolver.validate_principals(document["principals"] || {}, path)
            {"principal" => "(document)", "status" => PASS, "reason" => nil,
             "principals" => principals, "projects" => nil}
          rescue Psych::Exception
            {"principal" => "(document)", "status" => FAIL,
             "reason" => "#{path} could not be parsed as YAML; failing closed", "projects" => nil}
          rescue Ace::Lab::InvalidConfigurationError => e
            {"principal" => "(document)", "status" => FAIL, "reason" => e.message, "projects" => nil}
          end
        end

        def check_registry(manifest)
          manifest["projects"].map do |project|
            path = File.join(project["path"], ".ace", "lab", "config.yml")
            reason = registry_reason(path, project)
            {"project" => project["id"], "registry" => path,
             "status" => reason ? FAIL : PASS, "reason" => reason}
          end
        end

        def registry_reason(path, project)
          return "'#{path}' is missing; the project is not visible through the configuration " \
            "cascade (ace-lab projects / ace-overseer projects)" unless File.file?(path)

          begin
            document = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          rescue Psych::Exception
            return "'#{path}' could not be parsed as YAML"
          end
          return "'#{path}' must contain a YAML mapping" unless document.is_a?(Hash)

          projects = document.dig("topology", "projects")
          entry = projects.is_a?(Array) ? projects.find { |c| c.is_a?(Hash) && c["id"] == project["id"] } : nil
          return "'#{path}' does not register project '#{project["id"]}'" if entry.nil?
          if entry["path"] && entry["path"] != project["path"]
            return "project '#{project["id"]}' is registered at '#{entry["path"]}' but the " \
              "manifest declares '#{project["path"]}'"
          end
          nil
        end

        def check_overseer(manifest)
          manifest["projects"].map do |project|
            dir = File.join(project["path"], ".ace-tasks", "_overseer")
            reason = if !File.directory?(dir)
              "private folder '#{dir}' is missing"
            elsif (ignore_reason = gitignore_reason(project["path"], ".ace-tasks/_overseer"))
              ignore_reason
            end
            {"project" => project["id"], "dir" => dir,
             "status" => reason ? FAIL : PASS, "reason" => reason}
          end
        end

        # --- shared probes ------------------------------------------------

        def key_pair_reason(path, entry)
          stat = lstat(path)
          public_path = "#{path}.pub"
          pub_stat = lstat(public_path)
          return "private key '#{path}' is missing" if stat.nil?
          return "private key '#{path}' is not a regular file" unless stat.file?
          return "public key '#{public_path}' is missing" if pub_stat.nil?
          return "public key '#{public_path}' is not a regular file" unless pub_stat.file?

          if (stat.mode & 0o7777) != Molecules::KeyProvisioner::PRIVATE_MODE
            return "private key '#{path}' mode is #{format('%04o', stat.mode & 0o7777)} " \
              "but #{format('%04o', Molecules::KeyProvisioner::PRIVATE_MODE)} is required"
          end
          if (pub_stat.mode & 0o7777) != Molecules::KeyProvisioner::PUBLIC_MODE
            return "public key '#{public_path}' mode is #{format('%04o', pub_stat.mode & 0o7777)} " \
              "but #{format('%04o', Molecules::KeyProvisioner::PUBLIC_MODE)} is required"
          end
          if stat.uid != entry.uid
            return "private key '#{path}' is owned by uid #{stat.uid} but the account " \
              "'#{entry.name}' is uid #{entry.uid}"
          end
          if pub_stat.uid != entry.uid
            return "public key '#{public_path}' is owned by uid #{pub_stat.uid} but the " \
              "account '#{entry.name}' is uid #{entry.uid}"
          end

          ssh_dir = File.dirname(path)
          ssh_stat = lstat(ssh_dir)
          if ssh_stat.nil?
            "key directory '#{ssh_dir}' is missing"
          elsif !ssh_stat.directory? || ssh_stat.symlink?
            "key directory '#{ssh_dir}' is not a directory"
          elsif (ssh_stat.mode & 0o7777) != Molecules::KeyProvisioner::SSH_DIR_MODE
            "key directory '#{ssh_dir}' mode is #{format('%04o', ssh_stat.mode & 0o7777)} " \
              "but #{format('%04o', Molecules::KeyProvisioner::SSH_DIR_MODE)} is required"
          elsif ssh_stat.uid != entry.uid
            "key directory '#{ssh_dir}' is owned by uid #{ssh_stat.uid} but the account " \
              "'#{entry.name}' is uid #{entry.uid}"
          end
        end

        def repo_structure_reason(path)
          stat = lstat(path)
          return "'#{path}' is missing" if stat.nil?
          return "'#{path}' is not a directory" unless stat.directory?

          result = @runner.call(["git", "-C", path, "rev-parse", "--show-toplevel"])
          if dubious_ownership?(result)
            return "git refuses to operate on '#{path}' because of dubious ownership — run verify " \
              "as the account that owns the repository, or configure git safe.directory"
          end
          return "'#{path}' is not a Git repository" unless result["status"] == "ok"

          reported = result["out"].to_s.lines.first.to_s.strip
          return "'#{path}' is a subdirectory of the repository at '#{reported}'" unless same_location?(reported, path)

          nil
        end

        # Raw stored URL: `git remote get-url` applies url.<base>.insteadOf
        # rewrites from the invoking user's git config, which would
        # false-fail an origin that matches the manifest canonically.
        def origin_url(path)
          result = @runner.call(["git", "-C", path, "config", "--get", "remote.origin.url"])
          return nil unless result["status"] == "ok"

          url = result["out"].to_s.lines.first.to_s.strip
          url.empty? ? nil : url
        end

        # A remote the verifier may dial without leaving the machine:
        # an existing local path (bare or not), optionally via file://.
        def local_remote_path(remote)
          candidate = remote.start_with?("file://") ? remote.delete_prefix("file://") : remote
          candidate if candidate.start_with?("/") && File.directory?(candidate)
        end

        def ls_remote(remote)
          @runner.call(["git", "ls-remote", remote])["status"] == "ok"
        end

        # nil when Git ignores the path; otherwise the concrete reason
        # (including the dubious-ownership refusal, which must not be
        # misdiagnosed as "not ignored").
        def gitignore_reason(root, relative)
          result = @runner.call(["git", "-C", root, "check-ignore", "--", relative])
          if dubious_ownership?(result)
            return "git refuses to operate on '#{root}' because of dubious ownership — run " \
              "verify as the owning account, or configure git safe.directory"
          end
          return nil if result["status"] == "ok"

          "'#{File.join(root, relative)}' is not ignored by Git; private overseer tasks " \
            "would be committed (add '.ace-tasks/_overseer/' to the project .gitignore " \
            "and rerun ace-lab install)"
        end

        # Git's ownership-safety refusal (verify often runs as a different
        # account than the one that converged the repository — exactly the
        # under-target-accounts posture). Detected so the reported reason
        # is actionable instead of "not a Git repository".
        def dubious_ownership?(result)
          result["status"] != "ok" && result["err"].to_s.include?("dubious ownership")
        end

        def same_location?(reported, path)
          File.realpath(reported) == File.realpath(path)
        rescue Errno::ENOENT, Errno::ENOTDIR, Errno::EACCES
          File.expand_path(reported) == File.expand_path(path)
        end

        def owner_reason(directory, stat, entries)
          owner = directory["owner"]
          return nil if owner.nil?

          entry = entries[owner]
          return nil if entry.nil?

          if stat.uid != entry.uid
            "directory '#{directory["path"]}' is owned by uid #{stat.uid} but the manifest " \
              "declares owner '#{owner}' (uid #{entry.uid})"
          end
        end

        def non_login_shell?(entry)
          shell = shell_of(entry).to_s
          shell.end_with?("/nologin") || shell == "/bin/false" || shell == "/usr/bin/false"
        end

        def shell_of(entry)
          entry.respond_to?(:shell) ? entry.shell : nil
        end

        def lstat(path)
          File.lstat(path)
        rescue Errno::ENOENT, Errno::ENOTDIR
          nil
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
