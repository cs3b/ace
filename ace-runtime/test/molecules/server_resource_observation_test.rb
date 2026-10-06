# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/server_resource_observation"

class ServerResourceObservationTest < AceRuntimeTestCase
  Observation = Ace::Runtime::Molecules::ServerResourceObservation
  Kernel = Struct.new(:identity, :changed, :calls) do
    def live!(expected)
      raise Ace::Runtime::RuntimeUnavailableError, "incarnation changed" unless identity == expected
      true
    end
    def capture(_pid)
      self.calls += 1
      calls > 1 && changed ? changed : identity.dup
    end
    def same?(left, right) = left == right
  end
  Files = Struct.new(:result, :seen) do
    def observe(pid, entries)
      self.seen = [pid, entries]
      result
    end
  end

  def test_same_server_incarnation_bounds_real_source_observation_owner
    server = {"pid" => 81, "uid" => 13001, "started_at" => "birth"}
    expected = {"mount_namespace_identity" => {"device" => 2, "inode" => 9}, "resource_identities" => [], "resource_topology" => []}
    files = Files.new(expected)
    kernel = Kernel.new(server, nil, 0)
    entries = [{"host_path" => "/private", "view_path" => "/scratch"}]
    assert_equal expected, Observation.new(kernel: kernel, files: files).observe!(server: server, entries: entries)
    assert_equal [81, entries], files.seen
    assert_equal 2, kernel.calls
  end

  def test_credential_or_birth_change_after_collection_refuses
    server = {"pid" => 81, "uid" => 13001, "started_at" => "birth"}
    kernel = Kernel.new(server, server.merge("started_at" => "replacement"), 0)
    files = Files.new({"resource_identities" => []})
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      Observation.new(kernel: kernel, files: files).observe!(server: server, entries: [])
    end
  end
end
