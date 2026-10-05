# frozen_string_literal: true

require "test_helper"
require "open3"
require "json"

# Standard JSON Schema draft2020-12 validation, opt-in with a test-only Python
# environment. The dependency-free runtime gem never loads this validator.
class ReverseSchemaTest < AceHitlContractTestCase
  def test_published_schema_matches_canonical_reference_pair_matrix
    python = ENV["ACE_HITL_SCHEMA_PYTHON"]
    skip "requires explicit Python jsonschema4.25.1 fixture" if python.to_s.empty?
    assert File.executable?(python), "schema validator fixture executable is unavailable"
    root = File.expand_path("../../lib/ace/hitl/contract", __dir__)
    base = JSON.parse(File.read(File.join(root, "examples/managed-request.json")))
    pairs = [["$0", "%0", true], ["$12", "%345", true], ["W692.lab_1", "agent:3-x_9.y", true],
      ["$#{'1' * 127}", "%#{'2' * 127}", true], ["a" * 128, ":" * 128, true],
      ["$0", "p1", false], ["s1", "%0", false], ["%0", "$0", false], ["$01", "%0", false],
      ["$0", "%01", false], [" $0 ", "%0", false], ["s1", " p1 ", false], ["s1\n", "p1", false],
      ["$0", "%0\n", false], ["$#{'1' * 128}", "%0", false], ["a" * 129, "p1", false],
      [1, "p1", false], ["s1", nil, false], ["$0", "@0", false], ["$-1", "%0", false]]
    documents = pairs.map do |session, pane, _valid|
      base.merge("reverse" => {"schema" => "ace.hitl.ref/v1", "session" => session, "pane" => pane})
    end
    script = <<~PYTHON
      import json, sys, importlib.metadata
      from jsonschema import Draft202012Validator
      with open(sys.argv[1], encoding="utf-8") as source:
          schema = json.load(source)
      Draft202012Validator.check_schema(schema)
      validator = Draft202012Validator(schema)
      documents = json.load(sys.stdin)
      print(json.dumps({"version": importlib.metadata.version("jsonschema"),
                        "valid": [validator.is_valid(document) for document in documents]}))
    PYTHON
    out, err, status = Open3.capture3(python, "-c", script, File.join(root, "managed.v1.schema.json"),
      stdin_data: JSON.generate(documents))
    assert status.success?, "schema validator failed: #{err}"
    result = JSON.parse(out)
    assert_equal "4.25.1", result.fetch("version")
    assert_equal pairs.map(&:last), result.fetch("valid")
    documents.zip(pairs).each do |document, (_, _, valid)|
      if valid
        assert_equal document, Ace::Hitl::Contract::ManagedEnvelope.load(document)
      else
        assert_raises(Ace::Hitl::Contract::InvalidEnvelope) { Ace::Hitl::Contract::ManagedEnvelope.load(document) }
      end
    end
  end
end
