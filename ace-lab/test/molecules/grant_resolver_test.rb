# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class GrantResolverTest < Minitest::Test
    def topology
      Ace::Lab::Atoms::TopologySchema.normalize!(topology_config)["topology"]
    end

    def resolve(documents: [], trusted: nil)
      path = nil
      if trusted
        path = File.join(Dir.mktmpdir, "authorization.yml")
        File.write(path, YAML.dump(trusted))
      end
      path ||= "/nonexistent/lab/authorization.yml"

      Ace::Lab::Molecules::GrantResolver.resolve(
        documents: documents, topology: topology, trusted_path: path
      )
    end

    def cascade_doc(authorization: :none, defaults: false)
      document = {"schema_version" => 1, "topology" => {}}
      document["authorization"] = {"principals" => {}} unless authorization == :none
      {path: "/cfg/config.yml", document: document, defaults: defaults}
    end

    def test_missing_trusted_document_authorizes_nobody
      grants = resolve

      assert_empty grants["principals"]
    end

    def test_trusted_document_grants_its_identities
      grants = resolve(trusted: {"principals" => {
        "operator" => {"projects" => %w[atlas borealis]}
      }})

      assert_equal %w[atlas borealis], grants.dig("principals", "operator", "projects")
    end

    def test_trusted_grants_must_reference_known_projects
      assert_raises(Ace::Lab::InvalidConfigurationError) do
        resolve(trusted: {"principals" => {
          "operator" => {"projects" => ["ghost"]}
        }})
      end
    end

    def test_authorization_sections_in_cascade_documents_are_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        resolve(documents: [cascade_doc(authorization: {"principals" => {}})])
      end

      # A caller-writable cascade tier must never define grants (review F3)
      assert_match(%r{grants come from the trusted file /nonexistent/lab/authorization\.yml}, error.message)
      assert_match(%r{remove the authorization section from /cfg/config\.yml}, error.message)
    end

    def test_defaults_documents_may_carry_legacy_authorization_without_rejection
      grants = resolve(
        documents: [cascade_doc(defaults: true, authorization: {"principals" => {}})],
        trusted: {"principals" => {"operator" => {"projects" => ["atlas"]}}}
      )

      assert_equal ["atlas"], grants.dig("principals", "operator", "projects")
    end

    def test_unparseable_trusted_document_fails_configuration
      path = File.join(Dir.mktmpdir, "authorization.yml")
      File.write(path, "secret: *private_token_canary")

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.resolve(
          documents: [], topology: topology, trusted_path: path
        )
      end

      # Parser text may quote anchors/values; the public message must not
      refute_includes error.message, "private_token_canary"
      assert_match(/could not be parsed as YAML/, error.message)
    end

    def test_non_mapping_trusted_document_fails_configuration
      path = File.join(Dir.mktmpdir, "authorization.yml")
      File.write(path, "- broken")

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.resolve(
          documents: [], topology: topology, trusted_path: path
        )
      end

      assert_match(/must contain a YAML mapping/, error.message)
    end
  end
end
