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
      secure_element = Struct.new(:symlink?, :directory?, :uid, :mode).new(false, true, 0, 0o755)
      secure_file = Struct.new(:symlink?, :directory?, :uid, :mode).new(false, false, 0, 0o600)
      path = "/etc/lab/ace-lab/authorization.yml"

      File.stub :lstat, ->(candidate) { candidate.to_s.end_with?("authorization.yml") ? secure_file : secure_element } do
        File.stub :open, ->(*_args) { raise Errno::EACCES } do
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            resolve(trusted_path: path)
          end

          assert_match(/failed the deployment ownership verification/, error.message)
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

    def test_parse_keeps_grants_for_projects_absent_from_local_topology
      # The grants file is machine-global; referenced projects need not
      # exist in this directory's topology — such grants simply never
      # match at query time (review round 8, F1)
      grants = Ace::Lab::Molecules::GrantResolver.send(
        :parse_grants,
        YAML.dump({"principals" => {"operator" => {"projects" => %w[atlas ghost]}}}),
        "/etc/lab/ace-lab/authorization.yml"
      )

      assert_equal %w[atlas ghost], grants.dig("principals", "operator", "projects")
    end

    def test_parse_never_leaks_unparseable_content
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.send(
          :parse_grants, "secret: *private_token_canary",
          "/etc/lab/ace-lab/authorization.yml"
        )
      end

      # Parser text may quote anchors/values; the public message must not
      refute_includes error.message, "private_token_canary"
      assert_match(/could not be parsed as YAML/, error.message)
    end

    def test_parse_rejects_non_mapping_documents
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::GrantResolver.send(
          :parse_grants, "- broken", "/etc/lab/ace-lab/authorization.yml"
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

    def test_lstat_permission_race_fails_closed_classified
      # A directory changing permissions between traversal steps must
      # classify, never raise past the query boundary (review round 7, F2)
      path = "/etc/lab/ace-lab/authorization.yml"

      File.stub :lstat, ->(_candidate) { raise Errno::EACCES } do
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

module Molecules
  class GrantResolverSymlinkTest < Minitest::Test
    def topology
      Ace::Lab::Atoms::TopologySchema.normalize!(topology_config)["topology"]
    end

    def test_caller_writable_symlink_redirect_is_rejected
      # A symlink inside a caller-owned directory must fail ownership
      # verification even when it points at a root-owned file — following
      # the canonicalized target without verifying the original path would
      # let callers pick trusted content (review round 8, F2)
      Dir.mktmpdir do |dir|
        link = File.join(dir, "authorization.yml")
        File.symlink("/etc/hosts", link)
        secure_element = Struct.new(:symlink?, :directory?, :uid, :mode).new(false, true, 0, 0o755)
        real_lstat = File.method(:lstat)

        # Parent chain simulates the deployment-owned prefix; the link
        # itself is lstat-ed for real (user-owned symlink -> rejected)
        File.stub :lstat, ->(candidate) { (candidate.to_s == link) ? real_lstat.call(candidate) : secure_element } do
          error = assert_raises(Ace::Lab::InvalidConfigurationError) do
            Ace::Lab::Molecules::GrantResolver.resolve(
              documents: [], topology: topology, trusted_path: link
            )
          end

          assert_match(/failed the deployment ownership verification/, error.message)
        end
      end
    end

    def test_missing_file_under_deployment_owned_chain_is_absent_grants
      secure_element = Struct.new(:symlink?, :directory?, :uid, :mode).new(false, true, 0, 0o755)
      path = "/etc/lab/ace-lab/authorization.yml"

      File.stub :lstat, ->(candidate) { candidate.to_s.end_with?("authorization.yml") ? raise(Errno::ENOENT) : secure_element } do
        grants = Ace::Lab::Molecules::GrantResolver.resolve(
          documents: [], topology: topology, trusted_path: path
        )

        assert_empty grants["principals"]
      end
    end

    def test_user_owned_directory_chain_fails_verification
      Dir.mktmpdir do |dir|
        path = File.join(dir, "authorization.yml")
        File.write(path, YAML.dump({"principals" => {}}))

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

module Molecules
  class GrantResolverLinuxSymlinkTest < Minitest::Test
    def topology
      Ace::Lab::Atoms::TopologySchema.normalize!(topology_config)["topology"]
    end

    FakeStat = Struct.new(:symlink?, :directory?, :uid, :mode)

    def test_root_owned_linux_style_symlink_is_accepted
      # Linux symlinks always report mode 0777 and cannot be changed; a
      # root-owned deployment symlink must be accepted on ownership alone
      # (review round 9, F1)
      path = "/etc/lab/ace-lab/authorization.yml"
      target = "/etc/lab/ace-lab/grants.real.yml"
      dir_stat = FakeStat.new(false, true, 0, 0o755)
      link_stat = FakeStat.new(true, false, 0, 0o777)
      file_stat = FakeStat.new(false, false, 0, 0o600)
      content = YAML.dump({"principals" => {"operator" => {"projects" => ["atlas"]}}})
      fake_io = Struct.new(:stat, :read, :close).new(file_stat, content, nil)
      real_readlink = File.method(:readlink)

      File.stub :lstat, ->(candidate) {
        case candidate.to_s
        when path then link_stat
        when target then file_stat
        else dir_stat
        end
      } do
        File.stub :readlink, ->(candidate) { (candidate.to_s == path) ? target : real_readlink.call(candidate) } do
          File.stub :open, ->(_candidate, _flags) { fake_io } do
            grants = Ace::Lab::Molecules::GrantResolver.resolve(
              documents: [], topology: topology, trusted_path: path
            )

            assert_equal ["atlas"], grants.dig("principals", "operator", "projects")
          end
        end
      end
    end

    def test_user_owned_linux_style_symlink_is_rejected
      # Ownership alone is the symlink criterion: a user-owned 0777 symlink
      # is still a caller-controlled redirect (review round 9, F1)
      path = "/etc/lab/ace-lab/authorization.yml"
      dir_stat = FakeStat.new(false, true, 0, 0o755)
      user_link_stat = FakeStat.new(true, false, Process.uid, 0o777)

      File.stub :lstat, ->(candidate) { (candidate.to_s == path) ? user_link_stat : dir_stat } do
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
