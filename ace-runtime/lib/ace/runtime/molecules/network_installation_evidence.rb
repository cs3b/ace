# frozen_string_literal: true

require "json"
require "ipaddr"
require "date"
require_relative "protected_artifact_set"

module Ace
  module Runtime
    module Molecules
      # Authenticates bounded root-produced installation content. Actual policy
      # comparison/flow observations belong to the trusted domain producer; the
      # installed owner independently pins the nsfs object and supplies expected.
      class NetworkInstallationEvidence
        ID = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        SHA = /\A[0-9a-f]{64}\z/
        UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
        FAMILIES = %w[ipv4 ipv6].freeze
        PROFILE_KEYS = %w[version profile_id slot_id namespace_path families protected_controls loopback_tools
          credential_profiles].freeze
        REPORT_KEYS = %w[version report_id profile_id slot_id boot_id namespace_path namespace_identity profile_sha256
          policy_export_sha256 observed_topology installer_artifact_sha256 producer_source_sha
          completed_at checks].freeze
        TRACE_KEYS = %w[version report_id check_id family target_id boot_id namespace_identity profile_sha256
          policy_export_sha256 producer_artifact_sha256 observations].freeze
        EXPECTED_KEYS = %w[slot_id namespace_path boot_id namespace_identity installer_artifact_sha256].freeze

        def self.verify!(selection:, expected:)
          new.verify!(selection: selection, expected: expected)
        end

        # The injectable content reader is a source-test seam, never a runtime
        # transport selector or alternate trust root.
        def initialize(artifacts: ProtectedArtifactSet.new)
          @artifacts = artifacts
        end

        def verify!(selection:, expected:)
          object!(selection, %w[profile policy_export report installer_artifact])
          expected!(expected)
          @edges, @refs = Hash.new { |hash, path| hash[path] = [] }, {}
          @artifacts.with do
            selection.each_value { |ref| artifact!(ref) }
            unless selection.fetch("installer_artifact").fetch("sha256") == expected.fetch("installer_artifact_sha256")
              refuse!("selected network producer differs")
            end
            profile = json!(selection.fetch("profile"))
            profile!(profile, expected, selection.fetch("profile").fetch("path"))
            report = json!(selection.fetch("report"))
            report!(report, profile, selection, expected)
            graph_acyclic!
            @artifacts.verify_unchanged!
            result = report.slice("report_id", "boot_id", "slot_id", "namespace_path", "namespace_identity",
              "profile_sha256", "policy_export_sha256", "installer_artifact_sha256")
            result["report_sha256"] = selection.fetch("report").fetch("sha256")
            immutable(result)
          end
        rescue SystemCallError, IOError, JSON::ParserError, IPAddr::Error, KeyError, TypeError, ArgumentError
          refuse!("network installation evidence cannot be verified")
        ensure
          @edges = @refs = nil
        end

        private

        def expected!(value)
          object!(value, EXPECTED_KEYS)
          id!(value.fetch("slot_id"))
          path!(value.fetch("namespace_path"))
          format!(value.fetch("boot_id"), UUID)
          identity!(value.fetch("namespace_identity"))
          format!(value.fetch("installer_artifact_sha256"), SHA)
        end

        def profile!(value, expected, profile_path)
          object!(value, PROFILE_KEYS)
          version!(value)
          %w[profile_id slot_id].each { |key| id!(value.fetch(key)) }
          path!(value.fetch("namespace_path"))
          %w[slot_id namespace_path].each { |key| equal!(value.fetch(key), expected.fetch(key)) }
          families = collection!(value.fetch("families"), "family", min: 2)
          equal!(families.map { |entry| entry.fetch("family") }.sort, FAMILIES)
          families.each do |entry|
            object!(entry, %w[family mode])
            enum!(entry.fetch("mode"), %w[enabled disabled])
          end
          controls = collection!(value.fetch("protected_controls"), "id")
          tools = collection!(value.fetch("loopback_tools"), "id")
          credentials = collection!(value.fetch("credential_profiles"), "id")
          entries = families.size + controls.size + tools.size + credentials.size
          refuse!("network profile collections are oversized") if entries > 256
          controls.each { |entry| control!(entry) }
          tools.each { |entry| loopback!(entry) }
          credentials.each { |entry| credential!(entry, profile_path) }
        end

        def control!(entry)
          object!(entry, %w[id family kind address_ranges protocol ports])
          id!(entry.fetch("id"))
          enum!(entry.fetch("family"), FAMILIES)
          enum!(entry.fetch("kind"), %w[host_process internal_process protected_storage])
          enum!(entry.fetch("protocol"), %w[tcp udp])
          ranges = array!(entry.fetch("address_ranges"), min: 1)
          unique!(ranges)
          ranges.each { |range| cidr!(range, entry.fetch("family")) }
          ports = entry.fetch("ports")
          unless ports == "all"
            array!(ports, min: 1).each { |port| port!(port) }
            unique!(ports)
          end
        end

        def loopback!(entry)
          object!(entry, %w[id family protocol address port artifact_sha256])
          id!(entry.fetch("id"))
          enum!(entry.fetch("family"), FAMILIES)
          enum!(entry.fetch("protocol"), %w[tcp udp])
          equal!(entry.fetch("address"), entry.fetch("family") == "ipv4" ? "127.0.0.1" : "::1")
          port!(entry.fetch("port"))
          format!(entry.fetch("artifact_sha256"), SHA)
        end

        def credential!(entry, profile_path)
          object!(entry, %w[id kind helper_artifacts configuration_artifacts authority])
          id!(entry.fetch("id"))
          enum!(entry.fetch("kind"), %w[provider dns remote_git])
          equal!(entry.fetch("authority"), "remote_only")
          %w[helper_artifacts configuration_artifacts].each do |key|
            refs = array!(entry.fetch(key))
            unique!(refs.map { |ref| artifact!(ref, parent: profile_path); ref.fetch("path") })
          end
        end

        def report!(value, profile, selection, expected)
          object!(value, REPORT_KEYS)
          version!(value)
          %w[report_id boot_id].each { |key| format!(value.fetch(key), UUID) }
          %w[profile_id slot_id].each { |key| id!(value.fetch(key)); equal!(value.fetch(key), profile.fetch(key)) }
          %w[namespace_path boot_id namespace_identity installer_artifact_sha256].each do |key|
            equal!(value.fetch(key), expected.fetch(key))
          end
          identity!(value.fetch("namespace_identity"))
          %w[profile policy_export installer_artifact].each do |key|
            format!(value.fetch("#{key}_sha256"), SHA)
            equal!(value.fetch("#{key}_sha256"), selection.fetch(key).fetch("sha256"))
          end
          format!(value.fetch("producer_source_sha"), /\A[0-9a-f]{40}\z/)
          timestamp!(value.fetch("completed_at"))
          artifact!(value.fetch("observed_topology"), parent: selection.fetch("report").fetch("path"))
          checks = array!(value.fetch("checks"), min: 1)
          actual = checks.map do |check|
            object!(check, %w[check_id family target_id outcome evidence])
            id!(check.fetch("check_id"))
            id!(check.fetch("target_id"))
            enum!(check.fetch("family"), FAMILIES + ["all"])
            equal!(check.fetch("outcome"), "pass")
            check.values_at("check_id", "family", "target_id")
          end
          unique!(actual)
          equal!(actual.sort, required_checks(profile).sort)
          checks.each do |check|
            ref = check.fetch("evidence")
            trace!(json!(ref, parent: selection.fetch("report").fetch("path")), ref, check, value)
          end
        end

        def required_checks(profile)
          checks = [["effective_policy_export", "all", "policy"], ["namespace_identity", "all", "namespace"],
            ["untrusted_policy_mutation_denied", "all", "policy"]]
          profile.fetch("families").each do |entry|
            family = entry.fetch("family")
            checks << ["unsolicited_ingress_denied", family, "ingress"]
            if entry.fetch("mode") == "enabled"
              %w[ordinary_internet_egress_allowed dns_response_allowed].each { |id|
                checks << [id, family, id == "dns_response_allowed" ? "dns" : "internet"] }
            else
              checks << ["family_disabled_enforced", family, family]
            end
          end
          profile.fetch("protected_controls").each { |entry|
            checks << ["host_internal_controls_denied", entry.fetch("family"), entry.fetch("id")] }
          profile.fetch("loopback_tools").each { |entry|
            checks << ["loopback_scope_only", entry.fetch("family"), entry.fetch("id")] }
          profile.fetch("credential_profiles").each { |entry|
            checks << ["credential_no_local_control", "all", entry.fetch("id")] }
          checks
        end

        def trace!(trace, reference, check, report)
          object!(trace, TRACE_KEYS)
          version!(trace)
          %w[report_id boot_id namespace_identity profile_sha256 policy_export_sha256].each do |key|
            equal!(trace.fetch(key), report.fetch(key))
          end
          %w[check_id family target_id].each { |key| equal!(trace.fetch(key), check.fetch(key)) }
          equal!(trace.fetch("producer_artifact_sha256"), report.fetch("installer_artifact_sha256"))
          array!(trace.fetch("observations"), min: 1, max: 256).each do |observation|
            object!(observation, %w[kind artifact_refs summary])
            enum!(observation.fetch("kind"), %w[policy_comparison flow namespace artifact_inspection])
            object!(observation.fetch("summary"), %w[result procedure_id])
            equal!(observation.fetch("summary").fetch("result"), "pass")
            id!(observation.fetch("summary").fetch("procedure_id"))
            refs = array!(observation.fetch("artifact_refs"), min: 1, max: 16)
            refs.each { |ref| artifact!(ref, parent: reference.fetch("path")) }
          end
        end

        def artifact!(reference, parent: nil)
          object!(reference, %w[path sha256 bytes])
          path = reference.fetch("path")
          path!(path)
          format!(reference.fetch("sha256"), SHA)
          size = reference.fetch("bytes")
          unless size.is_a?(Integer) && size.between?(1, ProtectedArtifactSet::LIMIT)
            refuse!("network artifact byte bound is invalid")
          end
          previous = @refs[path]
          refuse!("network artifact references conflict") if previous && previous != reference
          @refs[path] = reference
          @edges[parent] << path if parent
          @artifacts.read!(reference)
        end

        def json!(reference, parent: nil)
          bytes = artifact!(reference, parent: parent).dup.force_encoding(Encoding::UTF_8)
          refuse!("network evidence is not UTF-8") unless bytes.valid_encoding?
          JSON.parse(bytes, max_nesting: 64, allow_nan: false, create_additions: false,
            allow_duplicate_key: false, allow_comments: false,
            allow_invalid_escape: false, allow_control_characters: false)
        end

        def graph_acyclic!
          visited, pending = {}, {}
          visit = lambda do |path|
            refuse!("network artifact reference cycle") if pending[path]
            return if visited[path]
            pending[path] = true
            @edges[path].each { |child| visit.call(child) }
            pending.delete(path)
            visited[path] = true
          end
          @refs.each_key { |path| visit.call(path) }
        end

        def cidr!(value, family)
          refuse!("network address range is invalid") unless value.is_a?(String) &&
            (match = /\A([^\/]+)\/(0|[1-9][0-9]{0,2})\z/.match(value))
          ip = IPAddr.new(value)
          bits = family == "ipv4" ? 32 : 128
          refuse!("network address family or canonical CIDR differs") unless
            (family == "ipv4" ? ip.ipv4? : ip.ipv6?) && match[2].to_i <= bits &&
            "#{ip.to_s}/#{match[2]}" == value
        end

        def timestamp!(value)
          format!(value, /\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?(?:Z|\+00:00)\z/)
          DateTime.rfc3339(value)
        end

        def identity!(value)
          object!(value, %w[device inode])
          unless value.values.all? { |n| n.is_a?(Integer) && n.positive? }
            refuse!("network namespace identity is invalid")
          end
        end

        def path!(value)
          refuse!("network artifact path is not canonical") unless value.is_a?(String) &&
            value.valid_encoding? && !value.include?("\0") && value.start_with?("/") &&
            !value.split("/").any? { |part| part == "." || part == ".." } && File.expand_path(value) == value
        end

        def collection!(value, key, min: 0)
          array!(value, min: min, max: 256)
          value.each { |entry| refuse!("network collection entry is invalid") unless entry.is_a?(Hash) }
          unique!(value.map { |entry| entry.fetch(key) })
          value
        end

        def object!(value, keys)
          refuse!("network evidence schema is not closed") unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def array!(value, min: 0, max: nil)
          refuse!("network evidence collection is invalid") unless value.is_a?(Array) && value.size >= min &&
            (max.nil? || value.size <= max)
          value
        end

        def unique!(values)
          refuse!("network evidence entries are duplicate") unless values.uniq.size == values.size
        end

        def version!(value) = equal!(value.fetch("version"), 1)
        def id!(value) = format!(value, ID)
        def format!(value, regex)
          refuse!("network evidence identifier or format is invalid") unless value.is_a?(String) && regex.match?(value)
        end
        def enum!(value, values)
          refuse!("network evidence enum is unsupported") unless values.include?(value)
        end
        def port!(value)
          refuse!("network evidence port is invalid") unless value.is_a?(Integer) && value.between?(1, 65_535)
        end
        def equal!(actual, expected)
          refuse!("network evidence context differs") unless same_value?(actual, expected)
        end
        def same_value?(actual, expected)
          case expected
          when Hash
            actual.is_a?(Hash) && actual.keys.sort == expected.keys.sort &&
              expected.all? { |key, value| same_value?(actual.fetch(key), value) }
          when Array
            actual.is_a?(Array) && actual.size == expected.size &&
              expected.each_with_index.all? { |value, index| same_value?(actual[index], value) }
          else actual.class == expected.class && actual == expected
          end
        end
        def refuse!(message) = raise(RuntimeUnavailableError, message)

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
