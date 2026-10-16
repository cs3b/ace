# frozen_string_literal: true

require "find"
require "ace/assign/authority/command_execution"
require "ace/herdr/molecules/bounded_observation"
require "ace/runtime/molecules/process_identity"
require_relative "command_policy"

module Ace
  module Lab
    module Molecules
      # Adds the project-command principals to the same installed listener.
      # Root launch facts do not impersonate a participant/native agent.
      class CommandOwnerAdmission
        def initialize(base:, project:, policy_loader: nil)
          @base, @project = base, project
          @policy_loader = policy_loader || -> { CommandPolicy.load(project: @project) }
          @peer = Ace::Assign::Authority::OrdinaryPeer.new
        end
        def service = @base.service
        def verify_listener! = @base.verify_listener!
        def peer(socket, deadline:) = @base.peer(socket, deadline: deadline)
        def authorize!(request:, peer:, deadline:)
          return @base.authorize!(request: request, peer: peer, deadline: deadline) unless Ace::Assign::Authority::CommandExecution::OPERATIONS.include?(request["operation"])
          raise Ace::Assign::AttemptErrors::UnauthorizedIdentity unless request["project_id"] == @project
          if %w[command_claim command_bind command_complete].include?(request["operation"])
            command_launcher!(peer: peer, deadline: deadline)
          elsif request["operation"] == "command_status"
            @peer.live!(peer, deadline: deadline) # Handler checks original requester before exposing data.
          else
            command_reader!(peer: peer, deadline: deadline)
          end
          :worker
        end

        def command_reader!(peer:, deadline:, definition: nil)
          @peer.live!(peer, deadline: deadline)
          return true if peer["uid"] == 0 && command_launcher!(peer: peer, deadline: deadline)
          if definition
            # Inspection never grants a second effect. Original requester UID
            # retains reconciliation after policy revocation or process restart.
            unless definition.dig("requester", "uid") == peer.fetch("uid")
              raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "command reference belongs to another requester"
            end
            return true
          end
          # Authorize visibility through the same closed selection machinery;
          # absence of any configured grant is a refusal, not native inference.
          document = policy
          document.reader!(peer.fetch("uid"))
        end

        def command_request!(selection:, peer:, deadline:)
          @peer.live!(peer, deadline: deadline)
          selected = policy.select(selection: selection, peer: peer)
          if selected.fetch("requester_kind") == "agent"
            selected["native_binding"] = @base.identity!(peer: peer, pane: selection.fetch("pane"), deadline: deadline).runtime_binding
          end
          verify_context!(selected, deadline)
          selected
        end

        # Historical execution can outlive its requester. Current root policy
        # and immutable source/executable must still grant this exact TEST
        # command; requester liveness does not invent a new execution.
        def command_test_evidence!(definition:, deadline:)
          unless definition["purpose"] == "test" && definition.dig("source", "head") && definition.dig("source", "tree") &&
              policy.select(selection: definition.fetch("selection"), peer: definition.fetch("requester")) == definition.except("native_binding")
            raise Ace::Assign::AttemptErrors::ReceiptRejected, "executed test command policy was revoked or changed"
          end
          verify_context!(definition, deadline)
        rescue SecurityError, Ace::Lab::InvalidConfigurationError
          raise Ace::Assign::AttemptErrors::ReceiptRejected, "executed test command policy or source is unavailable"
        end

        def command_launcher!(peer:, deadline:)
          @peer.live!(peer, deadline: deadline)
          expected = JSON.parse(GrantResolver.read_verified(policy.launcher.fetch("identity_path")) || "null")
          unless expected.is_a?(Hash) && expected.keys.sort == %w[identity schema] &&
              expected["schema"] == "labd-command-launcher/v1" && expected["identity"].is_a?(Hash) &&
              expected["identity"]["uid"] == 0 && peer["uid"] == 0
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "installed command launcher differs"
          end
          target = expected.fetch("identity")
          @peer.live!(target, deadline: deadline)
          cursor = peer
          64.times do
            return target if cursor.slice("pid", "uid", "host", "started_at") == target.slice("pid", "uid", "host", "started_at")
            break unless RUBY_PLATFORM.include?("linux") && cursor["uid"] == 0
            stat = File.read("/proc/#{cursor.fetch('pid')}/stat")
            parent = Integer(stat[(stat.rindex(")") + 2)..].split.fetch(1), 10)
            break if parent <= 1
            @peer.live!(cursor, deadline: deadline)
            identity = Ace::Runtime::Molecules::ProcessIdentity.new(executor:
              Ace::Herdr::Molecules::BoundedObservation.new(deadline: deadline)).capture(parent)
            break unless identity
            cursor = identity
          end
          raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "command helper is outside installed launcher ancestry"
        rescue JSON::ParserError, SystemCallError, IndexError, ArgumentError
          raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "installed command launcher is unavailable"
        end

        def command_claim!(definition:, caller:, launcher:, deadline:)
          command_launcher!(peer: launcher, deadline: deadline)
          unless caller == definition.fetch("requester") && command_request!(selection: definition.fetch("selection"), peer: caller, deadline: deadline) == definition
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "command requester or policy changed"
          end
          true
        end

        def command_child!(definition:, child:, launcher:, deadline:)
          command_launcher!(peer: launcher, deadline: deadline)
          unless command_request!(selection: definition.fetch("selection"), peer: definition.fetch("requester"), deadline: deadline) == definition
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "command admission changed before exec"
          end
          # The authenticated root daemon witnesses cwd/identity after dropping
          # the gated child. Owner independently captures its kernel generation.
          keys = %w[pid uid gid groups started_at host cwd process_group no_new_privs capabilities]
          actual = Ace::Runtime::Molecules::ProcessIdentity.new(executor:
            Ace::Herdr::Molecules::BoundedObservation.new(deadline: deadline)).capture(child["pid"])
          executor = definition.fetch("executor")
          unless child.is_a?(Hash) && child.keys.sort == keys.sort && actual &&
              actual == child.slice("pid", "uid", "started_at", "host") &&
              child["no_new_privs"] == 1 && child["capabilities"].is_a?(Hash) &&
              child["capabilities"].keys.sort == %w[CapAmb CapEff CapInh CapPrm] &&
              child["capabilities"].values.all? { |value| value.is_a?(String) && value.match?(/\A0{16}\z/) } &&
              child.values_at("uid", "gid", "groups", "cwd", "process_group") ==
                [executor.fetch("uid"), executor.fetch("gid"), executor.fetch("groups"), executor.fetch("cwd"), child.fetch("pid")]
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "gated command child differs"
          end
          {"kernel_identity" => actual, "root_witness" => child, "witnessed_by" => launcher}
        end

        private

        def policy = @policy_loader.call

        def verify_context!(definition, deadline)
          executor = definition.fetch("executor")
          cwd = executor.fetch("cwd")
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(cwd, directory: true)
          executor.fetch("path").each { |entry| GrantResolver.trusted_directory!(entry) }
          home = executor.fetch("home")
          GrantResolver.trusted_directory!(home) if File.exist?(home) || File.symlink?(home)
          count = 0
          Find.find(cwd) do |path|
            raise InvalidConfigurationError, "command source exceeds verification bound" if (count += 1) > 20_000 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            stat = File.lstat(path)
            unless stat.uid.zero? && (stat.mode & 0o022).zero? && !stat.symlink? && (stat.file? || stat.directory?)
              raise InvalidConfigurationError, "command source must be an immutable installed view"
            end
          end
          executable = File.expand_path(definition.fetch("argv").first, cwd)
          raise InvalidConfigurationError, "command executable exceeds verification bound" if File.size(executable) > 64 * 1024 * 1024
          bytes = GrantResolver.read_verified(executable)
          unless bytes && File.executable?(executable) && Digest::SHA256.hexdigest(bytes) == definition.fetch("executable_sha256")
            raise InvalidConfigurationError, "command executable differs"
          end
          source = definition.fetch("source")
          if source.fetch("head")
            result = Ace::Herdr::Molecules::BoundedProcess.call(["/usr/bin/git", "-c", "safe.directory=#{cwd}",
              "-c", "core.hooksPath=/dev/null", "-c", "core.fsmonitor=false", "rev-parse", "HEAD", "HEAD^{tree}"],
              environment: Ace::Assign::Molecules::InstalledJournalRead::ENVIRONMENT, chdir: cwd,
              stdin_data: "", timeout_s: deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), output_limit: 1024, cleanup_group: true)
            unless result.status.success? && result.stdout.lines.map(&:strip) == source.values_at("head", "tree")
              raise InvalidConfigurationError, "command accepted source differs"
            end
            clean = Ace::Herdr::Molecules::BoundedProcess.call(["/usr/bin/git", "-c", "safe.directory=#{cwd}",
              "-c", "core.hooksPath=/dev/null", "-c", "core.fsmonitor=false", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
              environment: Ace::Assign::Molecules::InstalledJournalRead::ENVIRONMENT, chdir: cwd,
              stdin_data: "", timeout_s: deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), output_limit: 65_536, cleanup_group: true)
            unless clean.status.success? && clean.stdout.empty? && !clean.oversized
              raise InvalidConfigurationError, "command accepted source is dirty"
            end
          end
          true
        end
      end
    end
  end
end
