# frozen_string_literal: true

require "ace/runtime/molecules/execution_unit_installation"
require "ace/runtime/molecules/cgroup_observation"
require "ace/runtime/molecules/protected_linux"
require_relative "inbox_context_service_configuration"

module Ace
  module Herdr
    module Molecules
      # An epoch is an observed service incarnation, not a caller grant. The
      # full effective unit is verified before and after the pinned observation.
      class InboxContextLifetime
        EPOCH_FIELDS = %w[boot_id cgroup_identity installation_sha256 process_identity schema service_invocation_id service_unit].freeze
        UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
        class KernelFiles
          def boot_id
            bytes = File.read("/proc/sys/kernel/random/boot_id", 128).strip
            unless bytes.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
              raise ValidationError, "context boot identity is unavailable"
            end
            bytes
          rescue SystemCallError, IOError
            raise ValidationError, "context boot identity is unavailable"
          end
        end

        attr_reader :epoch

        # Persisted shape validation alone never establishes stopped writers.
        def self.validate_epoch!(epoch)
          unless epoch.is_a?(Hash) && epoch.keys.sort == EPOCH_FIELDS && epoch["schema"] == "ace.herdr.inbox-owner-epoch/v1" &&
              epoch["installation_sha256"].is_a?(String) && epoch["installation_sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              epoch["boot_id"].is_a?(String) && UUID.match?(epoch["boot_id"]) &&
              epoch["service_invocation_id"].is_a?(String) && epoch["service_invocation_id"].match?(/\A[0-9a-f]{32}\z/) &&
              epoch["service_unit"].is_a?(String) && epoch["service_unit"].match?(/\A[A-Za-z0-9_.@-]+\.service\z/)
            raise ValidationError, "context epoch fields differ"
          end
          process = epoch.fetch("process_identity")
          unless process.is_a?(Hash) && process.keys.sort == %w[gid groups host parent_pid pid started_at uid] &&
              process.values_at("pid", "parent_pid").all? { |value| value.is_a?(Integer) && value.between?(1, (1 << 31) - 1) } &&
              process.values_at("uid", "gid").all? { |value| value.is_a?(Integer) && value.between?(1, InboxContextServiceConfiguration::MAX_ID) } &&
              process["groups"].is_a?(Array) && process["groups"].size <= 64 && process["groups"] == process["groups"].sort.uniq &&
              process["groups"].all? { |value| value.is_a?(Integer) && value.between?(0, InboxContextServiceConfiguration::MAX_ID) } &&
              process["host"].is_a?(String) && process["host"].bytesize.between?(1, 255) &&
              process["started_at"].is_a?(String) && process["started_at"].match?(/\Alinux:#{Regexp.escape(epoch.fetch('boot_id'))}:[1-9][0-9]*\z/)
            raise ValidationError, "context epoch process differs"
          end
          cgroup = epoch.fetch("cgroup_identity")
          root = Ace::Runtime::Molecules::CgroupObservation::ROOT
          unless cgroup.is_a?(Hash) && cgroup.keys.sort == %w[device filesystem_type inode mount_id path] &&
              cgroup["filesystem_type"] == "cgroup2" && cgroup["path"].is_a?(String) &&
              cgroup["path"].bytesize <= 4096 && !cgroup["path"].match?(/[\s\0]/) && cgroup["path"].start_with?(root + "/") &&
              File.expand_path(cgroup["path"]) == cgroup["path"] &&
              cgroup.values_at("device", "inode", "mount_id").all? { |value| value.is_a?(Integer) && value.between?(0, (1 << 64) - 1) } &&
              JSON.generate(epoch).bytesize <= 4096
            raise ValidationError, "context epoch scope differs"
          end
          true
        rescue KeyError, TypeError, ArgumentError
          raise ValidationError, "context epoch is malformed"
        end

        def initialize(installation:, manager:, configuration:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new,
          cgroups: Ace::Runtime::Molecules::CgroupObservation.new, files: KernelFiles.new)
          unless installation.is_a?(Ace::Runtime::Molecules::ExecutionUnitInstallation) &&
              configuration.is_a?(InboxContextServiceConfiguration)
            raise ValidationError, "context lifetime selection is not held"
          end
          @installation, @manager, @configuration, @kernel, @cgroups, @files = installation, manager, configuration, kernel, cgroups, files
          unless installation.inbox_context_configuration_reference == configuration.reference
            raise ValidationError, "context lifetime configuration association differs"
          end
        end

        def capture_epoch!
          raise ValidationError, "context epoch is already observed" if @epoch
          scope = @installation.inbox_context_scope
          @installation.verify!(manager: @manager)
          boot = @files.boot_id
          before = @manager.inspect_activation.fetch("service")
          peer = @kernel.capture(Process.pid)
          unless peer.values_at("uid", "gid", "groups") == @configuration.data.fetch("owner_credentials").values_at("uid", "gid", "groups") &&
              before.fetch("Id") == scope.fetch("service_unit") && before.fetch("MainPID") == Process.pid &&
              before.fetch("ControlPID").zero? && before.fetch("Job") == [0, "/"] &&
              before.fetch("ActiveState") == "active" && before.fetch("SubState") == "running" &&
              before.fetch("InvocationID").is_a?(String) && before.fetch("InvocationID").match?(/\A[0-9a-f]{32}\z/)
            raise ValidationError, "context service incarnation differs"
          end
          path = Ace::Runtime::Molecules::CgroupObservation::ROOT + before.fetch("ControlGroup")
          pinned = @cgroups.pin(path)
          @cgroups.member!(peer, pinned: pinned, kernel: @kernel)
          unless @cgroups.observe(pinned).fetch("populated") == 1 && @kernel.same?(peer, @kernel.capture(Process.pid)) &&
              @manager.inspect_activation.fetch("service") == before && @files.boot_id == boot
            raise ValidationError, "context service observation changed"
          end
          @installation.verify!(manager: @manager)
          observed = {"schema" => "ace.herdr.inbox-owner-epoch/v1", "installation_sha256" => scope.fetch("unit_manifest_sha256"),
            "boot_id" => boot, "service_unit" => scope.fetch("service_unit"), "service_invocation_id" => before.fetch("InvocationID"),
            "cgroup_identity" => pinned.fetch(:identity), "process_identity" => peer}
          self.class.validate_epoch!(observed)
          @epoch = immutable(observed)
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          raise ValidationError, "context service epoch is unavailable"
        ensure
          pinned&.fetch(:handle)&.close
        end

        private

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
