# frozen_string_literal: true
require_relative "network_installation_artifacts_test"
require "ace/runtime/molecules/execution_boot_baseline"

class ExecutionBootBaselineTest < AceRuntimeTestCase
  Baseline = Ace::Runtime::Molecules::ExecutionBootBaseline
  Unavailable = Ace::Runtime::RuntimeUnavailableError
  BOOT = "12345678-1234-1234-1234-123456789abc"

  # Reuses the existing controlled artifact trust seam; content/FD/mode/digest
  # reads are real, host ownership/mount proof remains synthetic.
  def setup
    @root = File.realpath(Dir.mktmpdir("boot-evidence-source-"))
    File.chmod(0700, @root)
    @reader = Ace::Runtime::Molecules::ProtectedArtifactSet.new(
      protection: NetworkInstallationArtifactsTest::FixtureProtection.new(@root))
    @producer = artifact("installer", "trusted fixed installer")
    @expected = {"slot_id" => "slot", "boot_id" => BOOT, "deployment_digest" => "a" * 64,
      "installer_artifact" => @producer}
    @payload = {"schema" => "ace.execution-boot-baseline/v1", "slot_id" => "slot", "boot_id" => BOOT,
      "deployment_digest" => "a" * 64, "producer_artifact" => @producer,
      "original_host_context" => {"pid" => 1, "uid" => 0, "gid" => 0, "started_at" => "linux:#{BOOT}:1"},
      "host_ipc_namespace_identity" => {"device" => 4, "inode" => 90}, "host_ptmx_link" => "pts/ptmx",
      "host_devpts_identity" => {"device" => 9, "inode" => 1, "major_minor" => "9:1"},
      "selected_devpts" => {"path" => "/run/ace/execution-slots/slot/devpts", "device" => 8, "inode" => 106, "major_minor" => "8:1", "ptmx_inode" => 500}}
    @ref = artifact("original", JSON.generate(@payload))
    @pointer = artifact("pointer", JSON.generate("schema" => "ace.execution-boot-selection/v1", "slot_id" => "slot", "baseline" => @ref))
    original = @reader.method(:read_path!)
    pointer_path = @pointer.fetch("path")
    @reader.define_singleton_method(:read_path!) do |path, limit:|
      raise "unexpected fixed boot selector" unless path == "/etc/ace/execution-slots/slot/boot-baseline-selection.json"
      original.call(pointer_path, limit: limit)
    end
    @owner = Baseline.new(artifacts: @reader)
  end

  def teardown
    FileUtils.remove_entry(@root) if File.exist?(@root)
  end

  def artifact(name, bytes)
    path = File.join(@root, name)
    File.binwrite(path, bytes)
    File.chmod(0600, path)
    {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
  end

  def verify_payload(payload)
    @owner.verify!(selection: artifact("case", JSON.generate(payload)), expected: @expected)
  end

  def test_exact_original_artifact_and_fresh_pointer_selection_are_immutable
    original = @owner.verify!(selection: @ref, expected: @expected)
    assert_equal @payload, original
    assert original.frozen?
    assert original.fetch("host_ipc_namespace_identity").frozen?
    selected = @owner.select!(expected: @expected)
    assert_equal @ref, selected.fetch("selection")
    assert_equal original, selected.fetch("baseline")
    assert selected.fetch("selection").frozen?
  end
  def test_selected_devpts_closed_original_backing_and_host_link_are_authenticated
    [->(p) { p.delete("selected_devpts") }, ->(p) { p["host_ptmx_link"] = "/dev/pts/ptmx" },
      ->(p) { p["selected_devpts"]["path"] = "/run/ace/execution-slots/other/devpts" },
      ->(p) { p["selected_devpts"]["device"] = p["host_devpts_identity"]["device"] },
      ->(p) { p["selected_devpts"]["major_minor"] = p["host_devpts_identity"]["major_minor"] },
      ->(p) { p["selected_devpts"]["ptmx_inode"] = 500.0 },
      ->(p) { p["selected_devpts"]["extra"] = true }].each do |mutate|
      payload = Marshal.load(Marshal.dump(@payload))
      mutate.call(payload)
      assert_raises(Unavailable) { verify_payload(payload) }
    end
  end

  def test_history_authenticates_original_ref_without_mutable_pointer_fallback
    File.write(@pointer.fetch("path"), "missing current selection")
    assert_equal @payload, @owner.verify!(selection: @ref, expected: @expected)
    assert_raises(Unavailable) { @owner.select!(expected: @expected) }
    File.unlink(@ref.fetch("path"))
    assert_raises(Unavailable) { @owner.verify!(selection: @ref, expected: @expected) }
  end

  def test_boot_slot_mapping_and_producer_context_must_match_original_selection
    {"boot_id" => "22345678-1234-1234-1234-123456789abc", "slot_id" => "other", "deployment_digest" => "b" * 64,
      "producer_artifact" => @producer.merge("sha256" => "b" * 64)}.each do |key, value|
      assert_raises(Unavailable, key) { verify_payload(@payload.merge(key => value)) }
    end
    changed = @ref.merge("sha256" => "c" * 64)
    assert_raises(Unavailable) { @owner.verify!(selection: changed, expected: @expected) }
  end

  def test_original_root_pid1_context_and_producer_size_reject_json_numeric_coercion
    %w[pid uid gid].each do |key|
      context = @payload.fetch("original_host_context").merge(key => @payload.fetch("original_host_context").fetch(key).to_f)
      assert_raises(Unavailable, key) { verify_payload(@payload.merge("original_host_context" => context)) }
    end
    refute_value = @producer.merge("bytes" => @producer.fetch("bytes").to_f)
    assert_raises(Unavailable) { verify_payload(@payload.merge("producer_artifact" => refute_value)) }
    assert_raises(Unavailable) { verify_payload(@payload.merge("original_host_context" => @payload.fetch("original_host_context").merge("pid" => 2))) }
  end

  def test_host_birth_is_canonical_linux_birth_at_original_boot
    ["unverified", "linux:#{BOOT}:01", "linux:#{BOOT}:-1", "linux:22345678-1234-1234-1234-123456789abc:1"].each do |birth|
      context = @payload.fetch("original_host_context").merge("started_at" => birth)
      assert_raises(Unavailable) { verify_payload(@payload.merge("original_host_context" => context)) }
    end
  end

  def test_duplicate_json_invalid_utf8_and_oversized_content_refuse
    ["{\"schema\":1,\"schema\":2}", "\xff".b, "a" * (Baseline::LIMIT + 1)].each do |bytes|
      assert_raises(Unavailable) { @owner.verify!(selection: artifact("bad", bytes), expected: @expected) }
    end
  end

  def test_held_original_and_producer_are_rechecked_before_return
    original = @reader.method(:verify_unchanged!)
    path = @producer.fetch("path")
    @reader.define_singleton_method(:verify_unchanged!) do
      File.binwrite(path, "producer replaced")
      original.call
    end
    assert_raises(Unavailable) { @owner.verify!(selection: @ref, expected: @expected) }
  end
end
