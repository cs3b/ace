# frozen_string_literal: true

require_relative "../../test_helper"

class ArtifactContractValidatorTest < Minitest::Test
  ArtifactContractValidator = Ace::Test::EndToEndRunner::Atoms::ArtifactContractValidator

  def test_extract_expands_grouped_capture_shorthand
    refs = ArtifactContractValidator.extract(
      '- `results/tc/02/create.stdout`, `.stderr`, `.exit` from command',
      source: "runner.md"
    )

    assert_equal(
      %w[
        results/tc/02/create.stdout
        results/tc/02/create.stderr
        results/tc/02/create.exit
      ],
      refs.map(&:path)
    )
  end

  def test_extract_keeps_optional_suffixes_optional
    refs = ArtifactContractValidator.extract(
      '- `results/tc/02/create.stdout`, `.stderr` (optional), `.exit`',
      source: "runner.md"
    )

    stderr_ref = refs.find { |ref| ref.path == "results/tc/02/create.stderr" }
    assert_equal true, stderr_ref.optional
  end

  def test_validate_rejects_wildcard_references
    error = assert_raises(ArgumentError) do
      ArtifactContractValidator.validate!(
        tc_id: "TC-001",
        scenario_dir: "/tmp/scenario",
        runner_references: [
          ArtifactContractValidator::Reference.new(
            path: "results/tc/01/output.*",
            optional: false,
            source: "runner.md",
            line: 12
          )
        ],
        verifier_references: [],
        scenario_references: []
      )
    end

    assert_match(/Wildcard artifact path/, error.message)
  end

  def test_validate_rejects_verifier_only_file_reference
    error = assert_raises(ArgumentError) do
      ArtifactContractValidator.validate!(
        tc_id: "TC-001",
        scenario_dir: "/tmp/scenario",
        runner_references: [
          ArtifactContractValidator::Reference.new(
            path: "results/tc/01",
            optional: false,
            source: "runner.md",
            line: 8
          )
        ],
        verifier_references: [
          ArtifactContractValidator::Reference.new(
            path: "results/tc/01/output.txt",
            optional: false,
            source: "verify.md",
            line: 10
          )
        ],
        scenario_references: []
      )
    end

    assert_match(/Verifier references undeclared artifact/, error.message)
    assert_match(/results\/tc\/01\/output\.txt/, error.message)
  end
end
