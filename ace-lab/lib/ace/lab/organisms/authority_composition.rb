# frozen_string_literal: true

require "ace/assign/authority/server"
require "ace/assign/authority/router"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/endcap"
require "ace/assign/authority/inbox_context_completion"
require_relative "../molecules/protected_service_policy"

module Ace
  module Lab
    module Organisms
      # The only full-service composition. The deployed map chooses identity
      # and placement; source selects all handlers, policy and evidence readers.
      class AuthorityComposition
        REQUIRED_ENDCAP = %w[submit_candidate export_candidate assign_review accept_review request_service
          begin_dispatch claim_service_settlement complete_service complete_no_effect submit_result finish recover bind_inbox reconcile_inbox
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
          completion = Ace::Assign::Authority::InboxContextCompletion.new(deployment: @deployment, history: history,
            authority_id: @authority_id, journals: journals, kernel: @kernel)
          router = Ace::Assign::Authority::Router.new(launch: launch, handlers: [endcap, completion])
          Ace::Assign::Authority::Server.new(authority_id: @authority_id, deployment: @deployment, kernel: @kernel,
            lifecycle: router, composition: "services")
        end
      end
    end
  end
end
