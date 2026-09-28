# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class CallerAuthorizerTest < Minitest::Test
    def principals
      topology_config["authorization"]["principals"]
    end

    def test_matches_configured_principal_by_username
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(principals: principals, identity: ["operator"])

      assert_equal %w[atlas borealis], authorizer.authorized_project_ids
      assert authorizer.authorized?("atlas")
      assert authorizer.authorized?("borealis")
      assert authorizer.authorized?
    end

    def test_matches_configured_principal_by_numeric_uid
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(principals: principals, identity: ["501"])

      refute authorizer.authorized?("atlas")
      refute authorizer.authorized?
      assert_empty authorizer.authorized_project_ids
    end

    def test_multiple_matching_principals_union_their_projects
      config_principals = principals.merge(
        "ci-runner" => {"projects" => ["borealis"]}
      )

      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(
        principals: config_principals, identity: %w[operator ci-runner]
      )

      assert_equal %w[atlas borealis], authorizer.authorized_project_ids
    end

    def test_identity_with_no_principal_is_authorized_for_nothing
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(principals: principals, identity: ["intruder"])

      refute authorizer.authorized?
      assert_empty authorizer.authorized_project_ids
    end

    def test_empty_principals_authorize_nothing
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(principals: {}, identity: ["operator"])

      refute authorizer.authorized?
    end

    def test_local_identity_defaults_to_process_owner
      identities = Ace::Lab::Molecules::CallerAuthorizer.local_identity

      refute_empty identities
      assert_includes identities, Process.uid.to_s
    end

    def test_local_identity_resolves_to_username_when_passwd_entry_exists
      require "etc"
      passwd = Etc.getpwuid(Process.uid)

      return if passwd.nil?

      assert_includes Ace::Lab::Molecules::CallerAuthorizer.local_identity, passwd.name
    end
  end

  class CallerAuthorizerNamespaceTest < Minitest::Test
    def test_numeric_usernames_are_never_matched_as_usernames
      # Username "501" and uid 501 belonging to DIFFERENT accounts must not
      # cross-match through the shared grants namespace (subject review:
      # separate caller identity principal namespaces)
      identities = Ace::Lab::Molecules::CallerAuthorizer.matchable_identities("501", 501)

      assert_equal %w[501], identities
      assert_equal ["uid-only"], Ace::Lab::Molecules::CallerAuthorizer.matchable_identities("501", "uid-only")
    end

    def test_regular_username_and_uid_both_match
      identities = Ace::Lab::Molecules::CallerAuthorizer.matchable_identities("operator", 501)

      assert_equal %w[operator 501], identities
    end

    def test_numeric_username_grant_cannot_authorize_different_numeric_account
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(
        principals: {"501" => {"projects" => ["atlas"]}},
        identity: Ace::Lab::Molecules::CallerAuthorizer.matchable_identities("501", 502)
      )

      # Account named "501" (uid 502) must not consume uid-501's grant
      refute authorizer.authorized?("atlas")
    end
  end
end
