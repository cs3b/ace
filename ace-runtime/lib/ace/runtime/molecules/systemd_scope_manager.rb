# frozen_string_literal: true

require_relative "protected_socket"
require "json"

module Ace
  module Runtime
    module Molecules
      # Fixed installed system-manager units only. This adapter does not decide
      # when a generation may start/stop: canonical lifecycle owns admission.
      class SystemdScopeManager
        SYSTEMCTL = "/usr/bin/systemctl"
        BUSCTL = "/usr/bin/busctl"
        UNIT = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        PROPERTIES = %w[Id LoadState ActiveState SubState InvocationID ControlGroup Job
          FragmentPath DropInPaths].freeze
        SERVICE_PROPERTIES = (PROPERTIES + %w[MainPID Slice]).freeze
        UNIT_GRAPH_SIGNATURES = {
          "Id" => "s", "Names" => "as", "LoadState" => "s", "FragmentPath" => "s", "DropInPaths" => "as",
          "UnitFileState" => "s", "NeedDaemonReload" => "b", "StopWhenUnneeded" => "b", "DefaultDependencies" => "b",
          **%w[Requires Requisite Wants BindsTo PartOf Upholds RequiredBy RequisiteOf WantedBy BoundBy UpheldBy
            ConsistsOf After Before OnSuccess OnSuccessOf OnFailure OnFailureOf Triggers TriggeredBy
            PropagatesStopTo StopPropagatedFrom JoinsNamespaceOf RequiresMountsFor WantsMountsFor].to_h { |key| [key, "as"] }
        }.freeze
        SERVICE_EXEC_SIGNATURES = {
          **%w[Type User Group Restart KillMode ProtectSystem RootDirectory RootImage NetworkNamespacePath Slice StandardInput TTYPath StandardOutput StandardError WorkingDirectory RuntimeDirectoryPreserve DevicePolicy PAMName].to_h { |key| [key, "s"] },
          **%w[SupplementaryGroups ReadWritePaths ReadOnlyPaths Environment PassEnvironment UnsetEnvironment Sockets InaccessiblePaths ExtensionDirectories RuntimeDirectory].to_h { |key| [key, "as"] },
          **%w[SendSIGKILL Delegate ProtectControlGroups NoNewPrivileges PrivateIPC PrivateDevices DynamicUser RootEphemeral MountAPIVFS PrivateTmp ProtectKernelTunables BindLogSockets].to_h { |key| [key, "b"] },
          **%w[CapabilityBoundingSet AmbientCapabilities RestrictNamespaces].to_h { |key| [key, "t"] },
          "RuntimeDirectoryMode" => "u", "UMask" => "u", "RootImageOptions" => "a(ss)", "TemporaryFileSystem" => "a(ss)", "MountImages" => "a(ssba(ss))",
          "ExtensionImages" => "a(sba(ss))", "EnvironmentFiles" => "a(sb)", "RestartForceExitStatus" => "(aiai)", "RestrictAddressFamilies" => "(bas)",
          "DeviceAllow" => "a(ss)", "BindPaths" => "a(ssbt)", "BindReadOnlyPaths" => "a(ssbt)",
          **%w[ExecConditionEx ExecStartPreEx ExecStartEx ExecStartPostEx ExecReloadEx ExecStopEx ExecStopPostEx].to_h { |key| [key, "a(sasasttttuii)"] }
        }.freeze

        UNIT_STATE_SIGNATURES = {"Id" => "s", "LoadState" => "s", "ActiveState" => "s", "SubState" => "s", "Job" => "(uo)"}.freeze
        MOUNT_SIGNATURES = {"Where" => "s"}.freeze
        ACTIVATION_UNIT_SIGNATURES = UNIT_STATE_SIGNATURES.merge("InvocationID" => "ay", "ControlGroup" => "s").freeze
        ACTIVATION_SERVICE_SIGNATURES = {"MainPID" => "u", "ControlPID" => "u", "Slice" => "s"}.freeze
        INBOX_CONTEXT_SIGNATURES = {"TimeoutStopUSec" => "t"}.freeze

        PIDFD_ARGV = [BUSCTL, "--system", "--no-pager", "--json=short", "--auto-start=no",
          "--allow-interactive-authorization=no", "--timeout=5", "call", "org.freedesktop.systemd1",
          "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager", "GetUnitByPIDFD", "h", "3"].freeze

        class Command
          LIMIT = 65_536

          def call(argv, timeout:, pidfd: nil)
            inherited = inherited_descriptor_options(argv, pidfd)
            unless RUBY_PLATFORM.include?("linux") && File.directory?("/run/systemd/system")
              raise RuntimeUnavailableError, "execution scope requires the Linux system systemd manager"
            end
            client = argv.first
            unless [SYSTEMCTL, BUSCTL].include?(client)
              raise RuntimeUnavailableError, "system manager client is not fixed"
            end
            ProtectedSocket.root_path!(client)
            unless File.executable?(client) && (File.stat(client).mode & 0o6000).zero?
              raise RuntimeUnavailableError, "installed system manager client is unsafe"
            end
            output_reader, output_writer = IO.pipe
            error_reader, error_writer = IO.pipe
            pid = Process.spawn({"PATH" => "/usr/bin:/bin", "LANG" => "C", "LC_ALL" => "C"}, *argv,
              in: File::NULL, out: output_writer, err: error_writer, unsetenv_others: true, close_others: true, **inherited)
            output_writer.close
            error_writer.close
            deadline = ProtectedSocket.deadline(timeout)
            readers = [output_reader, error_reader]
            bytes = {output_reader => +"", error_reader => +""}
            until readers.empty?
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              ready = remaining.positive? && IO.select(readers, nil, nil, remaining)
              raise RuntimeUnavailableError, "system manager job outcome is unavailable" unless ready
              ready.first.each do |reader|
                chunk = reader.read_nonblock(4096, exception: false)
                next if chunk == :wait_readable
                if chunk.nil?
                  readers.delete(reader)
                else
                  bytes.fetch(reader) << chunk
                  if bytes.values.sum(&:bytesize) > LIMIT
                    raise RuntimeUnavailableError, "system manager response is oversized"
                  end
                end
              end
            end
            loop do
              waited = Process.waitpid(pid, Process::WNOHANG)
              if waited
                status = $?
                pid = nil
                raise RuntimeUnavailableError, "fixed system manager operation was refused" unless status.success?
                return bytes.fetch(output_reader)
              end
              unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
                raise RuntimeUnavailableError, "system manager job outcome is unavailable"
              end
              sleep 0.01
            end
          rescue SystemCallError, IOError
            raise RuntimeUnavailableError, "system manager operation is unavailable"
          ensure
            [output_reader, output_writer, error_reader, error_writer].compact.each do |stream|
              stream.close unless stream.closed?
            end
            if pid
              begin
                Process.kill("KILL", pid)
              rescue Errno::ESRCH
                nil
              ensure
                begin
                  Process.waitpid(pid)
                rescue Errno::ECHILD
                  nil
                end
              end
            end
          end
          private

          def inherited_descriptor_options(argv, pidfd)
            return {} unless pidfd || argv == PIDFD_ARGV
            unless argv == PIDFD_ARGV && pidfd.is_a?(IO) && !pidfd.closed? && pidfd.fileno >= 3
              raise ArgumentError, "pidfd transport requires the fixed manager method and held IO"
            end
            {3 => pidfd}
          end
        end

        def initialize(slice_unit:, service_unit:, command: Command.new)
          unless slice_unit.is_a?(String) && service_unit.is_a?(String) &&
              UNIT.match?(slice_unit) && UNIT.match?(service_unit) &&
              slice_unit.end_with?(".slice") && service_unit.end_with?(".service") &&
              !%w[system.slice user.slice machine.slice].include?(slice_unit)
            raise ArgumentError, "execution scope requires fixed dedicated slice/service units"
          end
          @slice_unit, @service_unit, @command = slice_unit, service_unit, command
          @slice_ancestors = []
          parent = slice_unit
          loop do
            stem = parent.delete_suffix(".slice")
            parent = stem.include?("-") ? stem.rpartition("-").first + ".slice" : "-.slice"
            @slice_ancestors << parent
            break if parent == "-.slice"
          end
        end

        # The root identity owner supplies its already policy-checked pinned
        # lifetime. A wire descriptor number never selects this capability.
        def unit_for_pidfd(handle:, timeout: 5)
          unless handle.is_a?(IO) && !handle.closed?
            raise ArgumentError, "manager identity requires a held process lifetime"
          end
          bytes = @command.call(PIDFD_ARGV, timeout: bounded_timeout(timeout), pidfd: handle)
          value = strict_typed_json(bytes)
          data = value["data"]
          unless value.keys.sort == %w[data type] && value["type"] == "osay" &&
              data.is_a?(Array) && data.size == 3 && data[0] == unit_object(@service_unit) &&
              data[1] == @service_unit && invocation_bytes?(data[2]) && data[2].any?(&:positive?)
            raise RuntimeUnavailableError, "manager lifetime belongs to another unit or invocation"
          end
          {"unit" => @service_unit, "invocation_id" => data[2].pack("C*").unpack1("H*")}.freeze
        rescue JSON::ParserError, KeyError, TypeError
          raise RuntimeUnavailableError, "typed manager lifetime response is malformed"
        end

        def inspect_units
          slice = show(@slice_unit)
          service = show(@service_unit, properties: SERVICE_PROPERTIES)
          unless slice["LoadState"] == "loaded" && service["LoadState"] == "loaded" &&
              service["Slice"] == @slice_unit
            raise RuntimeUnavailableError, "fixed execution units are missing or their placement changed"
          end
          {"slice" => slice, "service" => service}
        end

        def start_slice
          operate("start", @slice_unit)
        end

        def inspect_activation
          inspect_units
          slice = typed_properties(unit: @slice_unit, interface: "Unit", signatures: ACTIVATION_UNIT_SIGNATURES)
          service = typed_properties(unit: @service_unit, interface: "Unit", signatures: ACTIVATION_UNIT_SIGNATURES)
          service.merge!(typed_properties(unit: @service_unit, interface: "Service", signatures: ACTIVATION_SERVICE_SIGNATURES))
          unless slice.fetch("Id") == @slice_unit && service.fetch("Id") == @service_unit &&
              slice.fetch("LoadState") == "loaded" && service.fetch("LoadState") == "loaded" && service.fetch("Slice") == @slice_unit
            raise RuntimeUnavailableError, "fixed activation escaped its parent slice"
          end
          {"slice" => slice, "service" => service}
        end

        def inspect_profile
          # `show` loads installed metadata before typed reads; it starts no unit.
          inspect_units
          slice = typed_properties(unit: @slice_unit, interface: "Unit", signatures: UNIT_GRAPH_SIGNATURES)
          service = typed_properties(unit: @service_unit, interface: "Unit", signatures: UNIT_GRAPH_SIGNATURES).merge(
            typed_properties(unit: @service_unit, interface: "Service", signatures: SERVICE_EXEC_SIGNATURES))
          ancestors = @slice_ancestors.to_h do |unit|
            show(unit)
            [unit, typed_properties(unit: unit, interface: "Unit", signatures: UNIT_GRAPH_SIGNATURES)]
          end
          {"slice" => slice, "service" => service, "ancestors" => ancestors, "unit_paths" => unit_paths,
            "manager_environment" => manager_environment, "prerequisites" => inspect_prerequisites(service)}
        end

        def inspect_inbox_context_profile
          profile = inspect_profile
          profile.fetch("service").merge!(typed_properties(unit: @service_unit, interface: "Service",
            signatures: INBOX_CONTEXT_SIGNATURES))
          profile
        end

        def manager_environment(timeout: 5)
          bytes = @command.call([BUSCTL, "--system", "--no-pager", "--json=short", "--auto-start=no",
            "--allow-interactive-authorization=no", "get-property", "org.freedesktop.systemd1",
            "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager", "Environment"], timeout: bounded_timeout(timeout))
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 65_536) && bytes.lines.size == 1
            raise RuntimeUnavailableError, "effective manager environment is unavailable"
          end
          value = JSON.parse(bytes, create_additions: false, allow_duplicate_key: false, allow_comments: false, max_nesting: 4)
          unless value.is_a?(Hash) && value.keys.sort == %w[data type] && value["type"] == "as" &&
              value["data"].is_a?(Array) && value["data"].size <= 256 &&
              value["data"].all? { |entry| entry.is_a?(String) && entry.bytesize.between?(1, 4096) && !entry.include?("\0") && entry.match?(/\A[A-Za-z_][A-Za-z_0-9]*=.*\z/) } &&
              value["data"].map { |entry| entry.split("=", 2).first }.uniq.size == value["data"].size
            raise RuntimeUnavailableError, "effective manager environment differs"
          end
          value.fetch("data")
        rescue JSON::ParserError, ArgumentError
          raise RuntimeUnavailableError, "effective manager environment is malformed"
        end

        def unit_paths
          bytes = @command.call([BUSCTL, "--system", "--no-pager", "--json=short", "--auto-start=no",
            "--allow-interactive-authorization=no", "get-property", "org.freedesktop.systemd1",
            "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager", "UnitPath"], timeout: 5)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Command::LIMIT) && bytes.lines.size == 1
            raise RuntimeUnavailableError, "system manager lookup paths are unavailable"
          end
          value = JSON.parse(bytes)
          unless value.is_a?(Hash) && value.keys.sort == %w[data type] && value["type"] == "as" &&
              value["data"].is_a?(Array) && value["data"].size.between?(1, 64) &&
              value["data"].all? { |path| path.is_a?(String) && path.start_with?("/") && !path.include?("\0") && File.expand_path(path) == path }
            raise RuntimeUnavailableError, "system manager lookup paths differ"
          end
          value.fetch("data")
        rescue JSON::ParserError, KeyError
          raise RuntimeUnavailableError, "system manager lookup paths are malformed"
        end

        # Typed reads only, against the existing system manager. Property sets
        # and unit identities are owner-selected, never request-controlled.
        def typed_properties(unit:, interface:, signatures:, timeout: 5)
          unless [@slice_unit, @service_unit, *@slice_ancestors, *@prerequisite_units.to_a].include?(unit) &&
              %w[Unit Service Mount].include?(interface) && (interface == "Unit" || interface == "Service" && unit == @service_unit || interface == "Mount" && @prerequisite_units.to_a.include?(unit) && unit.end_with?(".mount")) && signatures.is_a?(Hash) &&
              signatures.all? { |key, value|
                allowed = case interface
                when "Unit" then UNIT_GRAPH_SIGNATURES.merge(ACTIVATION_UNIT_SIGNATURES)
                when "Service" then SERVICE_EXEC_SIGNATURES.merge(ACTIVATION_SERVICE_SIGNATURES).merge(INBOX_CONTEXT_SIGNATURES)
                when "Mount" then MOUNT_SIGNATURES
                end
                allowed[key] == value
              } && !signatures.empty?
            raise ArgumentError, "typed inspection requires fixed unit properties"
          end
          object = unit_object(unit)
          bytes = @command.call([BUSCTL, "--system", "--no-pager", "--json=short", "--auto-start=no",
            "--allow-interactive-authorization=no", "get-property", "org.freedesktop.systemd1", object,
            "org.freedesktop.systemd1.#{interface}", *signatures.keys], timeout: bounded_timeout(timeout))
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Command::LIMIT)
            raise RuntimeUnavailableError, "typed manager properties are unavailable"
          end
          lines = bytes.lines
          unless lines.size == signatures.size
            raise RuntimeUnavailableError, "typed manager property set is incomplete"
          end
          signatures.to_a.zip(lines).to_h do |(key, signature), line|
            value = strict_typed_json(line)
            unless value.is_a?(Hash) && value.keys.sort == %w[data type] && value["type"] == signature && typed_value?(signature, value["data"])
              raise RuntimeUnavailableError, "typed manager property signature differs"
            end
            [key, key == "InvocationID" ? value.fetch("data").pack("C*").unpack1("H*") : value.fetch("data")]
          end
        rescue JSON::ParserError, KeyError
          raise RuntimeUnavailableError, "typed manager properties are malformed"
        end

        def start_service
          operate("start", @service_unit, timeout: 45)
        end

        def stop_slice
          operate("stop", @slice_unit)
        end

        def stop_service
          operate("stop", @service_unit)
        end

        private

        def inspect_prerequisites(service)
          @prerequisite_units = service.values_at("Requires", "Wants", "After").flatten.uniq - [@slice_unit]
          unless @prerequisite_units.all? { |unit| unit == "systemd-journald.socket" ||
              unit.is_a?(String) && unit.bytesize.between?(7, 255) && unit.end_with?(".mount") && !unit.match?(/[\s\/\0]/) }
            raise RuntimeUnavailableError, "execution service has an unverified implicit prerequisite"
          end
          @prerequisite_units.to_h do |unit|
            value = typed_properties(unit: unit, interface: "Unit", signatures: UNIT_STATE_SIGNATURES)
            value.merge!(typed_properties(unit: unit, interface: "Mount", signatures: MOUNT_SIGNATURES)) if unit.end_with?(".mount")
            [unit, value]
          end
        end

        def bounded_timeout(value)
          unless value.is_a?(Numeric) && value.finite? && value.positive? && value <= 5
            raise ArgumentError, "manager observation deadline exceeds its fixed budget"
          end
          value
        end

        def unit_object(unit)
          "/org/freedesktop/systemd1/unit/" + unit.bytes.map { |byte|
            ((byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || (byte >= 48 && byte <= 57)) ? byte.chr : "_%02x" % byte
          }.join
        end

        def strict_typed_json(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Command::LIMIT) &&
              bytes.dup.force_encoding(Encoding::UTF_8).valid_encoding?
            raise RuntimeUnavailableError, "typed manager response is unavailable"
          end
          value = JSON.parse(bytes, create_additions: false, max_nesting: 32,
            allow_duplicate_key: false, allow_comments: false)
          raise RuntimeUnavailableError, "typed manager response is malformed" unless value.is_a?(Hash)
          value
        end

        def invocation_bytes?(value)
          value.is_a?(Array) && value.size == 16 && value.all? { |byte| byte.is_a?(Integer) && byte.between?(0, 255) }
        end

        def typed_value?(signature, value)
          string = ->(item) { item.is_a?(String) && !item.include?("\0") }
          unsigned = ->(item, bits) { item.is_a?(Integer) && item >= 0 && item < (1 << bits) }
          signed = ->(item) { item.is_a?(Integer) && item >= -(1 << 31) && item < (1 << 31) }
          strings = ->(items) { items.is_a?(Array) && items.all? { |item| string.call(item) } }
          case signature
          when "ay" then invocation_bytes?(value)
          when "s" then string.call(value)
          when "(uo)" then value.is_a?(Array) && value.size == 2 && unsigned.call(value.first, 32) && string.call(value.last) && value.last.start_with?("/")
          when "a(ss)"
            value.is_a?(Array) && value.all? { |item| item.is_a?(Array) && item.size == 2 && item.all? { |part| string.call(part) } }
          when "a(ssba(ss))", "a(sba(ss))"
            strings_count = signature == "a(ssba(ss))" ? 2 : 1
            value.is_a?(Array) && value.all? { |item| item.is_a?(Array) && item.size == strings_count + 2 &&
              item.first(strings_count).all? { |part| string.call(part) } && [true, false].include?(item[strings_count]) &&
              typed_value?("a(ss)", item.last) }
          when "b" then value == true || value == false
          when "t" then unsigned.call(value, 64)
          when "u" then unsigned.call(value, 32)
          when "as" then strings.call(value)
          when "(aiai)"
            value.is_a?(Array) && value.size == 2 && value.all? { |items| items.is_a?(Array) && items.all? { |item| signed.call(item) } }
          when "(bas)"
            value.is_a?(Array) && value.size == 2 && [true, false].include?(value.first) && strings.call(value.last)
          when "a(sb)"
            value.is_a?(Array) && value.all? { |item| item.is_a?(Array) && item.size == 2 && string.call(item.first) && [true, false].include?(item.last) }
          when "a(ssbt)"
            value.is_a?(Array) && value.all? { |item| item.is_a?(Array) && item.size == 4 &&
              string.call(item[0]) && string.call(item[1]) && [true, false].include?(item[2]) && unsigned.call(item[3], 64) }
          when "a(sasasttttuii)"
            value.is_a?(Array) && value.all? { |item| item.is_a?(Array) && item.size == 10 &&
              string.call(item[0]) && strings.call(item[1]) && strings.call(item[2]) &&
              item[3..6].all? { |number| unsigned.call(number, 64) } && unsigned.call(item[7], 32) &&
              signed.call(item[8]) && signed.call(item[9]) }
          else false
          end
        end

        def operate(verb, unit, timeout: 30)
          @command.call([SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", verb, "--", unit], timeout: timeout)
          true
        end

        def show(unit, properties: PROPERTIES)
          bytes = @command.call([SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", "show",
            "--all", "--property=#{properties.join(',')}", "--", unit], timeout: 5)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Command::LIMIT)
            raise RuntimeUnavailableError, "fixed unit properties are unavailable"
          end
          expected = properties
          properties = {}
          bytes.each_line do |line|
            key, value = line.chomp.split("=", 2)
            unless expected.include?(key) && value && !properties.key?(key) && !value.include?("\0")
              raise RuntimeUnavailableError, "fixed unit property response is malformed"
            end
            properties[key] = value
          end
          unless properties.keys.sort == expected.sort && properties["Id"] == unit
            raise RuntimeUnavailableError, "fixed system manager unit identity differs"
          end
          properties
        end
      end
    end
  end
end
