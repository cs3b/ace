# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/authority/launch_driver"

module Ace
  module Assign
    class LaunchBudgetTest < AceAssignTestCase
      def build_driver(costs = {})
        @now = 100.0
        @calls = []
        @creates = 0
        definition = JSON.generate("session_id" => "assignment", "prepared_work" => {"scope" => "010"})
        state = {"assignment_id" => "assignment", "attempt_id" => "attempt", "launch_ticket" => "ticket", "generation" => 1,
          "native_binding" => {"server_identity" => {}, "socket_identity" => {}, "workspace_id" => "workspace"}}
        owner = self
        client = Object.new
        client.define_singleton_method(:call) do |operation, _params, **options|
          owner.instance_variable_get(:@calls) << [operation, options.fetch(:timeout)]
          owner.instance_variable_set(:@now, owner.instance_variable_get(:@now) + costs.fetch(operation, 0))
          data = case operation
          when "registration_status"
            {"definition_digest" => Digest::SHA256.hexdigest(definition), "definition_generation" => 1,
              "prepared_bundle_bytes" => 6, "prepared_bundle_sha256" => Digest::SHA256.hexdigest("bundle")}
          else state
          end
          Struct.new(:data, :replayed).new(data, false)
        end
        deployment = Object.new
        deployment.define_singleton_method(:mapping) { |_id| {"worker_uid" => 123, "native" => {}} }
        deployment.define_singleton_method(:verify!) { |*_args, **_options| true }
        kernel = Object.new
        kernel.define_singleton_method(:capture) { |_pid| {} }
        native = Object.new
        native.define_singleton_method(:create) do |**_options|
          owner.instance_variable_set(:@creates, owner.instance_variable_get(:@creates) + 1)
          raise "controlled native boundary reached"
        end
        driver = Authority::LaunchDriver.new(mapping_id: "mapping", deployment: deployment,
          kernel: kernel, client: client, native: native, clock: -> { @now })
        [driver, {assignment_id: "assignment", definition_bytes: definition, prepared_bundle: "bundle",
          scope: "010", base_head: "a" * 40, mutation_id: "launch"}]
      end

      def test_later_phases_receive_only_original_remaining_budget
        driver, params = build_driver("launch_preflight" => 3, "registration_status" => 4, "reserve_attempt" => 5, "inspect_launch" => 2)
        result = driver.launch(**params)
        assert_equal [["launch_preflight", 30.0], ["registration_status", 27.0], ["reserve_attempt", 23.0], ["inspect_launch", 18.0]], @calls
        assert_equal 1, @creates
        assert_equal "uncertain", result.fetch("phase")
      end

      def test_expired_reservation_reply_retains_uncertainty_without_native_create_or_retry
        driver, params = build_driver("reserve_attempt" => 31)
        result = driver.launch(**params)
        assert_equal "uncertain", result.fetch("phase")
        assert_equal "attempt", result.fetch("attempt_id")
        assert_equal 0, @creates
        assert_equal %w[launch_preflight registration_status reserve_attempt], @calls.map(&:first)
      end

      def test_expired_pre_reservation_budget_refuses_before_native_effect
        driver, params = build_driver("registration_status" => 31)
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { driver.launch(**params) }
        assert_equal 0, @creates
        assert_equal %w[launch_preflight registration_status], @calls.map(&:first)
      end

      def test_expired_inspection_reply_never_creates
        driver, params = build_driver("inspect_launch" => 31)
        assert_equal "uncertain", driver.launch(**params).fetch("phase")
        assert_equal 0, @creates
      end
    end
  end
end
