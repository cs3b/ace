# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/readiness_configuration"

class ReadinessConfigurationTest < Minitest::Test
  Configuration = Ace::Runtime::Molecules::ReadinessConfiguration

  def payload
    {"runtime" => {"interpreter_path" => "/usr/bin/ruby", "load_paths" => ["/usr/lib/ruby"],
        "dependencies" => [{"path" => "/usr/bin/ruby", "sha256" => "c" * 64, "bytes" => 1}]},
      "schema" => Configuration::SCHEMA, "slot_id" => "slot", "mapping_id" => "map", "project_id" => "project",
      "authority" => {"uid" => 13000, "gid" => 13000, "groups" => [], "socket_path" => "/run/ace/authority.sock"},
      "worker" => {"uid" => 13001, "gid" => 13001, "groups" => []},
      "native" => {"socket_path" => "/run/slot/native.sock", "executable" => "/opt/herdr", "version" => "0.9.3",
        "protocol" => 22, "workspace_id" => "w1", "executable_sha256" => "a" * 64},
      "boundary_manifest" => {"path" => "/etc/ace/execution-slots/slot/boundary-manifest.json", "sha256" => "b" * 64}}
  end

  def installation
    {"artifacts" => [{"role" => "runtime_dependency", "view_path" => "/usr/bin/ruby", "sha256" => "c" * 64}]}
  end

  def test_exact_selected_protected_values_and_deep_immutability
    config = Configuration.decode(JSON.generate(payload), slot: "slot")
    map = {"project_id" => "project", "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [],
      "native" => payload.fetch("native"), "execution_scope" => {"slot_id" => "slot", "boundary_manifest_sha256" => "b" * 64}}
    assert config.verify_selection!(mapping_id: "map", mapping: map, authority: payload.fetch("authority"), installation: installation)
    assert config.frozen?
    assert config.data.fetch("native").frozen?
    map["worker_uid"] = 13002
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      config.verify_selection!(mapping_id: "map", mapping: map, authority: payload.fetch("authority"), installation: installation)
    end
  end

  def test_closed_strict_bounded_content
    bytes = JSON.generate(payload)
    [bytes.sub('"slot_id":"slot"', '"slot_id":"slot","slot_id":"other"'), "\xff".b,
      " " * 65_537, JSON.generate(payload.merge("server_identity" => {})),
      JSON.generate(payload.merge("slot_id" => "another"))].each do |invalid|
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { Configuration.decode(invalid, slot: "slot") }
    end
  end

  def test_no_credential_or_boundary_path_substitution
    %w[authority worker].each do |kind|
      value = payload
      value[kind]["groups"] = [0]
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { Configuration.decode(JSON.generate(value), slot: "slot") }
    end
    value = payload
    value["boundary_manifest"]["path"] = "/tmp/boundary.json"
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { Configuration.decode(JSON.generate(value), slot: "slot") }
  end
end
