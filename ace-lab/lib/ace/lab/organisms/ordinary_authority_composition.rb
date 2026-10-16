# frozen_string_literal: true

require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/router"
require "ace/hitl/providers/lab"
require "ace/hitl/lifecycle/service"
require "ace/hitl/lifecycle/tls_authority"
require "ace/hitl/lifecycle/tls_service"
require_relative "../molecules/ordinary_owner_admission"
require_relative "../molecules/command_owner_admission"
require_relative "../molecules/ordinary_listener"
require_relative "ordinary_merge_receiver"

module Ace
  module Lab
    module Organisms
      # Ordinary delivery has one installed journal writer and exclusion owner.
      # Existing Assign, HITL and merge protocols share that process lifetime;
      # no requester cache or daemon working directory chooses accepted state.
      class OrdinaryAuthorityComposition
        def initialize(receiver_config:, owner_config: nil)
          unless receiver_config.is_a?(Molecules::OrdinaryReceiverConfig)
            raise ArgumentError, "ordinary composition needs installed receiver selection"
          end
          @receiver = receiver_config
          @config = owner_config || Molecules::OrdinaryOwnerConfig.load(project: @receiver.project)
          unless @config.is_a?(Molecules::OrdinaryOwnerConfig)
            raise ArgumentError, "ordinary composition needs installed assignment selection"
          end
        end

        def build
          @config.verify_listener!
          policy_document = Molecules::GrantResolver.trusted_document(@receiver.policy_path)
          verify_join!(policy_document)
          admission = Molecules::OrdinaryOwnerAdmission.new(config: @config)
          reader = nil
          journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @config.journal.fetch("repository"),
            ref: @config.journal.fetch("ref"), checkout_root: @config.journal.fetch("checkout_root"),
            evidence_reader: ->(reference, record, state, pending) { reader.call(reference, record, state, pending) })
          reader = Ace::Assign::Authority::ServiceEvidence.new(journal: journal)
          exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: @config.lifecycle_root)
          command_admission = Molecules::CommandOwnerAdmission.new(base: admission, project: @config.project)
          command = Ace::Assign::Authority::CommandExecution.new(project: @config.project, journal: journal,
            admission: command_admission)
          lifecycle = Ace::Assign::Authority::OrdinaryLifecycle.new(project: @config.project,
            admission: admission, journal: journal, exclusion: exclusion, input_root: @config.assignment_root,
            command_evidence: command)
          coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: @config.assignment_root,
            repo_root: @config.journal.fetch("repository"), journal: journal, lifecycle_exclusion: exclusion,
            recorded_binding_observer: admission.method(:recorded_binding!), ordinary_merge_evidence: lifecycle)
          router = Ace::Assign::Authority::Router.new(handlers: [lifecycle, command])
          merge = OrdinaryMergeReceiver.new(config: @receiver, coordinator: coordinator,
            policy_document: policy_document, owner_guard: -> { @config.selected_principal!(@receiver.principal_uid) },
            merge_factory: ->(document) {
              Molecules::OrdinaryMergeRead.new(repo_path: @receiver.repo_path, base_ref: document.fetch("base_ref"),
                root: @receiver.repo_path, common_dir: @config.worktrees.fetch("common_dir"))
            })
          listener = Molecules::OrdinaryListener.new(socket_path: @receiver.socket_path,
            peer_uid: @receiver.principal_uid, socket_gid: @receiver.socket_gid, handler: merge,
            logger: ->(message) { warn message })
          Ace::Assign::Authority::OrdinaryServer.new(admission: command_admission, lifecycle: router,
            services: hitl_services(coordinator) + [listener])
        end

        private

        def verify_join!(document)
          configured = Molecules::ServicePolicy.new(document).ordinary_receiver!(@config.project)
          expected = {"receiver_id" => @receiver.receiver_id, "socket_path" => @receiver.socket_path,
            "receiver_uid" => @config.service.fetch("uid"), "principal" => @receiver.principal,
            "journal_repository" => @config.journal.fetch("repository"), "journal_ref" => @config.journal.fetch("ref")}
          unless @receiver.project == @config.project && @receiver.receiver_uid == @config.service.fetch("uid") &&
              configured && configured.slice(*expected.keys) == expected &&
              @config.participants.key?(@receiver.principal_uid.to_s) &&
              ![@config.service.fetch("socket_path"), @config.native.fetch("socket_path"), @config.hitl.fetch("socket_path")].include?(@receiver.socket_path)
            raise InvalidConfigurationError, "ordinary receiver and assignment owner selections differ"
          end
        end

        def hitl_services(coordinator)
          selected = @config.hitl
          policy = Ace::Hitl::Providers::Lab.grants_policy(grants_path: selected.fetch("grants_path"))
          unless policy.service_uid == @config.service.fetch("uid")
            raise InvalidConfigurationError, "ordinary HITL service principal differs from assignment owner"
          end
          guard = lambda do
            @config.verify_owner!
            unless policy.service_uid == @config.service.fetch("uid")
              raise Ace::Hitl::Lifecycle::BindingError, "installed HITL service principal changed"
            end
          rescue Ace::Lab::InvalidConfigurationError, Ace::Assign::Error => error
            raise Ace::Hitl::Lifecycle::BindingError, error.message
          end
          binding = Ace::Hitl::Providers::Lab::AssignmentBinding.new(coordinator: coordinator,
            project: @config.project, owner_guard: guard)
          # Unix requesters and the existing Hermes mTLS transport share the
          # same owner and one in-memory OTP vault. No second daemon opens the
          # journal and no synthetic Unix principal represents a certificate.
          vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
          services = [Ace::Hitl::Lifecycle::Service.new(root: selected.fetch("root"),
            socket_path: selected.fetch("socket_path"), group: selected.fetch("group"),
            binding: binding, policy: policy, vault: vault)]
          if selected.key?("tls_authority")
            authority = Ace::Hitl::Lifecycle::TlsAuthority.load(selected.fetch("tls_authority"))
            verify_tls_identity!(authority)
            services << Ace::Hitl::Lifecycle::TlsService.new(root: selected.fetch("root"),
              binding: binding, project: @config.project, credential: authority.credential,
              ssl_context: authority.ssl_context!, listen: authority.listen, port: authority.port,
              group: selected.fetch("group"), vault: vault, decision_policy: policy)
          end
          services
        end

        def verify_tls_identity!(authority)
          unless authority.project_id == @config.project &&
              Etc.getpwnam(authority.service_user).uid == @config.service.fetch("uid") &&
              Etc.getgrnam(authority.service_group).gid == @config.service.fetch("gid")
            raise InvalidConfigurationError, "ordinary HITL TLS project or service identity differs"
          end
        rescue ArgumentError
          raise InvalidConfigurationError, "ordinary HITL TLS service account is unavailable"
        end
      end
    end
  end
end
