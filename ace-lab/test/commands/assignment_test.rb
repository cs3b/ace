# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentCommandTest < Minitest::Test
  def test_drive_uses_installed_transport_and_original_context_for_supervisor_adoption
    assert Ace::Lab::CLI::REGISTERED_COMMANDS.any? { |name, _| name == "assignment drive" }
    calls = []
    transport = Object.new
    driver = Object.new
    driver.define_singleton_method(:adopt_supervisor) do |**options|
      calls << options
      {"data" => {"generation" => 2}, "request" => "/retained/original/request.json"}
    end
    client_factory = ->(project:) { assert_equal "atlas", project; transport }
    driver_factory = ->(**options) { assert_equal({path: "/retained/context.json", project: "atlas", transport: transport}, options); driver }
    Ace::Lab::Organisms::OrdinaryAssignmentClient.stub(:new, client_factory) do
      Ace::Assign::Organisms::OrdinaryDriver.stub(:new, driver_factory) do
        out, = capture_io do
          Ace::Lab::CLI::Commands::Assignment::Drive.new.call(project: "atlas", context: "/retained/context.json",
            operation: "adopt-supervisor", pane: "w1:pS", generation: 1, previous_binding_sha256: "a" * 64)
        end
        assert_equal "/retained/original/request.json", JSON.parse(out).fetch("request")
      end
    end
    assert_equal [{pane: "w1:pS", generation: 1, previous_binding_sha256: "a" * 64}], calls
  end

  def test_registered_request_preserves_explicit_selection_and_emits_canonical_reply
    assert Ace::Lab::CLI::REGISTERED_COMMANDS.any? { |name, _| name == "assignment request" }
    assert Ace::Lab::CLI::REGISTERED_COMMANDS.any? { |name, _| name == "assignment prepare" }
    calls = []
    service = Object.new
    service.define_singleton_method(:request) do |**options|
      calls << options
      {"status" => "ok", "data" => {"generation" => 7}, "transport" => {"replayed" => true}}
    end
    factory = ->(project:) { assert_equal "atlas", project; service }
    Ace::Lab::Organisms::OrdinaryAssignmentClient.stub(:new, factory) do
      out, = capture_io do
        Ace::Lab::CLI::Commands::Assignment::Request.new.call(project: "atlas", input: "original.json", output: "snapshot")
      end
      assert_equal true, JSON.parse(out).dig("transport", "replayed")
    end
    assert_equal [{input: "original.json", output: "snapshot"}], calls
  end

  def test_absent_owner_returns_failure_without_success_or_local_fallback
    factory = ->(**) { raise Ace::Lab::InvalidConfigurationError, "installed owner unavailable" }
    Ace::Lab::Organisms::OrdinaryAssignmentClient.stub(:new, factory) do
      out, = capture_io do
        error = assert_raises(Ace::Support::Cli::Error) do
          Ace::Lab::CLI::Commands::Assignment::Request.new.call(project: "atlas", input: "original.json")
        end
        assert_includes error.message, "retain the original request"
      end
      assert_empty out
    end
  end
end
