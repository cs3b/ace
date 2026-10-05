# frozen_string_literal: true

require "json"
require "digest"
require "etc"
require_relative "systemd_scope_manager"

module Ace
  module Runtime
    module Molecules
      # Root-installed artifacts plus the system manager's effective properties.
      # These establish installation identity, not effective runtime isolation;
      # the same-User readiness action and live owner verify that separately.
      class ExecutionUnitInstallation
        SCHEMA = "ace.execution-unit-manifest/v1"
        ROLES = %w[slice_fragment service_fragment unit_dropin native_executable native_configuration
          readiness_executable bootstrap worker_executable runtime_dependency].freeze
        REQUIRED_ROLES = %w[slice_fragment service_fragment native_executable native_configuration
          readiness_executable bootstrap worker_executable].freeze
        SERVICE_REQUIRED = {"Type" => "exec", "Restart" => "no", "RestartForceExitStatus" => [[], []],
          "KillMode" => "control-group", "SendSIGKILL" => true, "Delegate" => false,
          "ProtectControlGroups" => true, "NoNewPrivileges" => true, "CapabilityBoundingSet" => 0,
          "AmbientCapabilities" => 0, "RestrictNamespaces" => 0, "PrivateIPC" => true,
          "PrivateDevices" => true, "ProtectSystem" => "strict", "DynamicUser" => false,
          "EnvironmentFiles" => [], "PassEnvironment" => [], "UnsetEnvironment" => [],
          "StandardOutput" => "journal", "StandardError" => "journal", "RuntimeDirectoryPreserve" => "no",
          "RuntimeDirectoryMode" => 0o700, "UMask" => 0o077, "RootImage" => "", "RootImageOptions" => [], "RootEphemeral" => false, "ExtensionDirectories" => [],
          "ExtensionImages" => [], "MountImages" => [], "TemporaryFileSystem" => [], "InaccessiblePaths" => []}.freeze
        EMPTY_ACTIVATION = %w[Requisite BindsTo PartOf Upholds OnFailure OnSuccess OnFailureOf OnSuccessOf
          TriggeredBy Triggers PropagatesStopTo StopPropagatedFrom JoinsNamespaceOf].freeze
        NATIVE_ENVIRONMENT = %w[HERDR_CONFIG_PATH HERDR_SOCKET_PATH HOME SHELL PATH LANG LC_ALL TERM
          TMPDIR TMP TEMP XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_RUNTIME_DIR CODEX_HOME CLAUDE_CONFIG_DIR].freeze
        EMPTY_EXEC = %w[ExecConditionEx ExecStartPreEx ExecReloadEx ExecStopEx ExecStopPostEx].freeze

        class Files
          def read(path, limit:)
            ProtectedSocket.root_path!(path)
            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              stat = file.stat
              unless stat.file? && stat.uid.zero? && (stat.mode & 0o022).zero?
                raise RuntimeUnavailableError, "installed artifact descriptor ownership is unsafe"
              end
              bytes = file.read(limit + 1)
              raise RuntimeUnavailableError, "installed artifact is oversized" if bytes.bytesize > limit
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

        def initialize(scope:, native:, bootstrap:, worker_executable:, worker_uid:, worker_gid:, files: Files.new)
          @scope, @native, @bootstrap, @worker_executable, @files = scope, native, bootstrap, worker_executable, files
          @worker_uid, @worker_gid = worker_uid, worker_gid
        end

        def verify!(manager:)
          slot = @scope.fetch("slot_id")
          unless slot.is_a?(String) && SystemdScopeManager::UNIT.match?(slot)
            raise RuntimeUnavailableError, "installed slot identity is invalid"
          end
          bytes = @files.read("/etc/ace/execution-slots/#{slot}/unit-manifest.json", limit: 65_536)
          unless Digest::SHA256.hexdigest(bytes) == @scope.fetch("unit_manifest_sha256")
            raise RuntimeUnavailableError, "unit manifest bytes differ from deployment"
          end
          manifest = JSON.parse(bytes)
          unless manifest.is_a?(Hash) && manifest.keys.sort == %w[artifacts properties schema slot_id] &&
              manifest["schema"] == SCHEMA && manifest["slot_id"] == slot
            raise RuntimeUnavailableError, "unit manifest schema/slot differs"
          end
          artifacts = verify_artifacts!(manifest.fetch("artifacts"))
          profile = manager.inspect_profile
          verify_profile!(profile, manifest.fetch("properties"), artifacts)
          manifest
        rescue SystemCallError, IOError, JSON::ParserError, KeyError, TypeError, NoMethodError
          raise RuntimeUnavailableError, "installed execution units cannot be verified"
        end

        private

        def verify_artifacts!(artifacts)
          unless artifacts.is_a?(Array) && artifacts.size.between?(7, 512) &&
              artifacts.all? { |a| a.is_a?(Hash) && a.keys.sort == %w[host_path role sha256 view_path] } &&
              artifacts.map { |a| a["host_path"] }.uniq.size == artifacts.size
            raise RuntimeUnavailableError, "installed unit artifact declarations differ"
          end
          roles = artifacts.group_by { |a| a.fetch("role") }
          unless REQUIRED_ROLES.all? { |role| roles.key?(role) } && (roles.keys - ROLES).empty? &&
              %w[slice_fragment service_fragment native_executable native_configuration readiness_executable bootstrap worker_executable].all? { |role| roles[role].size == 1 }
            raise RuntimeUnavailableError, "installed unit artifacts are incomplete or ambiguous"
          end
          artifacts.each do |artifact|
            path, digest = artifact.values_at("host_path", "sha256")
            unless path?(path) && path?(artifact["view_path"]) && digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/) && @files.sha256(path) == digest
              raise RuntimeUnavailableError, "installed unit artifact identity changed"
            end
          end
          expected = {"native_executable" => @native.fetch("executable"), "bootstrap" => @bootstrap,
            "worker_executable" => @worker_executable}
          unless expected.all? { |role, path| roles.fetch(role).first.fetch("view_path") == path } &&
              roles.fetch("native_executable").first.fetch("sha256") == @native.fetch("executable_sha256")
            raise RuntimeUnavailableError, "installed executable declarations differ from deployment"
          end
          roles
        end

        def verify_profile!(profile, expected, artifacts)
          unless expected.is_a?(Hash) && expected.keys.sort == %w[service slice]
            raise RuntimeUnavailableError, "unit profile declarations differ"
          end
          {"slice" => SystemdScopeManager::UNIT_GRAPH_SIGNATURES.keys,
           "service" => (SystemdScopeManager::UNIT_GRAPH_SIGNATURES.keys + SystemdScopeManager::SERVICE_EXEC_SIGNATURES.keys).uniq}.each do |kind, keys|
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
              service["SupplementaryGroups"] == [] &&
              service["RestrictAddressFamilies"] == [true, %w[AF_INET AF_INET6 AF_UNIX]] &&
              EMPTY_EXEC.all? { |key| service[key] == [] }
            raise RuntimeUnavailableError, "execution unit lacks the required retained isolation profile"
          end
          verify_command!(service.fetch("ExecStartEx"), artifacts.fetch("native_executable").first.fetch("view_path"))
          verify_command!(service.fetch("ExecStartPostEx"), artifacts.fetch("readiness_executable").first.fetch("view_path"))
          unless service.fetch("ExecStartEx").first[1] == [@native.fetch("executable"), "server"] &&
              service.fetch("ExecStartPostEx").first[1] == [artifacts.fetch("readiness_executable").first.fetch("view_path"), @scope.fetch("slot_id")]
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
              service["WorkingDirectory"] == "" && service["DefaultDependencies"] == false &&
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
