# frozen_string_literal: true

require "ace/assign/authority/server"
require "ace/assign/authority/router"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/endcap"
require_relative "../molecules/protected_service_policy"
require "ace/hitl/providers/lab"
require "ace/hitl/providers/lab/protected_assignment_binding"
require "ace/hitl/lifecycle/service_publication_binding"
require "ace/hitl/lifecycle/service"

module Ace
  module Lab
    module Organisms
      # The only full-service composition. The deployed map chooses identity
      # and placement; source selects all handlers, policy and evidence readers.
      class AuthorityComposition
        REQUIRED_ENDCAP = %w[submit_candidate export_candidate assign_review accept_review request_service
          begin_dispatch publication_challenge publication_continue claim_service_settlement complete_service complete_no_effect submit_result finish recover bind_inbox
          service_status evidence_fetch].freeze

        def initialize(authority_id:, deployment: Ace::Assign::Authority::Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @authority_id, @deployment, @kernel = authority_id, deployment, kernel
        end

        def build
          @deployment.verify_composition!(@authority_id, composition: "services")
          unless (REQUIRED_ENDCAP - Ace::Assign::Authority::Endcap::OPERATIONS).empty?
            raise InvalidConfigurationError, "full-service source composition is incomplete"
          end
          projects = @deployment.data.fetch("launch_mappings").values
            .select { |map| map.fetch("authority_id") == @authority_id }.map { |map| map.fetch("project_id") }.uniq
          raise InvalidConfigurationError, "full-service authority has no projects" if projects.empty?
          projects.each do |id|
            project = @deployment.project(id)
            unless project["service_receivers"].is_a?(Hash) && !project["service_receivers"].empty?
              raise InvalidConfigurationError, "full-service project has no fixed receiver"
            end
          end

          journals = {}
          endcap = nil
          projects.each do |id|
            project = @deployment.project(id)
            reader = nil
            journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: project.fetch("journal_repository"),
              checkout_root: project.fetch("evidence_checkout_root"), ref: project.fetch("evidence_git_ref"), mode: :protected,
              evidence_reader: ->(reference, record, state, pending) { reader.call(reference, record, state, pending) },
              service_authorizer: ->(existing, replacement, pending) {
                endcap.authorize_service_update!(journal: journals.fetch(id), existing: existing,
                  replacement: replacement, pending: pending)
              })
            reader = Ace::Assign::Authority::ServiceEvidence.new(journal: journal)
            journals[id] = journal
          end
          policy = Molecules::ProtectedServicePolicy.new(proposal_resolver: ->(project, reference, binding) {
            journals.fetch(project).proposal_authorize!(reference, binding)
          })
          history = Ace::Assign::Authority::DeploymentHistory.load
          launch = Ace::Assign::Authority::LaunchLifecycle.new(deployment: @deployment, deployment_history: history,
            kernel: @kernel, journals: journals)
          endcap = Ace::Assign::Authority::Endcap.new(deployment: @deployment, launch: launch, kernel: @kernel,
            service_policy: policy, deployment_history: history)
          router = Ace::Assign::Authority::Router.new(launch: launch, handlers: [endcap])
          Ace::Assign::Authority::Server.new(authority_id: @authority_id, deployment: @deployment, kernel: @kernel,
            lifecycle: router, composition: "services", hitl_service: publication_hitl(endcap, journals))
        end

        private

        def publication_hitl(endcap, journals)
          provider = Ace::Hitl::Providers::Lab
          policy = provider.grants_policy(grants_path: provider::DEFAULT_GRANTS_PATH)
          unless policy.service_uid == @deployment.authority(@authority_id).fetch("uid")
            raise InvalidConfigurationError, "protected HITL service principal differs from installed authority"
          end
          ordinary = provider::ProtectedAssignmentBinding.new(authority: endcap, kernel: @kernel, journals: journals)
          binding = Ace::Hitl::Lifecycle::ServicePublicationBinding.new(ordinary: ordinary, authority: endcap, kernel: @kernel)
          Ace::Hitl::Lifecycle::Service.new(root: provider::DEFAULT_STORE_ROOT,
            socket_path: provider::DEFAULT_SOCKET_PATH, binding: binding, policy: policy)
        end
      end
    end
  end
end
