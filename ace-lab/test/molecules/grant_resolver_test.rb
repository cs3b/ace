# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class GrantResolverTest < Minitest::Test
    def topology
      Ace::Lab::Atoms::TopologySchema.normalize!(topology_config)["topology"]
    end

    def resolve(documents: [], trusted_path: "/nonexistent/lab/authorization.yml")
      Ace::Lab::Molecules::GrantResolver.resolve(
        documents: documents, topology: topology, trusted_path: trusted_path
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

    def test_caller_writable_trusted_file_fails_ownership_verification
      # A user-owned grants file must be rejected even when it contains a
      # syntactically valid self-grant (review round 5, F1)
      path = File.join(Dir.mktmpdir, "authorization.yml")
      File.write(path, YAML.dump({"principals" => {
        Process.uid.to_s => {"projects" => %w[atlas borealis]}
      }}))

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        resolve(trusted_path: path)
      end

      assert_match(/failed the deployment ownership verification/, error.message)
    end

    def test_unreadable_trusted_file_fails_closed_classified
      # A root-owned 0600 file passes ownership verification but cannot be
      # opened by an ordinary caller; the EACCES must classify, not escape
      # (review round 6, F2)
      root_owned_dir = Struct.new(:directory?, :uid, :mode).new(true, 0, 0o755)
      path = "/etc/lab/ace-lab/authorization.yml"

      File.stub :realpath, path do
        File.stub :lstat, root_owned_dir do
          File.stub :open, ->(*_args) { raise Errno::EACCES } do
            error = assert_raises(Ace::Lab::InvalidConfigurationError) do
              resolve(trusted_path: path)
            end

            assert_match(/failed the deployment ownership verification/, error.message)
          end
        end
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
        documents: [cascade_doc(defaults: true, authorization: {"principals" => {}})]
      )

      # No trusted document: defaults are exempt from the cascade rejection
      # but never grant anything
      assert_empty grants["principals"]
    end

    def test_parse_rejects_unknown_project_references
      assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.send(
          :parse_grants,
          YAML.dump({"principals" => {"operator" => {"projects" => ["ghost"]}}}),
          "/etc/lab/ace-lab/authorization.yml", topology
        )
      end
    end

    def test_parse_never_leaks_unparseable_content
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.send(
          :parse_grants, "secret: *private_token_canary",
          "/etc/lab/ace-lab/authorization.yml", topology
        )
      end

      # Parser text may quote anchors/values; the public message must not
      refute_includes error.message, "private_token_canary"
      assert_match(/could not be parsed as YAML/, error.message)
    end

    def test_parse_rejects_non_mapping_documents
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.send(
          :parse_grants, "- broken", "/etc/lab/ace-lab/authorization.yml", topology
        )
      end

      assert_match(/must contain a YAML mapping/, error.message)
    end
  end
end

module Molecules
  class GrantResolverRaceTest < Minitest::Test
    def topology
      Ace::Lab::Atoms::TopologySchema.normalize!(topology_config)["topology"]
    end

    def test_lstat_race_during_verification_fails_closed_classified
      # A directory disappearing or changing permissions between realpath
      # and lstat must classify, never raise past the query boundary
      # (review round 7, F2)
      path = File.join(Dir.mktmpdir, "authorization.yml")
      File.write(path, YAML.dump({"principals" => {}}))

      File.stub :realpath, path do
        File.stub :lstat, ->(_dir) { raise Errno::ENOENT } do
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            Ace::Lab::Molecules::GrantResolver.resolve(
              documents: [], topology: topology, trusted_path: path
            )
          end

          assert_match(/failed the deployment ownership verification/, error.message)
        end
      end
    end
  end
end
