# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test/end_to_end_runner"

class ScenarioContractTest < AceMonorepoE2eTestCase
  SCENARIO_DIR = File.expand_path("../e2e/TS-MONO-001-rubygems-install", __dir__)

  def test_autonomy_scenarios_load_without_executing_vm_or_model
    loader = Ace::Test::EndToEndRunner::Molecules::ScenarioLoader.new
    {"TS-MONO-003-lab-vm-bootstrap" => %w[TC-001 TC-002 TC-003],
     "TS-MONO-004-lab-vm-recovery" => %w[TC-001 TC-002 TC-003 TC-004]}.each do |name, cases|
      scenario = loader.load(File.expand_path("../e2e/#{name}", __dir__))
      assert_equal cases, scenario.test_cases.map(&:tc_id)
      scenario.test_cases.each { |test_case| refute_empty test_case.declared_artifacts }
    end
  end

  # The artifact-contract validator runs only when the E2E runner loads the
  # scenario, so contract drift (a verify.md path not declared in the runner
  # or scenario.yml) otherwise surfaces only at verification time.
  def test_ts_mono_001_scenario_loads_with_consistent_artifact_contract
    loader = Ace::Test::EndToEndRunner::Molecules::ScenarioLoader.new
    scenario = loader.load(SCENARIO_DIR)

    assert_equal %w[TC-001 TC-002 TC-003 TC-004], scenario.test_cases.map(&:tc_id)
    scenario.test_cases.each do |test_case|
      refute_empty test_case.declared_artifacts,
        "#{test_case.tc_id} must declare its artifact contract"
    end
  end

  def test_every_verify_referenced_result_path_is_declared
    # Mirror of the runner's substring contract: each results/tc path in a
    # verify file must appear in the sibling runner file or scenario.yml.
    %w[TC-001-discover-gems TC-002-sandbox-install TC-003-fullindex-fallback
       TC-004-classify-result].each do |base|
      verify = File.read(File.join(SCENARIO_DIR, "#{base}.verify.md"))
      runner = File.read(File.join(SCENARIO_DIR, "#{base}.runner.md"))
      sandbox = File.read(File.join(SCENARIO_DIR, "scenario.yml"))

      verify.scan(%r{results/tc/\d{2}/[^\s`)"',]+}).each do |path|
        declared = runner.include?(path) || sandbox.include?(path)
        assert declared, "#{base}.verify.md references undeclared artifact: #{path}"
      end
    end
  end
end
