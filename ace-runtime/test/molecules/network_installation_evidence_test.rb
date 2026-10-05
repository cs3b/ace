# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/network_installation_fixture"

class NetworkInstallationEvidenceTest < AceRuntimeTestCase
  Evidence = Ace::Runtime::Molecules::NetworkInstallationEvidence
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  def setup
    @fixture = NetworkInstallationFixture.new
    @evidence = Evidence.new(artifacts: @fixture)
  end

  def verify(selection = @fixture.build, expected = @fixture.expected)
    @evidence.verify!(selection: selection, expected: expected)
  end

  def refused
    assert_raises(Unavailable) { verify }
  end

  def test_exact_success_is_deeply_immutable_and_contains_only_authentication_context
    selection = @fixture.build
    result = verify(selection)
    assert_equal %w[boot_id installer_artifact_sha256 namespace_identity namespace_path policy_export_sha256
      profile_sha256 report_id report_sha256 slot_id].sort, result.keys.sort
    assert_equal selection.fetch("report").fetch("sha256"), result.fetch("report_sha256")
    assert_equal @fixture.expected.fetch("namespace_identity"), result.fetch("namespace_identity")
    assert result.frozen?
    assert result.keys.all?(&:frozen?)
    assert result.values.all?(&:frozen?)
    assert_raises(FrozenError) { result.fetch("namespace_identity")["inode"] = 123 }
    assert_raises(FrozenError) { result.fetch("slot_id") << "other" }
    refute result.key?("boundary_verified")
    assert_equal @fixture.files.keys.sort, @fixture.reads.sort
    assert_equal result, verify(selection)
  end

  def test_disabled_families_still_require_ingress_and_explicit_disabled_enforcement
    @fixture.profile.fetch("families").each { |entry| entry["mode"] = "disabled" }
    assert verify
    @fixture.checks_edit = ->(checks) { checks.reject! { |entry| entry["check_id"] == "family_disabled_enforced" } }
    refused
  end

  def test_checks_are_the_exact_unique_profile_derived_set
    [->(checks) { checks.pop }, ->(checks) { checks << checks.first.dup },
      ->(checks) { checks.first["check_id"] = "caller_verified" },
      ->(checks) { checks.first["target_id"] = "other" },
      ->(checks) { checks.first["family"] = "ipv4" },
      ->(checks) { checks.first["outcome"] = "skipped" },
      ->(checks) { checks.first["claimed_verified"] = true }].each do |edit|
      @fixture.checks_edit = edit
      refused
    end
  end

  def test_expected_and_selection_are_closed_and_no_missing_evidence_fallback
    selection = @fixture.build
    [nil, {}, selection.merge("claimed_verified" => true), selection.reject { |key, _| key == "policy_export" }].each do |bad|
      assert_raises(Unavailable) { verify(bad) }
    end
    [nil, @fixture.expected.merge("namespace_identity" => {"device" => 0, "inode" => 7}),
      @fixture.expected.merge("boot_id" => "UPPERCASE"), @fixture.expected.merge("caller" => "root")].each do |bad|
      assert_raises(Unavailable) { verify(selection, bad) }
    end
    @fixture.files.delete(selection.fetch("policy_export").fetch("path"))
    assert_raises(Unavailable) { verify(selection) }
  end

  def test_report_rejects_each_context_mismatch_and_non_integer_namespace
    {"slot_id" => "other", "profile_id" => "other", "boot_id" => "33333333-3333-4333-8333-333333333333",
      "namespace_path" => "/run/netns/other", "namespace_identity" => {"device" => 5.0, "inode" => 7},
      "profile_sha256" => "a" * 64, "policy_export_sha256" => "a" * 64,
      "installer_artifact_sha256" => "a" * 64}.each do |key, value|
      @fixture.report_edit = ->(report) { report[key] = value }
      refused
    end
  end

  def test_report_requires_closed_schema_version_source_and_utc_timestamp
    [->(report) { report["version"] = 1.0 }, ->(report) { report["extra"] = true },
      ->(report) { report["producer_source_sha"] = "b" * 39 },
      ->(report) { report["completed_at"] = "2026-10-05T12:00:00+01:00" },
      ->(report) { report["completed_at"] = "2026-02-31T12:00:00Z" },
      ->(report) { report["report_id"] = "22222222-2222-4222-8222-22222222222A" }].each do |edit|
      @fixture.report_edit = edit
      refused
    end
    @fixture.report_edit = ->(report) { report["completed_at"] = "2026-10-05T12:00:00.123+00:00" }
    assert verify
  end

  def test_trace_requires_complete_context_exact_tuple_producer_and_nonempty_raw_observations
    [->(trace) { trace["namespace_identity"]["inode"] = 7.0 },
      ->(trace) { trace["boot_id"] = "33333333-3333-4333-8333-333333333333" },
      ->(trace) { trace["report_id"] = "33333333-3333-4333-8333-333333333333" },
      ->(trace) { trace["producer_artifact_sha256"] = "a" * 64 },
      ->(trace) { trace["target_id"] = "other" },
      ->(trace) { trace["family"] = "ipv6" },
      ->(trace) { trace["check_id"] = "other" },
      ->(trace) { trace["profile_sha256"] = "a" * 64 },
      ->(trace) { trace["policy_export_sha256"] = "a" * 64 },
      ->(trace) { trace["extra"] = true },
      ->(trace) { trace["observations"] = [] },
      ->(trace) { trace["observations"].first["artifact_refs"] = [] },
      ->(trace) { trace["observations"].first["kind"] = "timeout" },
      ->(trace) { trace["observations"].first["summary"]["result"] = true },
      ->(trace) { trace["observations"].first["summary"]["procedure_id"] = "caller command" }].each do |edit|
      setup
      @fixture.trace_edit = ->(trace, index) { edit.call(trace) if index.zero? }
      refused
    end
  end

  def test_no_duplicate_json_keys_or_invalid_utf8_or_nonfinite_numbers
    ['{"version":1,"version":1}', "{\"x\":\"\xff\"}".b, '{"x":NaN}', '{"x":Infinity}'].each do |bytes|
      @fixture.profile_bytes = bytes
      refused
      @fixture.profile_bytes = nil
      @fixture.report_bytes = bytes
      refused
      @fixture.report_bytes = nil
    end
    @fixture.profile_bytes = JSON.generate(@fixture.profile).sub('"profile_id":"internet-profile"',
      '"profile_id":"wrong","profile_id":"internet-profile"')
    refused
  end

  def test_profile_controls_canonical_ranges_families_ports_and_helper_authority
    cases = [->(p) { p["extra"] = true }, ->(p) { p["version"] = "1" },
      ->(p) { p["slot_id"] = "other" }, ->(p) { p["namespace_path"] = "/run/netns/other" },
      ->(p) { p["profile_id"] = "ü" }, ->(p) { p["families"].last["family"] = "ipv4" },
      ->(p) { p["families"].last["mode"] = "unavailable" },
      ->(p) { p["protected_controls"].first["kind"] = "internet" },
      ->(p) { p["protected_controls"].first["protocol"] = "icmp" },
      ->(p) { p["protected_controls"].first["ports"] = [0] },
      ->(p) { p["protected_controls"].first["ports"] = [443.0] },
      ->(p) { p["protected_controls"].first["ports"] = [443, 443] },
      ->(p) { p["protected_controls"].first["address_ranges"] = ["10.1.1.1/8"] },
      ->(p) { p["protected_controls"].first["address_ranges"] = ["::/0"] },
      ->(p) { p["protected_controls"].first["address_ranges"] = ["10.0.0.0/08"] },
      ->(p) { p["loopback_tools"].first["address"] = "0.0.0.0" },
      ->(p) { p["loopback_tools"].first["artifact_sha256"] = "A" * 64 },
      ->(p) { p["credential_profiles"].first["authority"] = "host_login" },
      ->(p) { p["credential_profiles"].first["kind"] = "ssh" }]
    cases.each do |edit|
      setup
      edit.call(@fixture.profile)
      refused
    end
  end

  def test_ipv6_canonical_control_loopback_and_all_ports_are_supported
    control = @fixture.profile.fetch("protected_controls").first
    control.merge!("family" => "ipv6", "address_ranges" => ["fd00::/8"], "ports" => "all", "protocol" => "udp")
    @fixture.profile.fetch("loopback_tools").first.merge!("family" => "ipv6", "address" => "::1", "protocol" => "udp")
    assert verify
    control["address_ranges"] = ["FD00::/8"]
    refused
  end

  def test_profile_budget_counts_outer_entries_and_not_nested_ports
    @fixture.profile.fetch("protected_controls").first["ports"] = (1..300).to_a
    assert verify
    @fixture.profile["loopback_tools"] = Array.new(253) { |n|
      @fixture.profile.fetch("loopback_tools").first.merge("id" => "tool#{n}") }
    refused # 2 families + 1 control + 253 tools + 1 credential = 257
  end

  def test_artifact_references_require_exact_digest_length_path_and_schema
    selection = @fixture.build
    [->(ref) { ref["path"] = "/evidence/../profile" }, ->(ref) { ref["path"] = "relative" },
      ->(ref) { ref["path"] = "/evidence/profile\0" }, ->(ref) { ref["bytes"] = 0 },
      ->(ref) { ref["bytes"] = 1.0 }, ->(ref) { ref["bytes"] = 1_048_577 },
      ->(ref) { ref["sha256"] = "a" * 63 }, ->(ref) { ref["extra"] = true }].each do |edit|
      candidate = Marshal.load(Marshal.dump(selection))
      edit.call(candidate.fetch("profile"))
      assert_raises(Unavailable) { verify(candidate) }
    end
    @fixture.files["/evidence/raw"] = "tampered observations"
    assert_raises(Unavailable) { verify(selection) }
  end

  def test_consistent_shared_artifact_refs_are_allowed_but_conflicts_refuse
    @fixture.trace_edit = lambda do |trace, index|
      if index.zero?
        ref = trace["observations"].first["artifact_refs"].first.dup
        ref["sha256"] = "a" * 64
        trace["observations"].first["artifact_refs"] << ref
      end
    end
    refused
  end

  def test_observation_bounds_and_trace_ref_bounds_are_exact
    @fixture.trace_edit = ->(trace, index) { trace["observations"] *= 257 if index.zero? }
    refused
    @fixture.trace_edit = ->(trace, index) { trace["observations"].first["artifact_refs"] *= 17 if index.zero? }
    refused
    @fixture.trace_edit = ->(trace, index) { trace["observations"] *= 256 if index.zero? }
    assert verify
  end
  def test_otherwise_valid_json_with_comments_and_nested_duplicate_keys_refuses
    valid = JSON.generate(@fixture.profile)
    ["/* producer comment */" + valid,
      valid.sub('"mode":"enabled"', '"mode":"disabled","mode":"enabled"'),
      valid.sub('"profile_id":"internet-profile"', '"profile_id":"internet-profile","profile_id":"internet-profile"')].each do |bytes|
      @fixture.profile_bytes = bytes
      refused
    end
  end

  def test_recursive_artifact_graph_refuses_even_with_a_fixture_integrity_boundary
    selection = @fixture.build
    profile = JSON.parse(@fixture.files.fetch("/evidence/profile"))
    profile.fetch("credential_profiles").first["helper_artifacts"] = [selection.fetch("report")]
    @fixture.files["/evidence/profile"] = JSON.generate(profile)
    report = JSON.parse(@fixture.files.fetch("/evidence/report"))
    report["observed_topology"] = selection.fetch("profile")
    @fixture.files["/evidence/report"] = JSON.generate(report)
    # A cyclic digest graph has no practical producer fixed point. Isolate the
    # integrity reader only to test the schema owner's explicit cycle refusal.
    @fixture.stub(:read!, ->(ref) { @fixture.files.fetch(ref.fetch("path")) }) do
      error = assert_raises(Unavailable) { verify(selection) }
      assert_match(/cycle/, error.message)
    end
  end

  def test_gem_declares_the_existing_strict_json_feature_dependency
    json = Gem.loaded_specs.fetch("ace-runtime").dependencies.find { |dependency| dependency.name == "json" }
    assert json
    refute json.requirement.satisfied_by?(Gem::Version.new("2.19.9"))
    assert json.requirement.satisfied_by?(Gem::Version.new("2.20.0"))
    assert json.requirement.satisfied_by?(Gem::Version.new("2.21.2"))
    refute json.requirement.satisfied_by?(Gem::Version.new("3.0.0"))
  end

end
