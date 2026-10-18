# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Organisms
      class HitlSenderTest < AceHitlTestCase
        RecordingAdapter = Struct.new(:deliveries, :outcome) do
          attr_accessor :route_name, :adapter_name

          def deliver(event:, text:, recipient:, reply_to:)
            deliveries << {event_id: event.id, text: text, recipient: recipient,
              reply_to: reply_to}
            raise outcome if outcome

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

        def routes_config(root, *routes)
          {"hitl" => {
            "root_dir" => root,
            "machine" => "lab01",
            "recipients" => {"overseer" => {"machine" => "lab01", "folder" => root}},
            "adapters" => {"routes" => routes}
          }}
        end

        def register_recording_adapter(name, outcome: nil)
          deliveries = []
          adapter = RecordingAdapter.new(deliveries, outcome)
          Adapters.register(name, ->(route) do
            adapter.route_name = route["route"]
            adapter.adapter_name = name
            adapter
          end)
          deliveries
        end

        def create_question(manager)
          manager.create("Which DB?", to: "overseer", questions: ["Postgres?"])
        end

        def test_fan_out_delivers_shared_text_to_every_route
          with_hitl_dir do |root|
            config = routes_config(root,
              {"route" => "r1", "adapter" => "alpha"},
              {"route" => "r2", "adapter" => "beta"}
            )
            first = register_recording_adapter(:alpha)
            second = register_recording_adapter(:beta)
            manager = HitlManager.new(root_dir: root, config: config)
            event = create_question(manager)

            report = HitlSender.new(manager: manager, config: config).send(event.id)

            assert report.all_delivered?
            assert_equal 2, report.results.size
            text = Atoms::HitlEventText.call(event)
            [first, second].each do |deliveries|
              assert_equal 1, deliveries.size
              assert_equal event.id, deliveries.first[:event_id]
              assert_equal text, deliveries.first[:text]
            end
          end
        end

        def test_unavailable_route_does_not_hide_other_route_nor_reroute
          with_hitl_dir do |root|
            config = routes_config(root,
              {"route" => "broken", "adapter" => "alpha"},
              {"route" => "healthy", "adapter" => "beta"}
            )
            register_recording_adapter(:alpha, outcome: Ace::Runtime::RuntimeUnavailableError.new("down"))
            healthy = register_recording_adapter(:beta)
            manager = HitlManager.new(root_dir: root, config: config)
            event = create_question(manager)

            report = HitlSender.new(manager: manager, config: config).send(event.id)

            refute report.all_delivered?
            statuses = report.results.map { |r| [r.route, r.status] }.to_h
            assert_equal :failed, statuses["broken"] # contained failure
            assert_equal :delivered, statuses["healthy"]
            # no rerouting: the healthy route received exactly one delivery
            assert_equal 1, healthy.size
          end
        end

        def test_unexpected_route_exception_is_contained
          with_hitl_dir do |root|
            config = routes_config(root,
              {"route" => "exploding", "adapter" => "alpha"},
              {"route" => "ok", "adapter" => "beta"}
            )
            register_recording_adapter(:alpha, outcome: StandardError.new("boom"))
            healthy = register_recording_adapter(:beta)
            manager = HitlManager.new(root_dir: root, config: config)
            event = create_question(manager)

            report = HitlSender.new(manager: manager, config: config).send(event.id)

            failed = report.results.find { |r| r.route == "exploding" }
            assert_equal :failed, failed.status
            assert_includes failed.detail, "boom"
            assert_equal 1, healthy.size
          end
        end

        def test_no_routes_fails_closed_before_any_delivery
          with_hitl_dir do |root|
            config = routes_config(root)
            register_recording_adapter(:alpha)
            manager = HitlManager.new(root_dir: root, config: config)
            event = create_question(manager)

            error = assert_raises(Molecules::HitlRouteLoader::NoRoutesError) do
              HitlSender.new(manager: manager, config: config).send(event.id)
            end
            assert_includes error.message, "no adapter routes configured"
          end
        end

        def test_unknown_adapter_fails_closed
          with_hitl_dir do |root|
            config = routes_config(root,
              {"route" => "future", "adapter" => "nervus"})
            manager = HitlManager.new(root_dir: root, config: config)
            event = create_question(manager)

            assert_raises(Adapters::UnknownAdapterError) do
              HitlSender.new(manager: manager, config: config).send(event.id)
            end
          end
        end

        def test_unknown_ref_fails_without_delivery
          with_hitl_dir do |root|
            config = routes_config(root,
              {"route" => "r1", "adapter" => "alpha"})
            register_recording_adapter(:alpha)
            manager = HitlManager.new(root_dir: root, config: config)

            error = assert_raises(Adapters::Error) do
              HitlSender.new(manager: manager, config: config).send("zzz999")
            end
            assert_includes error.message, "not found"
          end
        end

        def test_delivery_and_reply_flow_binds_answer_to_the_case
          with_hitl_dir do |root|
            config = routes_config(root,
              {"route" => "r1", "adapter" => "alpha"})
            deliveries = register_recording_adapter(:alpha)
            manager = HitlManager.new(root_dir: root, config: config)
            event = create_question(manager)

            report = HitlSender.new(manager: manager, config: config).send(event.id)
            assert report.all_delivered?
            assert_includes deliveries.first[:text], "case #{event.id}"

            # Local Reply after delivery: exact-id binding, address unchanged.
            manager.update(event.id, answer: "Use Postgres")
            answered = manager.show(event.id)[:event]
            assert answered.answered?
            assert_equal "Use Postgres", answered.answer
            assert_equal event.id, answered.reply_to["id"]
            assert_equal event.id, answered.recipient["id"]
          end
        end
      end
    end
  end
end
