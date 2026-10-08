# frozen_string_literal: true

require_relative "protected_worker_entry"
require_relative "execution_network_selection"

require "json"
require "digest"
require "etc"
require_relative "systemd_scope_manager"
require_relative "readiness_configuration"

module Ace
  module Runtime
    module Molecules
      # Root-installed artifacts plus the system manager's effective properties.
      # These establish installation identity, not effective runtime isolation;
      # the same-User readiness action and live owner verify that separately.
      class ExecutionUnitInstallation
        SCHEMA = "ace.execution-unit-manifest/v1"
        ROLES = %w[slice_fragment service_fragment unit_dropin native_executable native_configuration
          readiness_executable readiness_configuration boundary_manifest bootstrap worker_executable runtime_dependency].freeze
        REQUIRED_ROLES = %w[slice_fragment service_fragment native_executable native_configuration
          readiness_executable readiness_configuration boundary_manifest bootstrap worker_executable].freeze
        CONTEXT_REQUIRED_ROLES = %w[slice_fragment service_fragment boundary_manifest bootstrap
          context_executable context_configuration interpreter].freeze
        CONTEXT_ROLES = (CONTEXT_REQUIRED_ROLES + %w[unit_dropin runtime_dependency]).freeze
        CODEX_REQUIRED_ROLES = %w[slice_fragment service_fragment native_executable native_configuration boundary_manifest].freeze
        CODEX_ROLES = (CODEX_REQUIRED_ROLES + %w[unit_dropin runtime_dependency]).freeze
        SERVICE_REQUIRED = {"Type" => "exec", "Restart" => "no", "RestartForceExitStatus" => [[], []],
          "KillMode" => "control-group", "SendSIGKILL" => true, "Delegate" => false,
          "ProtectControlGroups" => true, "NoNewPrivileges" => true, "CapabilityBoundingSet" => 0,
          "AmbientCapabilities" => 0, "RestrictNamespaces" => 0, "PrivateIPC" => true,
          "PrivateDevices" => true, "PrivateTmp" => false, "MountAPIVFS" => true, "ProtectKernelTunables" => true, "BindLogSockets" => false,
          "DevicePolicy" => "closed", "DeviceAllow" => [], "ProtectSystem" => "strict", "DynamicUser" => false, "PAMName" => "",
          "EnvironmentFiles" => [], "PassEnvironment" => [], "UnsetEnvironment" => [],
          "StandardInput" => "null", "TTYPath" => "", "StandardOutput" => "journal", "StandardError" => "journal", "RuntimeDirectoryPreserve" => "no",
          "RuntimeDirectoryMode" => 0o700, "UMask" => 0o077, "RootImage" => "", "RootImageOptions" => [], "RootEphemeral" => false, "ExtensionDirectories" => [],
          "ExtensionImages" => [], "MountImages" => [], "TemporaryFileSystem" => [], "InaccessiblePaths" => []}.freeze
        EMPTY_ACTIVATION = %w[Requisite BindsTo PartOf Upholds OnFailure OnSuccess OnFailureOf OnSuccessOf
          TriggeredBy Triggers PropagatesStopTo StopPropagatedFrom JoinsNamespaceOf].freeze
        NATIVE_ENVIRONMENT = %w[HERDR_CONFIG_PATH HERDR_SOCKET_PATH HOME SHELL PATH LANG LC_ALL TERM
          TMPDIR TMP TEMP XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_RUNTIME_DIR CODEX_HOME CLAUDE_CONFIG_DIR].freeze
        MANAGER_ENVIRONMENT = (NATIVE_ENVIRONMENT + %w[LANGUAGE LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
          LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION]).freeze
        IMPLICIT_NAMESPACE_ROOTS = %w[/dev /proc /sys /run /tmp /var/tmp].freeze
        EMPTY_EXEC = %w[ExecConditionEx ExecStartPreEx ExecReloadEx ExecStopEx ExecStopPostEx].freeze

        class Files
          def authority_socket!(authority)
            path = authority.fetch("socket_path")
            ProtectedSocket.root_path!(File.dirname(path), directory: true, owner: authority.fetch("uid"))
            identity = ProtectedSocket.socket_identity(path)
            raise RuntimeUnavailableError, "selected authority socket owner differs" unless identity.last == authority.fetch("uid")
            identity
          end
          def read(path, limit:)
            ProtectedSocket.root_path!(path)
            File.open(path, File::RDONLY | File::NONBLOCK | File::NOFOLLOW) do |file|
              stat = file.stat
              unless stat.file? && stat.uid.zero? && (stat.mode & 0o6022).zero? && stat.size <= limit
                raise RuntimeUnavailableError, "installed artifact descriptor ownership is unsafe"
              end
              bytes = file.read(limit + 1)
              raise RuntimeUnavailableError, "installed artifact is oversized" if bytes.bytesize > limit
              after = file.stat
              unless [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode, stat.size, stat.mtime, stat.ctime] ==
                  [after.dev, after.ino, after.uid, after.gid, after.mode, after.size, after.mtime, after.ctime] && bytes.bytesize == stat.size
                raise RuntimeUnavailableError, "installed held artifact changed"
              end
              bytes
            end
          end

          def activation_routes(paths, service_unit)
            routes = []
            visited = 0
            pending = paths.map { |path| [path, 0] }
            until pending.empty?
              directory, depth = pending.shift
              begin
                ProtectedSocket.root_path!(directory, directory: true)
              rescue RuntimeUnavailableError
                if !File.exist?(directory) && !File.symlink?(directory)
                  ancestor = File.dirname(directory)
                  ancestor = File.dirname(ancestor) until File.exist?(ancestor) || ancestor == "/"
                  ProtectedSocket.root_path!(ancestor, directory: true)
                  next
                end
                raise
              end
              Dir.children(directory).sort.each do |name|
                visited += 1
                raise RuntimeUnavailableError, "installed activation graph is oversized" if visited > 50_000
                path = File.join(directory, name)
                stat = File.lstat(path)
                if stat.symlink?
                  raise RuntimeUnavailableError, "activation graph link owner differs" unless stat.uid.zero?
                  target = File.expand_path(File.readlink(path), directory)
                  if File.basename(target) == service_unit ||
                      (name == service_unit && directory.match?(/\.(?:wants|requires|upholds)\z/))
                    routes << path
                  end
                elsif stat.directory?
                  raise RuntimeUnavailableError, "activation graph directory is too deep" if depth >= 8
                  pending << [path, depth + 1]
                end
              end
            end
            routes
          end

          def sha256(path)
            ProtectedSocket.root_path!(path)
            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              stat = file.stat
              unless stat.file? && stat.uid.zero? && (stat.mode & 0o6022).zero? && stat.size <= 268_435_456
                raise RuntimeUnavailableError, "installed artifact kind/mode/size is unsafe"
              end
              digest = Digest::SHA256.new
              while (chunk = file.read(65_536))
                digest.update(chunk)
              end
              digest.hexdigest
            end
          end
        end

        def initialize(scope:, native:, bootstrap:, worker_entry:, worker_uid:, worker_gid:, files: Files.new)
          @scope, @native, @bootstrap, @worker_entry, @files = scope, native, bootstrap, worker_entry, files
          ProtectedWorkerEntry.validate!(@worker_entry)
          @worker_uid, @worker_gid = worker_uid, worker_gid
        end

        # Context entries have their own fixed protocol. The same effective
        # installation, activation, mount and isolation checks still apply.
        def self.for_inbox_context(service:, configuration:, load_paths:, authority:, owner_credentials:, files: Files.new)
          unless owner_credentials.is_a?(Hash) && owner_credentials.keys.sort == %w[gid groups uid] &&
              owner_credentials.values_at("uid", "gid").all? { |id| id.is_a?(Integer) && id.positive? } &&
              owner_credentials["groups"].is_a?(Array) && owner_credentials["groups"].size <= 64 &&
              owner_credentials["groups"].all? { |id| id.is_a?(Integer) && id >= 0 } &&
              owner_credentials["groups"] == owner_credentials["groups"].sort.uniq &&
              load_paths.is_a?(Array) && load_paths.size.between?(1, 64) && load_paths.uniq.size == load_paths.size
            raise RuntimeUnavailableError, "context installation selection differs"
          end
          selected = allocate
          selected.send(:initialize_context, service, configuration, load_paths, authority, owner_credentials, files)
          selected
        end

        # Selection only. The original bootstrap authenticates mapping ownership;
        # verify! still requires the actual fixed manager profile and full topology.
        def verify_codex_runtime_selection!(service:, intent_reference:, manager:)
          unless @codex_service && @codex_service == service && @codex_intent_reference == intent_reference
            raise RuntimeUnavailableError, "Codex dedicated installation selection differs"
          end
          verify!(manager: manager)
        end

        def self.for_codex_runtime(service:, intent_reference:, original_mapping:, mapping_id:, authority:, files: Files.new)
          require_relative "codex_runtime_installation"
          selected = allocate
          selected.send(:initialize_codex_runtime, service, intent_reference, original_mapping, mapping_id, authority, files)
          selected
        end

        # Descriptor shape only; no effective unit observation or role grant.
        def self.validate_inbox_context_service!(service)
          selected = allocate
          selected.send(:validate_context_service!, service)
          true
        end

        def verify!(manager:)
          slot = @scope.fetch("slot_id")
          unless slot.is_a?(String) && SystemdScopeManager::UNIT.match?(slot)
            raise RuntimeUnavailableError, "installed slot identity is invalid"
          end
          selected_service = @context || @codex_service
          path = selected_service ? selected_service.fetch("unit_manifest").fetch("path") : "/etc/ace/execution-slots/#{slot}/unit-manifest.json"
          bytes = @files.read(path, limit: 65_536)
          unless Digest::SHA256.hexdigest(bytes) == @scope.fetch("unit_manifest_sha256") &&
              (!selected_service || bytes.bytesize == selected_service.fetch("unit_manifest").fetch("bytes"))
            raise RuntimeUnavailableError, "unit manifest bytes differ from deployment"
          end
          manifest = JSON.parse(bytes)
          unless manifest.is_a?(Hash) && manifest.keys.sort == %w[artifacts properties schema slot_id] &&
              manifest["schema"] == SCHEMA && manifest["slot_id"] == slot
            raise RuntimeUnavailableError, "unit manifest schema/slot differs"
          end
          artifacts = verify_artifacts!(manifest.fetch("artifacts"))
          profile = @context ? manager.inspect_inbox_context_profile : manager.inspect_profile
          verify_profile!(profile, manifest.fetch("properties"), artifacts)
          manifest
        rescue SystemCallError, IOError, JSON::ParserError, KeyError, TypeError, NoMethodError
          raise RuntimeUnavailableError, "installed execution units cannot be verified"
        end

        # Source validity only. The caller owns selected staged bytes; this
        # neither observes a live authority nor grants installed readiness.
        def validate_staged_boundary_topology!(service:, artifacts:, authority:)
          validate_boundary_topology!(service, artifacts, authority: authority)
          true
        end

        def inbox_context_scope
          raise RuntimeUnavailableError, "installation is not a context service" unless @context
          @scope
        end

        def inbox_context_configuration_reference
          raise RuntimeUnavailableError, "installation is not a context service" unless @context
          @context_configuration
        end

        def inbox_context_service
          raise RuntimeUnavailableError, "installation is not a context service" unless @context
          @context
        end

        # Called from the held context configuration before service admission.
        # Native startup bytes and IPC paths must be actual members of this
        # SAME complete installed profile, not merely readable host selections.
        def verify_inbox_native_projection!(references:, resources:, manager:)
          raise RuntimeUnavailableError, "installation is not a context service" unless @context
          manifest = verify!(manager: manager)
          artifacts = manifest.fetch("artifacts")
          profile = manager.inspect_inbox_context_profile.fetch("service")
          unless references.is_a?(Array) && references.size.between?(3, 512) &&
              resources.is_a?(Array) && resources.size <= 64
            raise RuntimeUnavailableError, "context native projection exceeds bounds"
          end
          references.each do |ref|
            unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] &&
                ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 268_435_456) &&
                artifacts.any? { |artifact| artifact.values_at("host_path", "view_path", "sha256", "role") ==
                  [ref.fetch("path"), ref.fetch("path"), ref.fetch("sha256"), "runtime_dependency"] }
              raise RuntimeUnavailableError, "context native startup reference is not exactly projected"
            end
            bytes = @files.read(ref.fetch("path"), limit: ref.fetch("bytes"))
            unless bytes.bytesize == ref.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == ref.fetch("sha256")
              raise RuntimeUnavailableError, "context native startup reference differs"
            end
          end
          boundary = JSON.parse(@files.read(@context.fetch("boundary_manifest").fetch("path"), limit: 65_536))
          resources.each do |resource|
            unless resource.is_a?(Hash) && resource.keys.sort == %w[access gid kind mode path uid] &&
                %w[read write].include?(resource["access"]) && path?(resource["path"])
              raise RuntimeUnavailableError, "context native resource fields differ"
            end
            path = resource.fetch("path")
            readonly = resource.fetch("access") == "read"
            mounts = profile.fetch(readonly ? "BindReadOnlyPaths" : "BindPaths")
            unless mounts.include?([path, path, false, 0]) &&
                boundary.fetch("resources").any? { |entry| entry.values_at("host_path", "view_path", "stage", "worker_visible", "read_only") ==
                  [path, path, "parent", true, readonly] } &&
                (!readonly || profile.fetch("BindPaths").none? { |mount| overlaps?(path, mount[1]) } &&
                  profile.fetch("ReadWritePaths").none? { |root| overlaps?(path, root) })
              raise RuntimeUnavailableError, "context native resource is not exactly projected"
            end
          end
          verify!(manager: manager)
          true
        rescue SystemCallError, IOError, JSON::ParserError, KeyError, TypeError, NoMethodError
          raise RuntimeUnavailableError, "context native projection is unavailable"
        end

        private

        def initialize_context(service, configuration, load_paths, authority, credentials, files)
          validate_context_service!(service)
          refs = service.slice("unit_manifest", "boundary_manifest", "entry", "interpreter", "bootstrap_manifest").merge("configuration" => configuration)
          unless refs.values.all? { |ref| ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && path?(ref["path"]) &&
              ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 268_435_456) &&
              ref["sha256"].is_a?(String) && ref["sha256"].match?(/\A[0-9a-f]{64}\z/) } &&
              load_paths.all? { |path| path?(path) }
            raise RuntimeUnavailableError, "context installation artifacts differ"
          end
          @scope = immutable_selection(service.fetch("execution_scope"))
          @context = immutable_selection(service)
          @context_configuration, @context_authority = immutable_selection(configuration), immutable_selection(authority)
          @context_load_paths, @context_groups = immutable_selection(load_paths), immutable_selection(credentials.fetch("groups"))
          @worker_uid, @worker_gid, @files = credentials.fetch("uid"), credentials.fetch("gid"), files
        rescue KeyError, TypeError
          raise RuntimeUnavailableError, "context installation selection is incomplete"
        end

        def validate_context_service!(service)
          unless service.is_a?(Hash) && service.keys.sort == %w[bootstrap_manifest boundary_manifest entry execution_scope interpreter unit_manifest] &&
              service.reject { |key, _| key == "execution_scope" }.values.all? { |ref|
                ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && path?(ref["path"]) &&
                  ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 268_435_456) &&
                  ref["sha256"].is_a?(String) && ref["sha256"].match?(/\A[0-9a-f]{64}\z/)
              }
            raise RuntimeUnavailableError, "context service descriptor differs"
          end
          scope = service.fetch("execution_scope")
          unless scope.is_a?(Hash) && scope.keys.sort == %w[backend boundary_manifest_sha256 network_namespace_path root_directory runtime_directory service_unit slice_unit slot_id unit_manifest_sha256] &&
              scope["backend"] == "linux_systemd_cgroup_v2" && scope["slot_id"].is_a?(String) && SystemdScopeManager::UNIT.match?(scope["slot_id"]) &&
              %w[root_directory runtime_directory network_namespace_path].all? { |key| path?(scope[key]) } &&
              scope.fetch("runtime_directory").start_with?("/run/") && !overlaps?(scope.fetch("root_directory"), scope.fetch("runtime_directory")) &&
              {"slice_unit" => ".slice", "service_unit" => ".service"}.all? { |key, suffix|
                scope[key].is_a?(String) && SystemdScopeManager::UNIT.match?(scope[key]) && scope[key].end_with?(suffix) && !scope[key].downcase.include?("overseer")
              } &&
              scope["unit_manifest_sha256"] == service.fetch("unit_manifest").fetch("sha256") &&
              scope["boundary_manifest_sha256"] == service.fetch("boundary_manifest").fetch("sha256") &&
              service.fetch("unit_manifest").fetch("bytes") <= 65_536 && service.fetch("boundary_manifest").fetch("bytes") <= 65_536
            raise RuntimeUnavailableError, "context service scope differs"
          end
        rescue KeyError, TypeError, NoMethodError
          raise RuntimeUnavailableError, "context service descriptor is incomplete"
        end

        def immutable_selection(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable_selection(item)] }.freeze
          when Array then value.map { |item| immutable_selection(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end

        def verify_artifacts!(artifacts)
          minimum = @context ? CONTEXT_REQUIRED_ROLES.size : @codex_service ? CODEX_REQUIRED_ROLES.size : 9
          unless artifacts.is_a?(Array) && artifacts.size.between?(minimum, 512) &&
              artifacts.all? { |a| a.is_a?(Hash) && a.keys.sort == %w[host_path role sha256 view_path] } &&
              artifacts.map { |a| a["host_path"] }.uniq.size == artifacts.size
            raise RuntimeUnavailableError, "installed unit artifact declarations differ"
          end
          roles = artifacts.group_by { |a| a.fetch("role") }
          required, allowed = if @context
            [CONTEXT_REQUIRED_ROLES, CONTEXT_ROLES]
          elsif @codex_service
            [CODEX_REQUIRED_ROLES, CODEX_ROLES]
          else
            [REQUIRED_ROLES, ROLES]
          end
          unless required.all? { |role| roles.key?(role) } && (roles.keys - allowed).empty? &&
              required.all? { |role| roles[role].size == 1 }
            raise RuntimeUnavailableError, "installed unit artifacts are incomplete or ambiguous"
          end
          artifacts.each do |artifact|
            path, digest = artifact.values_at("host_path", "sha256")
            unless path?(path) && path?(artifact["view_path"]) && digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/) && @files.sha256(path) == digest
              raise RuntimeUnavailableError, "installed unit artifact identity changed"
            end
          end
          return verify_context_artifacts!(roles) if @context
          return verify_codex_artifacts!(roles) if @codex_service
          expected = {"native_executable" => @native.fetch("executable"), "bootstrap" => @bootstrap,
            "worker_executable" => @worker_entry.fetch("wrapper").fetch("path"),
            "readiness_configuration" => "/etc/ace/execution-slots/#{@scope.fetch('slot_id')}/readiness.json",
            "boundary_manifest" => "/etc/ace/execution-slots/#{@scope.fetch('slot_id')}/boundary-manifest.json"}
          unless expected.all? { |role, path| roles.fetch(role).first.fetch("view_path") == path } &&
              roles.fetch("native_executable").first.fetch("sha256") == @native.fetch("executable_sha256") &&
              roles.fetch("boundary_manifest").first.fetch("sha256") == @scope.fetch("boundary_manifest_sha256")
            raise RuntimeUnavailableError, "installed executable declarations differ from deployment"
          end
          {"wrapper" => "worker_executable", "interpreter" => "runtime_dependency"}.each do |key, role|
            reference = @worker_entry.fetch(key)
            matches = roles.fetch(role).select { |artifact| artifact.fetch("view_path") == reference.fetch("path") }
            unless matches.size == 1 && matches.first.fetch("sha256") == reference.fetch("sha256")
              raise RuntimeUnavailableError, "installed worker entry role differs"
            end
            bytes = @files.read(matches.first.fetch("host_path"), limit: reference.fetch("bytes"))
            unless bytes.bytesize == reference.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == reference.fetch("sha256")
              raise RuntimeUnavailableError, "installed worker entry bytes differ"
            end
          end
          roles
        end

        def verify_context_artifacts!(roles)
          refs = {"context_executable" => @context.fetch("entry"), "interpreter" => @context.fetch("interpreter"),
            "bootstrap" => @context.fetch("bootstrap_manifest"), "boundary_manifest" => @context.fetch("boundary_manifest"),
            "context_configuration" => @context_configuration}
          refs.each do |role, ref|
            artifact = roles.fetch(role).first
            bytes = @files.read(artifact.fetch("host_path"), limit: ref.fetch("bytes"))
            unless artifact.fetch("host_path") == ref.fetch("path") && artifact.fetch("sha256") == ref.fetch("sha256") &&
                (!%w[bootstrap boundary_manifest context_configuration].include?(role) || artifact.fetch("view_path") == ref.fetch("path")) &&
                bytes.bytesize == ref.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == ref.fetch("sha256")
              raise RuntimeUnavailableError, "context host artifact differs from selected immutable reference"
            end
          end
          roles
        end

        def verify_profile!(profile, expected, artifacts)
          unless expected.is_a?(Hash) && expected.keys.sort == %w[service slice]
            raise RuntimeUnavailableError, "unit profile declarations differ"
          end
          environment = profile.fetch("manager_environment")
          unless environment.is_a?(Array) && environment.all? { |entry| entry.is_a?(String) &&
              MANAGER_ENVIRONMENT.include?(entry.split("=", 2).first) }
            raise RuntimeUnavailableError, "effective manager environment changes the fixed startup surface"
          end
          {"slice" => SystemdScopeManager::UNIT_GRAPH_SIGNATURES.keys,
           "service" => (SystemdScopeManager::UNIT_GRAPH_SIGNATURES.keys + SystemdScopeManager::SERVICE_EXEC_SIGNATURES.keys + (@context ? ["TimeoutStopUSec"] : [])).uniq}.each do |kind, keys|
            wanted, actual = expected.fetch(kind), profile.fetch(kind)
            projected = actual.dup
            %w[ExecStartEx ExecStartPostEx].each do |key|
              projected[key] = actual.fetch(key).map { |command| command.first(3) } if kind == "service"
            end
            unless wanted.is_a?(Hash) && wanted.keys.sort == keys.sort && projected == wanted &&
                actual["Id"] == @scope.fetch("#{kind}_unit") && actual["Names"] == [actual["Id"]] &&
                actual["LoadState"] == "loaded" && actual["NeedDaemonReload"] == false
              raise RuntimeUnavailableError, "effective installed unit properties differ"
            end
            fragment = artifacts.fetch("#{kind}_fragment").first.fetch("host_path")
            unless actual["FragmentPath"] == fragment && File.basename(fragment) == @scope.fetch("#{kind}_unit")
              raise RuntimeUnavailableError, "system manager loaded another unit fragment"
            end
            unless actual.fetch("DropInPaths").is_a?(Array) && actual.fetch("DropInPaths").all? { |path|
              artifacts.fetch("unit_dropin", []).any? { |artifact| artifact["host_path"] == path }
            }
              raise RuntimeUnavailableError, "system manager loaded an unverified drop-in"
            end
          end
          slice, service = profile.values_at("slice", "service")
          verify_graph!(slice, service, profile.fetch("ancestors"), profile.fetch("prerequisites"))
          unless @files.activation_routes(profile.fetch("unit_paths"), @scope.fetch("service_unit")).empty?
            raise RuntimeUnavailableError, "service has installed outside enablement or alias routes"
          end
          unless slice["StopWhenUnneeded"] == false && service["Sockets"] == [] &&
              service["RootDirectory"] == @scope.fetch("root_directory") &&
              service["NetworkNamespacePath"] == @scope.fetch("network_namespace_path") &&
              credential_id(service.fetch("User"), :uid) == @worker_uid &&
              credential_id(service.fetch("Group"), :gid) == @worker_gid &&
              SERVICE_REQUIRED.all? { |key, value| service[key] == value } &&
              service["SupplementaryGroups"] == (@context ? @context_groups.map(&:to_s) : @codex_service ? @codex_groups.map(&:to_s) : []) &&
              service["RestrictAddressFamilies"] == [true, %w[AF_INET AF_INET6 AF_UNIX]] &&
              EMPTY_EXEC.all? { |key| service[key] == [] }
            raise RuntimeUnavailableError, "execution unit lacks the required retained isolation profile"
          end
          if @context
            verify_context_protocol!(service, artifacts)
            verify_artifact_projection!(service, artifacts)
            verify_boundary_topology!(service, artifacts, authority: @context_authority)
            return
          end
          if @codex_service
            verify_codex_protocol!(service, artifacts)
            verify_artifact_projection!(service, artifacts)
            verify_boundary_topology!(service, artifacts, authority: @codex_authority)
            return
          end
          verify_command!(service.fetch("ExecStartEx"), artifacts.fetch("native_executable").first.fetch("view_path"))
          config_artifact = artifacts.fetch("readiness_configuration").first
          config = ReadinessConfiguration.decode(@files.read(config_artifact.fetch("host_path"), limit: 65_536),
            slot: @scope.fetch("slot_id"))
          interpreter = config.data.dig("runtime", "interpreter_path")
          unless artifacts.fetch("runtime_dependency", []).any? { |artifact| artifact.fetch("view_path") == interpreter }
            raise RuntimeUnavailableError, "readiness interpreter is not installed"
          end
          verify_command!(service.fetch("ExecStartPostEx"), interpreter)
          unless service.fetch("ExecStartEx").first[1] == [@native.fetch("executable"), "server"] &&
              service.fetch("ExecStartPostEx").first[1] == [interpreter, "--disable=gems,rubyopt",
                artifacts.fetch("readiness_executable").first.fetch("view_path"), @scope.fetch("slot_id")]
            raise RuntimeUnavailableError, "unit commands differ from the fixed native/readiness protocol"
          end
          environment = service.fetch("Environment")
          unless environment.is_a?(Array) && environment.all? { |entry| entry.is_a?(String) && !entry.include?("\0") } &&
              environment.all? { |entry| key, value = entry.split("=", 2); NATIVE_ENVIRONMENT.include?(key) && value && !value.empty? } &&
              environment.map { |entry| entry.split("=", 2).first }.uniq.size == environment.size &&
              environment.include?("HERDR_CONFIG_PATH=#{artifacts.fetch('native_configuration').first.fetch('view_path')}")
            raise RuntimeUnavailableError, "native configuration is not the exact immutable input"
          end
          verify_artifact_projection!(service, artifacts)
          verify_boundary_topology!(service, artifacts, authority: config.data.fetch("authority"))
        end

        def verify_context_protocol!(service, artifacts)
          interpreter = artifacts.fetch("interpreter").first.fetch("view_path")
          entry = artifacts.fetch("context_executable").first.fetch("view_path")
          verify_command!(service.fetch("ExecStartEx"), interpreter)
          arguments = [interpreter, "--disable=gems,rubyopt", *@context_load_paths.flat_map { |path| ["-I", path] }, entry]
          unless service.fetch("ExecStartEx").first[1] == arguments && service.fetch("ExecStartPostEx") == [] &&
              service.fetch("Environment") == [] && service.fetch("TimeoutStopUSec") == 35_000_000 &&
              @context_load_paths.all? { |path| artifacts.fetch("runtime_dependency", []).any? { |artifact| covers?(path, artifact.fetch("view_path")) } }
            raise RuntimeUnavailableError, "context commands differ from the fixed service protocol"
          end
        end

        def verify_graph!(slice, service, ancestors, prerequisites)
          unless ancestors.is_a?(Hash) && !ancestors.empty?
            raise RuntimeUnavailableError, "parent activation graph is incomplete"
          end
          parents = [slice, *ancestors.values]
          parents.each_with_index do |unit, index|
            parent = parents[index + 1]
            permitted = parent ? [parent.fetch("Id")] : []
            unless unit["LoadState"] == "loaded" && unit["NeedDaemonReload"] == false &&
                unit["Requires"] == permitted && unit["Wants"] == [] &&
                (EMPTY_ACTIVATION + %w[RequiresMountsFor WantsMountsFor]).all? { |key| unit[key] == [] }
              raise RuntimeUnavailableError, "parent activation graph could start outside its retained hierarchy"
            end
          end
          permitted_paths = [@scope.fetch("root_directory"), *service.fetch("RuntimeDirectory").map { |path| "/run/#{path}" }]
          unless prerequisites.is_a?(Hash) && prerequisites.all? { |unit, value|
            value["Id"] == unit && value["LoadState"] == "loaded" && value["ActiveState"] == "active" && value["Job"] == [0, "/"] &&
              (unit == "systemd-journald.socket" && value["SubState"] == "listening" ||
                unit.end_with?(".mount") && value["SubState"] == "mounted" && (value["Where"] == "/" || path?(value["Where"])) &&
                permitted_paths.any? { |path| covers?(value["Where"], path) })
          } && (service.values_at("Requires", "Wants", "After").flatten.uniq - [slice["Id"]]).sort == prerequisites.keys.sort &&
              service.values_at("Requires", "Wants").flatten.none? { |unit| unit == "systemd-journald.socket" }
            raise RuntimeUnavailableError, "implicit backing mounts/logging are not active exact prerequisites"
          end
          unless parents.last["Id"] == "-.slice" && service["Slice"] == slice["Id"] &&
              service["Requires"].include?(slice["Id"]) && service["After"].include?(slice["Id"]) &&
              service["WantsMountsFor"] == [@scope.fetch("root_directory")] &&
              service.fetch("RuntimeDirectory") == [@scope.fetch("runtime_directory").delete_prefix("/run/")] &&
              service["RequiresMountsFor"].sort == service.fetch("RuntimeDirectory").map { |path| "/run/#{path}" }.sort &&
              service["WorkingDirectory"] == (@codex_service ? @codex_intent.fetch("cwd") : "") && service["DefaultDependencies"] == false &&
              %w[RequiredBy RequisiteOf WantedBy BoundBy UpheldBy ConsistsOf].all? { |key| service[key] == [] } &&
              %w[disabled static].include?(service["UnitFileState"]) &&
              EMPTY_ACTIVATION.all? { |key| service[key] == [] }
            raise RuntimeUnavailableError, "service has outside activation or parent stop propagation"
          end
        end

        def verify_artifact_projection!(service, artifacts)
          writable = service.fetch("BindPaths")
          readonly = service.fetch("BindReadOnlyPaths")
          mounts = writable + readonly
          unless mounts.all? { |mount| path?(mount[0]) && path?(mount[1]) && mount[2] == false && mount[3] == 0 } &&
              mounts.map { |mount| mount[1] }.uniq.size == mounts.size
            raise RuntimeUnavailableError, "unit mount projection is ambiguous or optional"
          end
          artifacts.each do |role, entries|
            next if %w[slice_fragment service_fragment unit_dropin].include?(role)
            entries.each do |artifact|
              view = artifact.fetch("view_path")
              if IMPLICIT_NAMESPACE_ROOTS.any? { |root| covers?(root, view) } ||
                  service.fetch("ReadWritePaths").any? { |root| !path?(root) || covers?(root, view) }
                raise RuntimeUnavailableError, "immutable artifact is inside an implicit or writable namespace projection"
              end
              if writable.any? { |mount| overlaps?(view, mount[1]) }
                raise RuntimeUnavailableError, "immutable unit artifact has a writable overlay"
              end
              selected = readonly.select { |mount| covers?(mount[1], view) }.max_by { |mount| mount[1].length }
              relative = selected && view.delete_prefix(selected[1]).delete_prefix("/")
              host = selected ? (relative.empty? ? selected[0] : File.join(selected[0], relative)) : @scope.fetch("root_directory") + view
              unless artifact.fetch("host_path") == host
                raise RuntimeUnavailableError, "hashed artifact is shadowed by another effective unit mount"
              end
            end
          end
        end

        def verify_boundary_topology!(service, artifacts, authority:)
          validate_staged_boundary_topology!(service: service, artifacts: artifacts, authority: authority)
          @files.authority_socket!(authority)
        end

        def validate_boundary_topology!(service, artifacts, authority:)
          artifact = artifacts.fetch("boundary_manifest").first
          bytes = @files.read(artifact.fetch("host_path"), limit: 65_536).dup.force_encoding(Encoding::UTF_8)
          raise RuntimeUnavailableError, "boundary content is not UTF-8" unless bytes.valid_encoding?
          boundary = JSON.parse(bytes, create_additions: false, max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
          unless boundary.is_a?(Hash) && boundary.keys.sort == %w[network_installation resources schema slot_id] &&
              boundary["schema"] == "ace.execution-boundary-manifest/v1" && boundary["slot_id"] == @scope.fetch("slot_id") &&
              boundary["resources"].is_a?(Array) && boundary["resources"].size.between?(1, 64)
            raise RuntimeUnavailableError, "boundary lifecycle topology differs"
          end
          entries = boundary.fetch("resources")
          ExecutionNetworkSelection.validate_static!(boundary.fetch("network_installation"), slot_id: @scope.fetch("slot_id"))
          entries.each do |entry|
            unless entry.is_a?(Hash) && entry.keys.sort == %w[host_path read_only stage view_path worker_visible] &&
                path?(entry["host_path"]) && path?(entry["view_path"]) && %w[parent native].include?(entry["stage"]) &&
                [true, false].include?(entry["worker_visible"]) && [true, false].include?(entry["read_only"]) &&
                (entry["worker_visible"] || entry["stage"] == "parent" && entry["read_only"])
              raise RuntimeUnavailableError, "boundary resource declaration differs"
            end
          end
          unless entries.map { |entry| entry.values_at("host_path", "view_path") }.uniq.size == entries.size
            raise RuntimeUnavailableError, "boundary resource projections repeat"
          end
          projections = service.fetch("BindPaths").map { |mount| [mount[0], mount[1], false] } +
            service.fetch("BindReadOnlyPaths").map { |mount| [mount[0], mount[1], true] }
          socket = authority.fetch("socket_path")
          socket_projection = [socket, socket, true]
          socket_mounts = projections.select { |host, view, _| overlaps?(host, socket) || overlaps?(view, socket) }
          unless socket_mounts == [socket_projection]
            raise RuntimeUnavailableError, "authority socket has no unique exact readonly projection"
          end
          devpts = "/run/ace/execution-slots/#{@scope.fetch('slot_id')}/devpts"
          device_projections = @context ? [] : [[devpts, "/dev/pts", false], [devpts + "/ptmx", "/dev/pts/ptmx", true]]
          unless projections.select { |_host, view, _| overlaps?(view, "/dev/pts") } == device_projections
            raise RuntimeUnavailableError, "selected devpts has no exact root and ptmx projection"
          end
          api_roots = %w[/dev /proc /sys]
          if (projections - device_projections).any? { |_host, view, _| api_roots.any? { |root| overlaps?(root, view) } }
            raise RuntimeUnavailableError, "API namespace has an unsupported storage alias"
          end
          readonly_paths = service.fetch("ReadOnlyPaths")
          unless readonly_paths.all? { |path| path?(path) } &&
              %w[/dev /dev/shm].all? { |view| readonly_paths.any? { |path| covers?(path, view) } } &&
              !service.fetch("ReadWritePaths").any? { |path| !path?(path) || overlaps?(path, "/dev/shm") }
            raise RuntimeUnavailableError, "file-backed IPC is not positively read-only"
          end
          runtime = @scope.fetch("runtime_directory")
          projections << [runtime, runtime, false]
          service.fetch("ReadWritePaths").each do |view|
            unless path?(view) && api_roots.none? { |root| overlaps?(root, view) }
              raise RuntimeUnavailableError, "writable path directive is not exact"
            end
            projection = projections.select { |mount| covers?(mount[1], view) }.max_by { |mount| mount[1].length }
            host = projection ? File.join(projection[0], view.delete_prefix(projection[1]).delete_prefix("/")) :
              @scope.fetch("root_directory") + view
            projections << [host, view, false]
          end
          unless projections.select { |host, view, _| overlaps?(host, socket) || overlaps?(view, socket) } == [socket_projection]
            raise RuntimeUnavailableError, "authority socket is shadowed by an effective writable or parent projection"
          end
          projections.each do |host, view, readonly|
            next if [host, view, readonly] == socket_projection
            next if device_projections.include?([host, view, readonly])
            next if readonly && artifacts.values.flatten.any? { |entry| entry["host_path"] == host && entry["view_path"] == view }
            unless entries.any? { |entry| entry.values_at("host_path", "view_path", "worker_visible", "read_only") == [host, view, true, readonly] }
              raise RuntimeUnavailableError, "effective projection is omitted from boundary inventory"
            end
          end
          entries.each do |entry|
            view = entry.fetch("view_path")
            accessible = projections.any? { |host, target, _readonly| covers?(target, view) &&
              File.expand_path(File.join(host, view.delete_prefix(target).delete_prefix("/"))) == entry.fetch("host_path") } ||
              entry.fetch("host_path") == @scope.fetch("root_directory") + view
            if entry.fetch("worker_visible") != accessible
              raise RuntimeUnavailableError, "boundary visibility is not proven by installed topology"
            end
            if entry.fetch("stage") == "native" && !covers?(runtime, entry.fetch("host_path"))
              raise RuntimeUnavailableError, "service-created resource has no fixed creation directive"
            end
          end
        end

        def covers?(root, path) = root == path || root == "/" || path.start_with?(root + "/")
        def overlaps?(left, right) = covers?(left, right) || covers?(right, left)

        def verify_command!(value, executable)
          unless value.is_a?(Array) && value.size == 1 && value.first.is_a?(Array) && value.first.size == 10 &&
              value.first[0] == executable && value.first[1].is_a?(Array) && value.first[1].first == executable &&
              value.first[1].all? { |arg| arg.is_a?(String) && !arg.include?("\0") } && value.first[2] == [] &&
              value.first[3..].all? { |number| number.is_a?(Integer) }
            raise RuntimeUnavailableError, "unit command bypasses fixed unprivileged execution"
          end
        end

        def credential_id(value, kind)
          return Integer(value, 10) if value.match?(/\A[1-9][0-9]*\z/)
          kind == :uid ? Etc.getpwnam(value).uid : Etc.getgrnam(value).gid
        rescue ArgumentError
          raise RuntimeUnavailableError, "installed unit principal is unavailable"
        end

        def path?(value)
          value.is_a?(String) && value.bytesize.between?(2, 4096) && value.start_with?("/") &&
            !value.match?(/[\s\0;]/) && File.expand_path(value) == value
        end
      end
    end
  end
end
