# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/atoms/protected_publication_input"

class ProtectedPublicationInputTest < Minitest::Test
  def input
    {"target" => {"resource" => "rubygems:ace-hitl:1.2.3", "artifact_digest" => "b" * 64},
      "publication" => {"gem_name" => "ace-hitl", "version" => "1.2.3", "head" => "a" * 40,
        "registry" => "https://rubygems.org", "artifact_relative_path" => "pkg/ace-hitl-1.2.3.gem"}}
  end

  def test_exact_single_artifact_and_version_binding
    assert_equal input, Ace::Lab::Atoms::ProtectedPublicationInput.decode!(JSON.generate(input))
    value = input
    value["publication"]["version"] = "1.2.4"
    assert_raises(ArgumentError) { Ace::Lab::Atoms::ProtectedPublicationInput.validate!(value) }
  end

  def test_no_ambient_queue_path_registry_or_secret_selection
    changes = {"artifact_relative_path" => ["/tmp/a.gem", "../a.gem", "pkg//a.gem", "pkg/a.zip"],
      "head" => ["main", "a" * 64], "registry" => ["http://rubygems.org", "https://other.invalid"],
      "gem_name" => ["../ace"], "version" => ["latest"]}
    changes.each do |key, values|
      values.each do |replacement|
        value = input
        value["publication"][key] = replacement
        assert_raises(ArgumentError) { Ace::Lab::Atoms::ProtectedPublicationInput.validate!(value) }
      end
    end
    value = input.merge("queue" => [])
    assert_raises(ArgumentError) { Ace::Lab::Atoms::ProtectedPublicationInput.validate!(value) }
    value = input
    value["publication"]["otp"] = (1..6).to_a.join
    assert_raises(ArgumentError) { Ace::Lab::Atoms::ProtectedPublicationInput.validate!(value) }
    value = input
    value["target"].delete("artifact_digest")
    assert_raises(ArgumentError) { Ace::Lab::Atoms::ProtectedPublicationInput.validate!(value) }
  end

  def test_duplicate_decoded_fields_and_oversized_input_refuse
    bytes = JSON.generate(input)
    assert_raises(ArgumentError) do
      Ace::Lab::Atoms::ProtectedPublicationInput.decode!(bytes.sub('"publication":', '"publication":{},"publication":'))
    end
    assert_raises(ArgumentError) { Ace::Lab::Atoms::ProtectedPublicationInput.decode!(" " * 65537) }
  end
end
