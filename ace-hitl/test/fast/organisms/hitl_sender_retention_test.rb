# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Organisms
      class HitlSenderRetentionTest < AceHitlTestCase
        attr_accessor :route_name, :adapter_name

        FlakyAdapter = Struct.new(:deliveries, :failure, :mode) do
          attr_accessor :route_name, :adapter_name

          def deliver(event:, text:, recipient:, reply_to:)
            deliveries << {event_id: event.id, text: text}
            raise failure if failure

            Adapters::RouteResult.new(route: route_name, adapter: adapter_name,
              status: :delivered, detail: "ok")
          end
        end

        def setup
          Adapters.reset_registry!
        end

        def teardown
          Adapters.reset_registry!
        end

        def config(root, *routes)
          {"hitl" => {
            "root_dir" => root, "machine" => "lab01",
            "recipients" => {"overseer" => {"machine" => "lab01", "folder" => root}},
            "adapters" => {"routes" => routes}
          }}
        end

        # Registers a controllable adapter; returns [deliveries, knob] where
        # knob = {failure: Exception or nil} mutable between sends.
        def register_flaky(name)
          deliveries = []
          knob = {failure: nil}
          Adapters.register(name, ->(route) do
            adapter = FlakyAdapter.new(deliveries, knob[:failure])
            adapter.route_name = route["route"]
            adapter.adapter_name = name
            adapter
          end)
          [deliveries, knob]
        end

        def create_report(manager)
          manager.create("Work done", to: "overseer", type: "report",
            result: "success", task: "8xg.t.sbz.1.3", body: ["did the thing"])
        end

        def delivery_map(manager, id)
          manager.show(id)[:event].metadata["delivery"]
        end

        def test_failed_result_and_reason_are_retained_on_the_event
          with_hitl_dir do |root|
            cfg = config(root, {"route" => "r1", "adapter" => "alpha"})
            deliveries, knob = register_flaky(:alpha)
            knob[:failure] = Ace::Runtime::RuntimeUnavailableError.new("herdr socket missing")
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)

            report = HitlSender.new(manager: manager, config: cfg).send(event.id)

            refute report.all_delivered?
            retained = delivery_map(manager, event.id)
            assert_equal "failed", retained["r1"]["status"]
            assert_includes retained["r1"]["detail"], "herdr socket missing"
            assert retained["r1"]["attempted_at"]
            assert_equal "alpha", retained["r1"]["adapter"]
          end
        end

        def test_retry_after_transport_restoration_delivers_same_case_and_task
          with_hitl_dir do |root|
            cfg = config(root, {"route" => "r1", "adapter" => "alpha"})
            deliveries, knob = register_flaky(:alpha)
            knob[:failure] = Ace::Runtime::RuntimeUnavailableError.new("down")
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)
            sender = HitlSender.new(manager: manager, config: cfg)

            sender.send(event.id)
            assert_equal 1, deliveries.size

            # Transport restored.
            knob[:failure] = nil
            report = sender.send(event.id)

            assert report.all_delivered?
            assert_equal 2, deliveries.size
            first, second = deliveries
            assert_equal first[:text], second[:text], "same rendering (same case ID + task binding)"
            assert_includes second[:text], "case #{event.id}"
            assert_includes second[:text], "Task: 8xg.t.sbz.1.3"
            assert_equal "delivered", delivery_map(manager, event.id)["r1"]["status"]
          end
        end

        def test_retry_skips_delivered_routes
          with_hitl_dir do |root|
            cfg = config(root,
              {"route" => "healthy", "adapter" => "alpha"},
              {"route" => "broken", "adapter" => "beta"})
            healthy, healthy_knob = register_flaky(:alpha)
            broken, broken_knob = register_flaky(:beta)
            broken_knob[:failure] = Ace::Runtime::RuntimeUnavailableError.new("down")
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)
            sender = HitlSender.new(manager: manager, config: cfg)

            sender.send(event.id)
            assert_equal 1, healthy.size
            assert_equal 1, broken.size

            broken_knob[:failure] = nil
            report = sender.send(event.id)

            assert report.all_delivered?
            assert_equal 1, healthy.size, "delivered route is not re-sent"
            assert_equal 2, broken.size, "failed route is retried"
            assert_equal 1, report.skipped.size
            assert_equal "healthy", report.skipped.first.route
          end
        end

        def test_stale_in_flight_marker_is_unknown_and_retried_with_same_id
          with_hitl_dir do |root|
            cfg = config(root, {"route" => "r1", "adapter" => "alpha"})
            deliveries, = register_flaky(:alpha)
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)

            # Simulate a crash between the in_flight marker and the result:
            # the recipient accepted the message (one delivery recorded by
            # the recipient), but the sender died before persisting.
            Ace::Support::Items::Molecules::FieldUpdater.update(event.file_path,
              set: {"delivery.r1.status" => "in_flight",
                    "delivery.r1.adapter" => "alpha",
                    "delivery.r1.attempted_at" => "2026-10-18T12:00:00Z"})
            deliveries << {event_id: event.id, text: Atoms::HitlEventText.call(event)}

            # Redelivery after the lost ACK.
            report = HitlSender.new(manager: manager, config: cfg).send(event.id)

            assert report.all_delivered?
            assert_equal 2, deliveries.size, "redelivery re-sent the same case (at-least-once)"
            first, second = deliveries.map { |d| d[:text] }
            assert_includes first, "case #{event.id}"
            assert_includes second, "case #{event.id}"
            assert_equal first, second, "duplicate is identifiable: identical ID and content"

            # Redelivery performed delivery only: no resume, no answer write.
            reloaded = manager.show(event.id)[:event]
            assert_nil reloaded.answer
            assert_equal "recorded", reloaded.status
          end
        end

        def test_force_redelivers_delivered_routes_with_same_id
          with_hitl_dir do |root|
            cfg = config(root, {"route" => "r1", "adapter" => "alpha"})
            deliveries, = register_flaky(:alpha)
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)
            sender = HitlSender.new(manager: manager, config: cfg)

            sender.send(event.id)
            report = sender.send(event.id, force: true)

            assert report.all_delivered?
            assert_equal 2, deliveries.size
            assert_equal deliveries.first[:text], deliveries.last[:text]
          end
        end

        def test_dry_run_reports_decisions_without_delivery_or_write
          with_hitl_dir do |root|
            cfg = config(root, {"route" => "r1", "adapter" => "alpha"})
            deliveries, = register_flaky(:alpha)
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)

            HitlSender.new(manager: manager, config: cfg).send(event.id, force: true)
            deliveries.clear

            report = HitlSender.new(manager: manager, config: cfg).send(event.id, dry_run: true)

            assert_equal 1, report.skipped.size
            assert_empty report.results
            assert_empty deliveries, "dry-run performs no delivery"
            assert_equal "delivered", delivery_map(manager, event.id)["r1"]["status"]
          end
        end

        def test_all_delivered_noop_attempts_nothing
          with_hitl_dir do |root|
            cfg = config(root, {"route" => "r1", "adapter" => "alpha"})
            deliveries, = register_flaky(:alpha)
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)
            sender = HitlSender.new(manager: manager, config: cfg)

            sender.send(event.id)
            deliveries.clear
            report = sender.send(event.id)

            assert report.all_delivered?
            assert_empty report.results
            assert_empty deliveries
          end
        end

        def test_unknown_adapter_abort_retains_attempted_route_records
          with_hitl_dir do |root|
            cfg = config(root,
              {"route" => "first", "adapter" => "alpha"},
              {"route" => "second", "adapter" => "nervus"})
            deliveries, = register_flaky(:alpha)
            manager = HitlManager.new(root_dir: root, config: cfg)
            event = create_report(manager)

            assert_raises(Adapters::UnknownAdapterError) do
              HitlSender.new(manager: manager, config: cfg).send(event.id)
            end

            assert_equal 1, deliveries.size, "first route delivered before the abort"
            retained = delivery_map(manager, event.id)
            assert_equal "delivered", retained["first"]["status"], "delivered record survives the abort"
          end
        end
      end
    end
  end
end
