# frozen_string_literal: true
require_relative "network_installation_artifacts_test"
require "ace/runtime/molecules/execution_network_selection"

class ExecutionNetworkSelectionTest < AceRuntimeTestCase
  Owner = Ace::Runtime::Molecules::ExecutionNetworkSelection
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  def setup
    @root = File.realpath(Dir.mktmpdir("network-selection-source-"))
    @reader = Ace::Runtime::Molecules::ProtectedArtifactSet.new(
      protection: NetworkInstallationArtifactsTest::FixtureProtection.new(@root))
    @selection = Owner::FIELDS.to_h { |name| [name, artifact(name, "original #{name}")] }
    @path = File.join(@root, "pointer")
    @static = @selection.slice("profile", "installer_artifact").merge(
      "current_selection_path" => "/etc/ace/execution-slots/slot/network-installation-selection.json")
    write_pointer
    original, target, expected_path = @reader.method(:read_path!), @path, @static.fetch("current_selection_path")
    @reader.define_singleton_method(:read_path!) do |path, limit:|
      raise "wrong fixed selector" unless path == expected_path
      original.call(target, limit: limit)
    end
    @owner = Owner.new(artifacts: @reader)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def artifact(name, bytes)
    path = File.join(@root, name)
    File.binwrite(path, bytes)
    File.chmod(0600, path)
    {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
  end

  def write_pointer(selection = @selection)
    File.binwrite(@path, JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot", "selection" => selection))
    File.chmod(0600, @path)
  end

  def select(static = @static, slot = "slot")
    @owner.select!(static_selection: static, slot_id: slot)
  end

  def test_exact_held_selection_is_deeply_frozen_and_new_operation_observes_pointer_advance
    original = select
    assert_equal @selection, original
    assert original.frozen?
    assert original.values.all?(&:frozen?)
    assert_raises(FrozenError) { original.fetch("report").fetch("path").replace("changed") }
    replacement = @selection.merge("report" => artifact("next-report", "new report"))
    write_pointer(replacement)
    assert_equal replacement, select
    assert_equal @selection, original
  end

  def test_static_contract_and_exact_selected_profile_producer_are_mandatory
    [@selection, @static.merge("extra" => true), @static.merge("current_selection_path" => "/tmp/other"),
      @static.merge("profile" => @selection.fetch("profile").merge("bytes" => 1.0)),
      @static.merge("installer_artifact" => @selection.fetch("installer_artifact").merge("sha256" => "b" * 64))].each do |static|
      assert_raises(Unavailable) { select(static) }
    end
    assert_raises(Unavailable) { select(@static, "../other") }
    changed = @selection.merge("profile" => artifact("other-profile", "another valid profile"))
    write_pointer(changed)
    assert_raises(Unavailable) { select }
    changed = @selection.merge("installer_artifact" => artifact("other-producer", "another valid producer"))
    write_pointer(changed)
    assert_raises(Unavailable) { select }
  end

  def test_closed_strict_utf8_bounded_pointer_and_reference_types
    valid = File.binread(@path)
    values = [valid.sub('"slot_id":"slot"', '"slot_id":"other"'), valid.sub('"slot_id":"slot"', '"slot_id":"slot","slot_id":"slot"'),
      valid.sub('"bytes":15', '"bytes":15.0'), "\xff".b, "{}", "[]", valid + "{}", " " * Owner::LIMIT + valid,
      JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot", "selection" => @selection, "extra" => true)]
    # Guaranteed strict floating reference mutation, independently of byte length.
    float = Marshal.load(Marshal.dump(@selection))
    float.fetch("report")["bytes"] = float.fetch("report")["bytes"].to_f
    values << JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot", "selection" => float)
    [0, Owner::LIMIT * 32, "15", nil].each do |bytes|
      malformed = Marshal.load(Marshal.dump(@selection))
      malformed.fetch("report")["bytes"] = bytes
      values << JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot", "selection" => malformed)
    end
    values << valid.sub('"schema":', '/*comment*/"schema":')
    values << valid.sub('"bytes":15', '"bytes":NaN')
    values << JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot", "selection" => @selection.except("report"))
    values.each do |bytes|
      File.binwrite(@path, bytes)
      assert_raises(Unavailable) { select }
    end
    File.binwrite(@path, valid)
    assert_equal @selection, select
  end

  def test_caller_static_inputs_are_snapshotted_before_protected_io
    original = @reader.method(:read_path!)
    inputs = @static
    @reader.define_singleton_method(:read_path!) do |path, limit:|
      result = original.call(path, limit: limit)
      inputs.fetch("profile")["sha256"] = "f" * 64
      result
    end
    expected = Marshal.load(Marshal.dump(@selection))
    assert_equal expected, select
    assert_equal "f" * 64, @static.fetch("profile").fetch("sha256")
  end

  def test_missing_symlink_nonregular_unsafe_changed_and_racing_objects_refuse
    valid = File.binread(@path)
    File.unlink(@path)
    assert_raises(Unavailable) { select }
    File.symlink(@selection.fetch("report").fetch("path"), @path)
    assert_raises(Unavailable) { select }
    File.unlink(@path)
    Dir.mkdir(@path)
    assert_raises(Unavailable) { select }
    Dir.rmdir(@path)
    File.binwrite(@path, valid)
    File.chmod(0666, @path)
    assert_raises(Unavailable) { select }
    File.chmod(0600, @path)
    original = @reader.method(:verify_unchanged!)
    path = @path
    @reader.define_singleton_method(:verify_unchanged!) do
      File.binwrite(path, "changed after protected read")
      original.call
    end
    assert_raises(Unavailable) { select }
  end

  def test_original_literal_graph_authenticates_after_current_pointer_rotates_without_fallback
    fixture = NetworkInstallationArtifactsTest::DiskFixture.new(@root)
    original = fixture.build
    expected = fixture.expected
    static = original.slice("profile", "installer_artifact").merge("current_selection_path" => "/etc/ace/execution-slots/slot1/network-installation-selection.json")
    read = Ace::Runtime::Molecules::ProtectedArtifactSet.instance_method(:read_path!).bind(@reader)
    target = @path
    @reader.define_singleton_method(:read_path!) do |path, limit:|
      raise "wrong original slot pointer" unless path == static.fetch("current_selection_path")
      read.call(target, limit: limit)
    end
    current = original.merge("report" => artifact("next-valid-report", File.binread(original.fetch("report").fetch("path")) + "\n"))
    File.binwrite(@path, JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot1", "selection" => current))
    assert_equal current, @owner.select!(static_selection: static, slot_id: "slot1")
    evidence = Ace::Runtime::Molecules::NetworkInstallationEvidence.new(artifacts: @reader)
    assert_equal original.fetch("report").fetch("sha256"), evidence.verify!(selection: original, expected: expected).fetch("report_sha256")
    assert_equal current.fetch("report").fetch("sha256"), evidence.verify!(selection: current, expected: expected).fetch("report_sha256")
    File.unlink(original.fetch("report").fetch("path"))
    assert_raises(Unavailable) { evidence.verify!(selection: original, expected: expected) }
    assert_equal current, @owner.select!(static_selection: static, slot_id: "slot1")
  end
end
