# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/install_manifest_loader"
require_relative "../molecules/key_provisioner"
require_relative "../molecules/role_verifier"
require_relative "../molecules/caller_authorizer"
require_relative "../atoms/topology_schema"
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
        # @param nav_runner [Proc, nil] (argv, cwd) runner seam for
        #   resolving protocol role instructions through ace-nav
        # @param platform [String, nil] "darwin" / "linux"
        def initialize(manifest_path: nil, runner: nil, account_lookup: nil,
          group_source: nil, trusted_read: nil, authorization_path: nil, nav_runner: nil,
          platform: nil)
          @manifest_path = manifest_path || Ace::Lab.install_manifest_path
          @runner = runner || method(:run_argv)
          @account_lookup = account_lookup || method(:lookup_passwd)
          @group_source = group_source
          @trusted_read = trusted_read || ->(path) { Molecules::GrantResolver.read_verified(path) }
          @authorization_path = authorization_path || Ace::Lab.authorization_path
          @nav_runner = nav_runner || method(:run_nav)
          @platform = platform
        end

        # @return [Hash] {ready:, machine:, manifest:,
        #   authorization_path:, checks: {accounts:, directories:,
        #   keys:, roles:, repositories:, grants:, registry:,
        #   overseer:, adapters:, tools:}, counts: {pass:, fail:,
        #   unknown:}}
        # @raise [Ace::Lab::InvalidConfigurationError] missing,
        #   untrusted or schema-invalid manifest — same classification
        #   as install/prepare
        def call
          manifest = Molecules::InstallManifestLoader.load(path: manifest_path, platform: platform)
          entries = manifest["accounts"].to_h { |a| [a["username"], @account_lookup.call(a["username"])] }
          executors = target_executors(manifest, entries)

          checks = {
            "accounts" => check_accounts(manifest, entries),
            "directories" => check_directories(manifest, entries),
            "keys" => check_keys(manifest, entries),
            "roles" => check_roles(manifest),
            "repositories" => check_repositories(manifest, executors),
            "grants" => check_grants(manifest),
            "registry" => check_registry(manifest),
            "overseer" => check_overseer(manifest),
            "adapters" => check_adapters(manifest),
            "tools" => check_tools(manifest)
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

        # Final verification resolves role instructions through the
        # ACTUAL resolver for the execution context (LAB-4): prepare's
        # protocol check is deliberately syntax-only, so reusing it as
        # readiness would promote a syntactically valid but
        # nonexistent role (`wfi://does-not-exist/not-a-role`) to
        # verified readiness. Protocol instructions are resolved with
        # ace-nav from every declared project root (the execution
        # contexts the executor works in); a role that fails resolution
        # is a failed check, an environment without the resolver
        # reports unknown (offline verifier posture, like network
        # remotes) and does not block.
        def check_roles(manifest)
          verifier = Molecules::RoleVerifier.new(
            account_lookup: @account_lookup, group_source: @group_source
          )
          manifest["roles"].map do |role|
            report = verifier.call(role: role)
            if report["status"] == "verified"
              status, reason = protocol_resolution(role["instructions"], manifest)
            else
              status, reason = FAIL, report["message"]
            end
            {"id" => role["id"], "account" => role["account"],
             "instructions" => role["instructions"],
             "status" => status, "reason" => reason}
          end
        end

        # @return [Array<(String, String, nil)>] pass/fail/unknown with
        #   reason for protocol instructions; file-path instructions
        #   were already resolved (readability) by the RoleVerifier.
        def protocol_resolution(instructions, manifest)
          unless Molecules::RoleVerifier::PROTOCOL_PREFIXES.any? { |p| instructions.start_with?(p) }
            return [PASS, nil]
          end

          contexts = manifest["projects"].map { |project| project["path"] }
          if contexts.empty?
            return [PASS, "no project declared as an execution context; syntax verified only"]
          end

          failures = []
          unresolved_resolver = false
          contexts.each do |root|
            result = @nav_runner.call([nav_binary(root), "resolve", instructions], root)
            if result["status"] == "ok" && !result["out"].to_s.lines.first.to_s.strip.empty?
              next
            end

            if %w[enoent exec_failed].include?(result["status"])
              unresolved_resolver = true
            else
              failures << "project '#{File.basename(root)}': #{resolution_error(result)}"
            end
          end
          return [FAIL, "role instructions '#{instructions}' do not resolve through ace-nav " \
            "for the execution context (#{failures.join('; ')})"] unless failures.empty?
          return [UNKNOWN, "ace-nav is not available to resolve role instructions " \
            "'#{instructions}'; not probed by the read-only verifier"] if unresolved_resolver

          [PASS, nil]
        end

        def resolution_error(result)
          detail = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
          detail ? detail : "ace-nav exited with status #{result['status']}"
        end

        # Same binary choice the executor's resolver makes
        # (Ace::Coworker::Molecules::InstructionResolver): the
        # project's binstub when present, otherwise the PATH lookup.
        # A privileged installer never executes repository-controlled
        # binstubs (same trust posture as the LAB-1 symlink refusals):
        # under root only the PATH-installed resolver is used.
        def nav_binary(project_root)
          binstub = File.join(project_root, "bin", "ace-nav")
          use_binstub = !Process.uid.zero? && File.executable?(binstub)
          use_binstub ? binstub : "ace-nav"
        end

        def run_nav(argv, cwd)
          out, err, status = Open3.capture3(*argv, chdir: cwd)
          {"status" => status.success? ? "ok" : (status.exitstatus || "signal #{status.termsig}"),
           "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError, IOError => e
          {"status" => "exec_failed", "out" => "", "err" => e.class.name}
        end

        # The declared target executors: the distinct accounts the
        # manifest binds roles to (nil entries — accounts that failed
        # lookup — are dropped; the accounts check already fails those).
        def target_executors(manifest, entries)
          manifest["roles"].filter_map { |role| entries[role["account"]] }
            .uniq { |entry| entry.uid }
        end

        def check_repositories(manifest, executors)
          verifier = Molecules::RoleVerifier.new(
            account_lookup: @account_lookup, group_source: @group_source
          )
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
            # Readiness is judged for the target EXECUTOR, not the
            # invoking installer (LAB-2): a repository behind an
            # installer-owned 0700 ancestor with a different target UID
            # is NOT ready even though the installer's git succeeded.
            if reason.nil?
              reason = executors.filter_map do |entry|
                access = verifier.directory_access_reason(path, entry)
                access ? "executor '#{entry.name}': #{access}" : nil
              end.join("; ")
              reason = nil if reason.empty?
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
          if document_check["missing"] && manifest["grants"].empty?
            # No grants declared: the trusted document is not part of
            # this lab's contract, and none was written — requiring one
            # would make a grants-less manifest permanently unready.
            return [{"principal" => "(document)", "status" => PASS,
                     "reason" => "no grants declared; no trusted authorization document required",
                     "projects" => nil}]
          end
          document_check.delete("missing") # internal only — keep JSON schema uniform
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
            return {"principal" => "(document)", "status" => FAIL, "missing" => true,
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

          # Shape validation through the same schema every registry
          # consumer applies (LAB-6): a syntactically valid but
          # structurally malformed document (`topology: invalid`) must
          # become a classified per-project failure, never a TypeError
          # that kills the whole readiness report.
          begin
            Atoms::TopologySchema.normalize!(document)
          rescue Ace::Lab::InvalidConfigurationError => e
            return "'#{path}' is not a valid lab configuration: #{e.message}"
          end

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

        # Declared communication/HITL adapters (task 8xg.t.sbz.7.2/.7.4,
        # LAB-3): configuration validity is re-derived from the trusted
        # manifest (the single state owner for the declaration) and an
        # adapter that names a local command is probed for availability
        # — a broken adapter blocks readiness with a classified failure,
        # never a crash. Network reachability stays out of scope (L9).
        def check_adapters(manifest)
          manifest["adapters"].map do |adapter|
            reason = if !adapter["config"].is_a?(Hash)
              "adapter '#{adapter['id']}' configuration is not a mapping"
            elsif adapter["command"]
              adapter_command_reason(adapter)
            end
            note = if reason.nil? && adapter["command"].nil?
              "configured (no local command declared; network reachability is out of scope)"
            end
            probe = adapter["command"] ? path_probe(adapter["command"]) : :pass
            status = if probe == :unknown
              UNKNOWN
            elsif reason
              FAIL
            else
              PASS
            end
            {"adapter" => adapter["id"], "kind" => adapter["kind"], "command" => adapter["command"],
             "status" => status, "reason" => reason || note}
          end
        end

        # Required tools (task 8xg.t.sbz.7.4, LAB-3): presence check
        # only — the tool must resolve to an executable; a missing tool
        # blocks readiness. No execution, no network.
        def check_tools(manifest)
          manifest["tools"].map do |tool|
            case path_probe(tool)
            when :pass
              {"tool" => tool, "status" => PASS, "reason" => nil}
            when :fail
              {"tool" => tool, "status" => FAIL,
               "reason" => "required tool '#{tool}' is not available (not found on PATH)"}
            else
              {"tool" => tool, "status" => UNKNOWN,
               "reason" => "PATH is unset; cannot probe tool '#{tool}' availability"}
            end
          end
        end

        # Resolve an executable without running it: a name containing a
        # separator must be executable at that path; a bare name must
        # resolve through PATH. An unset or empty PATH leaves the probe
        # undecidable and yields unknown (never a false failure) — a
        # minimal-PATH environment must not block readiness.
        def path_probe(name)
          if name.include?(File::SEPARATOR)
            return File.executable?(name) && File.file?(name) ? :pass : :fail
          end

          directories = (ENV["PATH"].to_s.split(File::PATH_SEPARATOR) - [""])
          return :unknown if directories.empty?
          directories.any? do |directory|
            candidate = File.join(directory, name)
            File.file?(candidate) && File.executable?(candidate)
          end ? :pass : :fail
        end

        def tool_reason(tool)
          case path_probe(tool)
          when :fail then "required tool '#{tool}' is not available (not found on PATH)"
          when :unknown then nil
          end
        end

        def adapter_command_reason(adapter)
          case path_probe(adapter["command"])
          when :fail
            "adapter '#{adapter['id']}' command '#{adapter['command']}' is not available " \
              "(not found on PATH); fix the adapter installation or the manifest declaration"
          when :unknown
            "PATH is unset; cannot probe adapter '#{adapter['id']}' command availability"
          end
        end

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
