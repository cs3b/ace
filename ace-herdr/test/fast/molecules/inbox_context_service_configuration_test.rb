# frozen_string_literal: true

require "test_helper"
require "ace/herdr/molecules/inbox_context_service_configuration"
require "ace/herdr/molecules/codex_runtime_selection"
require_relative "../../support/inbox_context_owner_fixture"
require_relative "../../support/inbox_context_service_selection_fixture"

class InboxContextServiceConfigurationTest < Minitest::Test
  include InboxContextServiceSelectionFixture
  Configuration = Ace::Herdr::Molecules::InboxContextServiceConfiguration
  ERROR = Ace::Herdr::ValidationError

  def setup
    @root = File.realpath(Dir.mktmpdir("context-service-config"))
    @path = File.join(@root, "service.json")
    @data = {"schema" => "ace.herdr.inbox-context-service/v1", "project_id" => "project", "inbox_context_id" => "ctx",
      "native_mapping_id" => "mapping", "native_clients" => native_client_selection, "control_socket_path" => "/run/ctx/control.sock",
      "state_root" => "/var/lib/ctx/state", "deliveries_dir" => "/var/lib/ctx/events",
      "owner_credentials" => {"uid" => 200, "gid" => 200, "groups" => [300]}, "socket_gid" => 300,
      "key" => {"public_key_path" => "/etc/ctx/public.pem", "configuration_path" => "/etc/ctx/key.json"},
      "authority" => {"uid" => 100, "gid" => 100, "groups" => [], "socket_path" => "/run/authority/control.sock"},
      "grants" => [{"uid" => 100, "gid" => 100, "groups" => [300], "role" => "authority", "purposes" => %w[deliver enqueue reconcile]}]}
    @artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(
      protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root))
  end

  def teardown = FileUtils.remove_entry(@root)

  def stage(bytes = JSON.generate(@data))
    File.write(@path, bytes)
    File.chmod(0o600, @path)
    {"schema" => "ace.herdr.inbox-context-stage/v1", "codex_runtime" => {"path" => "/opt/context/runtime.json", "bytes" => 1, "sha256" => "a" * 64}, "project_id" => "project", "inbox_context_id" => "ctx",
      "configuration" => {"path" => @path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}}
  end

  def test_held_literal_configuration_is_closed_and_deeply_immutable
    selected = Configuration.load(stage: stage, artifacts: @artifacts)
    assert_equal @data, selected.data
    assert selected.frozen?
    assert_raises(FrozenError) { selected.data.fetch("grants").first["groups"] << 999 }
    @data["project_id"] = "changed"
    assert_equal "project", selected.data.fetch("project_id")
    assert_raises(NoMethodError) { Configuration.new({}, {}) }
  end

  def test_runtime_factory_refuses_a_different_stage_reference_before_bootstrap
    selected = Configuration.load(stage: stage, artifacts: @artifacts)
    bootstrap = Object.new
    called = false
    bootstrap.define_singleton_method(:with_inbox_context_installation) { |**| called = true }
    assert_raises(ERROR) do
      Ace::Herdr::Molecules::CodexRuntimeSelection.with(
        stage_reference: selected.codex_runtime_reference.merge("sha256" => "b" * 64),
        configuration: selected, installation: {}, bootstrap: bootstrap) { flunk "unselected runtime yielded" }
    end
    refute called
  end

  def test_actual_held_reader_refuses_changed_bytes_and_duplicate_decoded_keys
    literal = stage
    File.write(@path, JSON.generate(@data.merge("project_id" => "other")))
    assert_raises(ERROR) { Configuration.load(stage: literal, artifacts: @artifacts) }
    bytes = JSON.generate(@data).sub('"project_id":"project"', '"project_id":"project","project\\u005fid":"project"')
    assert_raises(ERROR) { Configuration.load(stage: stage(bytes), artifacts: @artifacts) }
  end

  def test_closed_schema_principal_separation_group_access_and_path_isolation
    changes = [->(d) { d["extra"] = true }, ->(d) { d["owner_credentials"]["uid"] = 100 },
      ->(d) { d["grants"].first["groups"] = [] }, ->(d) { d["state_root"] = "/etc/ctx" },
      ->(d) { d["deliveries_dir"] = d["state_root"] + "/events" },
      ->(d) { d["control_socket_path"] = "/run/ctx/../control.sock" },
      ->(d) { d["owner_credentials"]["groups"] = [300, 300] },
      ->(d) { d["grants"] = Array.new(65) { |i| d["grants"].first.merge("uid" => i + 1000) } }]
    changes.each do |change|
      data = Marshal.load(Marshal.dump(@data))
      change.call(data)
      assert_raises(ERROR) { Configuration.validate!(data) }
    end
    assert_raises(ERROR) { Configuration.load(stage: stage.merge("inbox_context_id" => "other"), artifacts: @artifacts) }
  end

  def test_native_release_selection_has_no_ambient_executable_environment_or_resource_fallback
    changes = [->(d) { d.delete("codex") }, ->(d) { d["herdr"]["path"] = "herdr" },
      ->(d) { d["codex"]["sha256"] = "A" * 64 }, ->(d) { d["pi"] = d["codex"].dup },
      ->(d) { d["dependencies"] = [d["codex"].dup] }, ->(d) { d["environment"]["PATH"] = "bad\0value" },
      ->(d) { d["environment"]["RUBYOPT"] = "-r arbitrary" },
      ->(d) { d["resources"] = [] }, ->(d) { d["resources"].first["access"] = "grant" },
      ->(d) { d["codex"]["bytes"] = 268_435_456 },
      ->(d) { d["codex_runtime_intent"]["bytes"] = 65_537 }]
    changes.each do |change|
      value = native_client_selection
      change.call(value)
      assert_raises(ERROR) { Configuration.native_clients!(value) }
    end
  end
  def test_static_codex_service_closure_exact_limit_and_substitutions
    value = native_client_selection
    value["dependencies"] = Array.new(506) { |index| {"path" => "/opt/dependency/#{index}", "bytes" => 1, "sha256" => "d" * 64} }
    assert Configuration.native_clients!(value)
    assert_equal 512, Configuration.native_references(value).size
    value["dependencies"] << {"path" => "/opt/dependency/extra", "bytes" => 1, "sha256" => "d" * 64}
    assert_raises(ERROR) { Configuration.native_clients!(value) }
    [->(v) { v["codex_runtime_service"]["unit_manifest"]["bytes"] = 65_537 },
     ->(v) { v["codex_runtime_service"]["unit_manifest"] = v["codex_runtime_intent"].dup },
     ->(v) { v["codex_runtime_service"]["execution_scope"]["unit_manifest_sha256"] = "e" * 64 },
     ->(v) { v["codex_runtime_service"]["extra"] = true },
     ->(v) { v.delete("codex_runtime_service") }].each do |change|
      selected = native_client_selection
      change.call(selected)
      assert_raises(ERROR) { Configuration.native_clients!(selected) }
    end
  end

  def test_static_startup_uses_same_held_configuration_but_cannot_open_runtime
    reference = stage.fetch("configuration")
    selected = Configuration.load_static(configuration_reference: reference, project_id: "project", inbox_context_id: "ctx", artifacts: @artifacts)
    assert_equal @data, selected.data
    assert_nil selected.codex_runtime_reference
    assert selected.frozen?
    assert selected.reference.frozen?
    bootstrap = Object.new
    called = false
    bootstrap.define_singleton_method(:with_inbox_context_installation) { |**| called = true }
    assert_raises(ERROR) do
      Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: nil, configuration: selected,
        installation: {}, bootstrap: bootstrap) { flunk "static-only runtime yielded" }
    end
    refute called
    assert_raises(ERROR) { Configuration.load(stage: stage.merge("codex_runtime" => nil), artifacts: @artifacts) }
  end

  def test_static_startup_refuses_wrong_identity_malformed_or_changed_artifact
    reference = stage.fetch("configuration")
    [{project_id: "foreign", inbox_context_id: "ctx"}, {project_id: "project", inbox_context_id: "foreign"},
     {project_id: "", inbox_context_id: "ctx"}].each do |identity|
      assert_raises(ERROR) { Configuration.load_static(configuration_reference: reference, **identity, artifacts: @artifacts) }
    end
    malformed = reference.merge("bytes" => 65_537)
    assert_raises(ERROR) { Configuration.load_static(configuration_reference: malformed, project_id: "project", inbox_context_id: "ctx", artifacts: @artifacts) }
    File.write(@path, JSON.generate(@data.merge("project_id" => "changed")))
    assert_raises(ERROR) { Configuration.load_static(configuration_reference: reference, project_id: "project", inbox_context_id: "ctx", artifacts: @artifacts) }
    duplicate = JSON.generate(@data).sub('"project_id":"project"', '"project_id":"project","project\\u005fid":"project"')
    literal = stage(duplicate)
    assert_raises(ERROR) { Configuration.load_static(configuration_reference: literal.fetch("configuration"), project_id: "project", inbox_context_id: "ctx", artifacts: @artifacts) }
  end

end
