# frozen_string_literal: true

require "yaml"
require "json"
require "digest"
require "etc"
require "ace/assign/authority/private_directory"
require "ace/assign/authority/protected_assignment_context"
require "ace/assign/molecules/installed_journal_read"
require "ace/runtime/molecules/protected_artifact_set"
require_relative "../errors"

module Ace
  module Lab
    module Molecules
      # Placement and principals only. Source selects lifecycle operations.
      # Root installs this independently of requester worktrees/config cascades.
      class OrdinaryOwnerConfig
        PATH = "/etc/lab/ace-lab/assign-owners.yml"
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        PROJECT_KEYS = %w[service journal assignment_root lifecycle_root runtime_binary native worktrees participants].freeze
        SERVICE_KEYS = %w[uid gid socket_path state_root].freeze
        JOURNAL_KEYS = %w[repository ref checkout_root].freeze
        PARTICIPANT_KEYS = %w[gid actor role runtime workspace].freeze
        ROLES = %w[supervisor worker reviewer].freeze
        NATIVE_KEYS = %w[socket_path socket_identity server_identity version protocol].freeze

        def self.load(project:, path: PATH)
          reader = Ace::Runtime::Molecules::ProtectedArtifactSet.new(file_limit: 65_536, total_limit: 65_536)
          bytes = reader.with do |held|
            content, = held.read_path!(path)
            held.verify_unchanged!
            content
          end
          new(YAML.safe_load(bytes, aliases: false), project: project, source: path)
        rescue Psych::Exception, Ace::Runtime::Error
          raise InvalidConfigurationError, "ordinary assignment owner configuration is unavailable"
        end

        attr_reader :project, :service, :journal, :assignment_root, :lifecycle_root,
          :runtime_binary, :native, :worktrees, :participants, :source

        def initialize(document, project:, source:)
          unless document.is_a?(Hash) && document.keys.sort == %w[projects version] && document["version"] == 1 &&
              document["projects"].is_a?(Hash) && document["projects"].keys.all? { |id| id.is_a?(String) && ID.match?(id) } &&
              project.is_a?(String) && ID.match?(project)
            invalid!
          end
          selected = document.fetch("projects")[project]
          validate_principal_separation!(document.fetch("projects"))
          invalid! unless selected.is_a?(Hash) && selected.keys.sort == PROJECT_KEYS.sort
          invalid! unless absolute?(source)
          @project, @source = project.dup.freeze, source.dup.freeze
          # Validate a detached immutable copy; callers cannot mutate trusted selection.
          selected = JSON.parse(JSON.generate(selected))
          @service, @journal, @participants = selected.values_at("service", "journal", "participants")
          invalid! unless @service.is_a?(Hash) && @service.keys.sort == SERVICE_KEYS.sort &&
            %w[uid gid].all? { |key| uid?(@service[key]) } &&
            %w[socket_path state_root].all? { |key| absolute?(@service[key]) }
          invalid! unless @journal.is_a?(Hash) && @journal.keys.sort == JOURNAL_KEYS.sort &&
            %w[repository checkout_root].all? { |key| absolute?(@journal[key]) } &&
            @journal["ref"].is_a?(String) && @journal["ref"].match?(%r{\Arefs/[a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)+\z})
          @assignment_root, @lifecycle_root, @runtime_binary = selected.values_at("assignment_root", "lifecycle_root", "runtime_binary")
          invalid! unless [@assignment_root, @lifecycle_root, @runtime_binary].all? { |path| absolute?(path) }
          @native = selected.fetch("native")
          invalid! unless @native.is_a?(Hash) && @native.keys.sort == NATIVE_KEYS.sort && absolute?(@native["socket_path"]) &&
            @native["protocol"] == 22 && @native["protocol"].is_a?(Integer) && @native["version"].is_a?(String) &&
            @native["version"].match?(/\A\d+\.\d+\.\d+\z/)
          server = @native["server_identity"]
          invalid! unless server.is_a?(Hash) && server.keys.sort == %w[gid host pid started_at uid] &&
            %w[pid uid gid].all? { |key| uid?(server[key]) } &&
            %w[host started_at].all? { |key| server[key].is_a?(String) && server[key].bytesize.between?(1, 512) && !server[key].include?("\0") }
          endpoint = @native["socket_identity"]
          invalid! unless endpoint.is_a?(Array) && endpoint.size == 3 && endpoint.all? { |value| value.is_a?(Integer) && value >= 0 } && endpoint.last == server.fetch("uid")
          @worktrees = selected.fetch("worktrees")
          invalid! unless @worktrees.is_a?(Hash) && @worktrees.keys.sort == %w[common_dir root] && @worktrees.values.all? { |path| absolute?(path) }
          private_paths = [@assignment_root, @lifecycle_root, @journal.fetch("checkout_root")]
          invalid! unless private_paths.all? { |path| path.start_with?(@service.fetch("state_root") + "/") } &&
            private_paths.uniq.size == private_paths.size && private_paths.combination(2).none? { |a, b| a.start_with?(b + "/") || b.start_with?(a + "/") }
          invalid! if @journal.fetch("repository").start_with?(@service.fetch("state_root") + "/") ||
            @service.fetch("state_root").start_with?(@journal.fetch("repository") + "/") ||
            @service.fetch("state_root") == @journal.fetch("repository")
          invalid! unless @participants.is_a?(Hash) && !@participants.empty? && @participants.size <= 64
          @participants.each do |uid, participant|
            invalid! unless uid.is_a?(String) && uid.match?(/\A[1-9][0-9]{0,9}\z/) && uid?(uid.to_i) && uid.to_i != @service.fetch("uid") &&
              participant.is_a?(Hash) && participant.keys.sort == PARTICIPANT_KEYS.sort && uid?(participant["gid"]) &&
              participant["actor"].is_a?(String) && ID.match?(participant["actor"]) && ROLES.include?(participant["role"]) &&
              participant["runtime"] == "herdr" && participant["workspace"].is_a?(String) && ID.match?(participant["workspace"])
          end
          invalid! unless @participants.values.map { |value| value.fetch("actor") }.uniq.size == @participants.size
          @fingerprint = Digest::SHA256.hexdigest(Ace::Assign::Atoms::EvidenceDigest.canonical_json(selected))
          freeze_value(selected)
          freeze
        end

        def verify_selection!
          current = self.class.load(project: @project, path: @source)
          unless current.fingerprint == @fingerprint
            raise InvalidConfigurationError, "ordinary assignment owner selection changed; restart with installed configuration"
          end
          true
        end

        def verify_listener!
          verify_selection!
          unless [Process.uid, Process.euid, Process.gid, Process.egid] ==
              [@service.fetch("uid"), @service.fetch("uid"), @service.fetch("gid"), @service.fetch("gid")]
            raise InvalidConfigurationError, "ordinary assignment owner process differs"
          end
          ([service.fetch("uid")] + participants.keys.map(&:to_i)).each { |uid| exclude_protected!(uid) }
          [@service.fetch("state_root"), @assignment_root, @lifecycle_root, @journal.fetch("checkout_root")].each do |path|
            Ace::Assign::Authority::PrivateDirectory.verify!(path)
          end
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(@runtime_binary)
          invalid! unless File.file?(@runtime_binary) && File.executable?(@runtime_binary)
          invalid! unless File.lstat(@journal.fetch("repository")).uid == @service.fetch("uid")
          reader = Ace::Assign::Molecules::InstalledJournalRead.new(repo_root: @journal.fetch("repository"),
            ref: @journal.fetch("ref"), owner_uid: @service.fetch("uid"))
          reader.with(deadline: wire.deadline(30)) { |_snapshot| true }
          true
        end

        def participant!(peer)
          verify_selection!
          exclude_protected!(@service.fetch("uid"))
          exclude_protected!(peer.fetch("uid"))
          participant = @participants[peer.fetch("uid").to_s]
          unless participant && participant.fetch("gid") == peer.fetch("gid")
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary participant is not installed for this project"
          end
          # HITL and the canonical coordinator use the authenticated passwd
          # principal. An unrelated display label cannot replace that identity.
          unless Etc.getpwuid(peer.fetch("uid")).name == participant.fetch("actor")
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary actor differs from installed OS principal"
          end
          participant
        rescue ArgumentError
          raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary OS principal is unavailable"
        end

        protected

        attr_reader :fingerprint

        private

        def validate_principal_separation!(projects)
          invalid! unless projects.size.between?(1, 64)
          owners, callers = [], []
          projects.each_value do |entry|
            invalid! unless entry.is_a?(Hash) && entry["service"].is_a?(Hash) &&
              uid?(entry["service"]["uid"]) && entry["participants"].is_a?(Hash)
            owners << entry.fetch("service").fetch("uid")
            entry.fetch("participants").each_key do |uid|
              invalid! unless uid.is_a?(String) && uid.match?(/\A[1-9][0-9]{0,9}\z/) && uid?(uid.to_i)
              callers << uid.to_i
            end
          end
          invalid! unless (owners & callers).empty?
        end

        def exclude_protected!(uid)
          context = Ace::Assign::Authority::ProtectedAssignmentContext.load(uid: uid)
          if context.protected_participant?
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "protected principal cannot use ordinary assignment authority"
          end
        end

        def absolute?(value)
          value.is_a?(String) && value.bytesize.between?(1, 4096) && !value.include?("\0") &&
            value.start_with?("/") && File.expand_path(value) == value
        end

        def uid?(value) = value.is_a?(Integer) && value.between?(1, 2**31 - 1)

        def freeze_value(value)
          case value
          when Hash then value.each { |key, item| key.freeze; freeze_value(item) }
          when Array then value.each { |item| freeze_value(item) }
          end
          value.freeze
        end

        def invalid!
          raise InvalidConfigurationError, "ordinary assignment owner configuration is invalid"
        end
      end
    end
  end
end
