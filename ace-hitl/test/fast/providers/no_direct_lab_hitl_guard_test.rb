# frozen_string_literal: true

require "test_helper"

# Acceptance guard (spec 8wm.t.vrz §8): agent-facing ace-hitl code must
# contain zero direct lab transport references. Everything lab-touching
# lives under lib/ace/hitl/providers/ only.
class NoDirectLabHitlGuardTest < AceHitlTestCase
  FORBIDDEN_MARKERS = [
    "lab-hitl",            # transport binary name / argv strings
    "LabRequestSubmitter", # legacy class name must not survive anywhere else
    "ACE_HITL_LAB_BIN"     # transport binary selection
  ].freeze

  def test_agent_facing_code_has_zero_direct_lab_transport_references
    lib_dir = File.expand_path("../../../lib", __dir__)
    providers_dir = File.join(lib_dir, "ace", "hitl", "providers")
    offenders = []

    Dir.glob(File.join(lib_dir, "**", "*.rb")).sort.each do |path|
      next if path.start_with?(providers_dir + File::SEPARATOR)

      body = File.read(path)
      marker = FORBIDDEN_MARKERS.find { |needle| body.include?(needle) }
      offenders << "#{path.sub("#{lib_dir}/", '')} (#{marker})" if marker
    end

    assert_empty offenders,
      "agent-facing ace-hitl code must not reference the lab transport directly " \
      "(allowed only under lib/ace/hitl/providers/): #{offenders.join(', ')}"
  end

  def test_ask_command_dispatches_through_the_providers_registry
    source = File.read(File.expand_path("../../../lib/ace/hitl/cli/commands/ask.rb", __dir__))

    assert_match(/Providers\.resolve/, source)
    assert_match(/Providers::Ref\.from_env/, source)
  end
end
