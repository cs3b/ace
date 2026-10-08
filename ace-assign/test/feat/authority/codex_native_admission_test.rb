# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/execution_scope_observation"
module Ace
  module Assign
    class CodexNativeAdmissionTest < AceAssignTestCase
      class Manager
        attr_reader :starts, :stops
        attr_accessor :activation
        def initialize
          @starts = @stops = 0
          @activation = {"service" => {"ActiveState" => "inactive", "MainPID" => 0, "ControlPID" => 0, "Job" => [0, "/"], "InvocationID" => ""}}
        end
        def inspect_activation = Marshal.load(Marshal.dump(activation))
        def start_service
          @starts += 1
          @activation["service"].merge!("ActiveState" => "active", "MainPID" => 100, "InvocationID" => "a" * 32)
        end
        def stop_service
          @stops += 1
          @activation["service"].merge!("ActiveState" => "inactive", "MainPID" => 0)
        end
        def unit_for_pidfd(handle:)
          {"unit" => "codex.service", "invocation_id" => activation.fetch("service").fetch("InvocationID")}
        end
      end
      class Kernel
        Pin = Struct.new(:closed) { def close; self.closed = true; end }
        attr_reader :pins
        def initialize(manager)
          @manager, @pins = manager, []
        end
        def capture(pid) = {"pid" => pid, "uid" => 13001, "gid" => 13001, "groups" => [13001]}
        def pin(peer)
          handle = Pin.new(false)
          @pins << handle
          handle
        end
        def same?(a,b) = a == b
        def live!(peer) = true
        def exited?(pin) = @manager.activation.fetch("service").fetch("MainPID").zero?
      end
      def setup
        super
        @scope = {"slot_id" => "slot", "slice_unit" => "slot.slice", "service_unit" => "worker.service", "unit_manifest_sha256" => "w"}
        map = {"execution_scope" => @scope, "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [13001]}
        deployment = Object.new
        deployment.define_singleton_method(:mapping) { |id| map }
        @manager, @worker = Manager.new, Manager.new
        @observer = Authority::ExecutionScopeObservation.new(mapping_id: "map", deployment: deployment, kernel: (@kernel = Kernel.new(@manager)), manager: @worker)
        @observer.define_singleton_method(:observe) { |lineage| true }
        reader = Object.new
        reader.define_singleton_method(:verify_unchanged!) { true }
        @observer.instance_variable_set(:@native_workspace_lifetime, {reader: reader, selector: "scope"})
        @installation = Ace::Runtime::Molecules::ExecutionUnitInstallation.allocate
        @installation.define_singleton_method(:verify_codex_runtime_selection!) { |**selection| true }
        lineage = Object.new
        lineage.define_singleton_method(:binding_event) { {"digest" => "scope"} }
        lineage.define_singleton_method(:sealed?) { false }
        @arguments = {lineage: lineage, installation: @installation, service: {"execution_scope" => @scope.merge("service_unit" => "codex.service", "unit_manifest_sha256" => "c")}, intent_reference: {}, manager: @manager}
      end
      def test_admitted_exact_unit_starts_once_and_stops_before_original_worker
        assert @observer.start_codex_service!(**@arguments)
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.start_codex_service!(**@arguments) }
        assert_equal 1, @manager.starts
        @observer.stop_sealed_service!
        assert_equal 1, @manager.stops
        assert_equal 1, @worker.stops
      end
      def test_changed_invocation_refuses_stop_without_touching_replacement_or_worker
        @observer.start_codex_service!(**@arguments)
        @manager.activation.fetch("service")["InvocationID"] = "b" * 32
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.stop_sealed_service! }
        assert_equal 0, @manager.stops
        assert_equal 0, @worker.stops
      end
      def test_shutdown_closes_retained_handles_without_claiming_native_stop
        @observer.start_codex_service!(**@arguments)
        @observer.close
        assert @kernel.pins.all?(&:closed)
        assert_equal 0, @manager.stops
        assert_equal 0, @worker.stops
      end
      def test_dedicated_selection_cannot_expand_slice
        @arguments.fetch(:service).fetch("execution_scope")["slice_unit"] = "other.slice"
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.start_codex_service!(**@arguments) }
        assert_equal 0, @manager.starts
      end
    end
  end
end
