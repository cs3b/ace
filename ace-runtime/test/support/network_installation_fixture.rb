# frozen_string_literal: true

require "json"
require "digest"

# Synthetic root-producer content for SOURCE schema tests, never policy proof.
class NetworkInstallationFixture
  attr_reader :profile, :expected, :files, :reads
  attr_accessor :report_edit, :trace_edit, :checks_edit, :profile_bytes, :report_bytes

  def initialize
    @files, @reads = {}, []
    @profile = {"version" => 1, "profile_id" => "internet-profile", "slot_id" => "slot1",
      "namespace_path" => "/run/netns/slot1", "families" => [
        {"family" => "ipv4", "mode" => "enabled"}, {"family" => "ipv6", "mode" => "enabled"}],
      "protected_controls" => [{"id" => "host-control", "family" => "ipv4", "kind" => "host_process",
        "address_ranges" => ["10.0.0.0/8"], "protocol" => "tcp", "ports" => [22, 443]}],
      "loopback_tools" => [{"id" => "tool", "family" => "ipv4", "protocol" => "tcp", "address" => "127.0.0.1",
        "port" => 8080, "artifact_sha256" => "a" * 64}],
      "credential_profiles" => [{"id" => "provider", "kind" => "provider", "helper_artifacts" => [],
        "configuration_artifacts" => [], "authority" => "remote_only"}]}
    @expected = {"slot_id" => "slot1", "namespace_path" => "/run/netns/slot1",
      "boot_id" => "11111111-1111-4111-8111-111111111111", "namespace_identity" => {"device" => 5, "inode" => 7},
      "installer_artifact_sha256" => Digest::SHA256.hexdigest("producer source fixture")}
  end

  def store(path, bytes)
    @files[path] = bytes
    {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
  end

  def store_json(path, object) = store(path, JSON.generate(object))

  def build
    @reads.clear
    producer = store("/evidence/producer", "producer source fixture")
    policy = store("/evidence/policy", "opaque domain effective-policy fixture")
    raw = store("/evidence/raw", "synthetic setup/correlation observations")
    topology = store("/evidence/topology", "opaque domain complete-topology fixture")
    profile = store("/evidence/profile", profile_bytes || JSON.generate(@profile))
    context = {"version" => 1, "report_id" => "22222222-2222-4222-8222-222222222222",
      "boot_id" => expected.fetch("boot_id"), "namespace_identity" => expected.fetch("namespace_identity"),
      "profile_sha256" => profile.fetch("sha256"), "policy_export_sha256" => policy.fetch("sha256")}
    tuples = [["effective_policy_export", "all", "policy"], ["namespace_identity", "all", "namespace"],
      ["untrusted_policy_mutation_denied", "all", "policy"]]
    @profile.fetch("families").each do |entry|
      family = entry.fetch("family")
      tuples << ["unsolicited_ingress_denied", family, "ingress"]
      if entry.fetch("mode") == "enabled"
        tuples << ["ordinary_internet_egress_allowed", family, "internet"]
        tuples << ["dns_response_allowed", family, "dns"]
      else
        tuples << ["family_disabled_enforced", family, family]
      end
    end
    @profile.fetch("protected_controls").each { |entry| tuples << ["host_internal_controls_denied", entry["family"], entry["id"]] }
    @profile.fetch("loopback_tools").each { |entry| tuples << ["loopback_scope_only", entry["family"], entry["id"]] }
    @profile.fetch("credential_profiles").each { |entry| tuples << ["credential_no_local_control", "all", entry["id"]] }
    checks = tuples.each_with_index.map do |(id, family, target), index|
      trace = JSON.parse(JSON.generate(context)).merge("check_id" => id, "family" => family, "target_id" => target,
        "producer_artifact_sha256" => producer.fetch("sha256"), "observations" => [
          {"kind" => "flow", "artifact_refs" => [raw], "summary" => {"result" => "pass", "procedure_id" => "fixed-domain-procedure"}}])
      trace_edit&.call(trace, index)
      {"check_id" => id, "family" => family, "target_id" => target, "outcome" => "pass",
        "evidence" => store_json("/evidence/trace-#{index}", trace)}
    end
    checks_edit&.call(checks)
    report = context.merge("profile_id" => @profile.fetch("profile_id"), "slot_id" => "slot1",
      "namespace_path" => expected.fetch("namespace_path"), "observed_topology" => topology,
      "installer_artifact_sha256" => producer.fetch("sha256"), "producer_source_sha" => "b" * 40,
      "completed_at" => "2026-10-05T12:00:00Z", "checks" => checks)
    report_edit&.call(report)
    report_ref = store("/evidence/report", report_bytes || JSON.generate(report))
    {"profile" => profile, "policy_export" => policy, "report" => report_ref, "installer_artifact" => producer}
  end

  def with
    yield self
  end

  def read!(ref)
    @reads << ref.fetch("path") unless @reads.include?(ref.fetch("path"))
    bytes = @files.fetch(ref.fetch("path")) { raise Errno::ENOENT }
    unless ref.fetch("bytes") == bytes.bytesize && ref.fetch("sha256") == Digest::SHA256.hexdigest(bytes)
      raise Ace::Runtime::RuntimeUnavailableError, "source fixture content mismatch"
    end
    bytes
  end

  def verify_unchanged! = true
end
