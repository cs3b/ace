# frozen_string_literal: true

require "test_helper"
require "ace/herdr/molecules/inbox_context_service_configuration"
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
      "grants" => [{"uid" => 100, "gid" => 100, "groups" => [300], "role" => "authority", "purposes" => %w[deliver enqueue]}]}
    @artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(
      protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root))
  end

  def teardown = FileUtils.remove_entry(@root)

  def stage(bytes = JSON.generate(@data))
    File.write(@path, bytes)
    File.chmod(0o600, @path)
    {"schema" => "ace.herdr.inbox-context-stage/v1", "project_id" => "project", "inbox_context_id" => "ctx",
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
      ->(d) { d["codex"]["bytes"] = 268_435_456 }]
    changes.each do |change|
      value = native_client_selection
      change.call(value)
      assert_raises(ERROR) { Configuration.native_clients!(value) }
    end
  end
end
