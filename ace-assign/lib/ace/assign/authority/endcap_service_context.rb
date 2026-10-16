# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Protected admission remains here. The shared fixed service transitions
      # never manufacture a Deployment mapping or a protected launch origin.
      class Endcap
        include FixedServiceLifecycle
        include FixedPublicationLifecycle

        private

        def with_service_scope(**options, &block) = @launch.with_assignment(**options, &block)
        def service_journal!(journal) = protected_journal!(journal)
        def service_mapping!(id) = @deployment.mapping(id)
        def service_project!(id) = @deployment.project(id)
        def service_scope_open!(**options) = @launch.scope_open_for_effect!(**options)
        def service_preview_events!(**options) = @launch.preview_attempt_events!(**options)
        def service_origin!(events, params) = active_origin(events, params)

        def service_origin_fields!(origin)
          {"worker_process_binding" => origin.fetch("process_binding").fetch("process_identity"),
            "launch_ticket" => origin.fetch("launch_ticket"),
            "reservation_generation" => origin.fetch("reservation_generation")}
        end

        def service_origin_matches!(record, origin)
          expected = service_origin_fields!(origin)
          record.slice(*expected.keys) == expected
        end

        def service_worker!(*args, **options) = worker_or_launcher!(*args, **options)
        def service_review!(*args, **options) = approved_review!(*args, **options)
      end
    end
  end
end
