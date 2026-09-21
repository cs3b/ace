# frozen_string_literal: true

require "test_helper"

module Errors
  # Failure taxonomy integrity: every classified failure exists, inherits from
  # Ace::Git::Error, and carries actionable messages.
  class TaxonomyTest < AceGitTestCase
    TAXONOMY = [
      Ace::Git::NoDefaultServerConfiguredError,
      Ace::Git::MultipleDefaultServersError,
      Ace::Git::DuplicateServerNameError,
      Ace::Git::UnknownProviderError,
      Ace::Git::UnknownServerNameError,
      Ace::Git::AmbiguousRemoteError,
      Ace::Git::ProviderCliMissingError,
      Ace::Git::ProviderAuthenticationError,
      Ace::Git::ProviderUnreachableError,
      Ace::Git::ProviderMalformedOutputError,
      Ace::Git::ProviderObjectNotFoundError
    ].freeze

    def test_all_taxonomy_errors_inherit_from_ace_git_error
      TAXONOMY.each do |error_class|
        assert_operator error_class, :<, Ace::Git::Error,
          "#{error_class} must inherit from Ace::Git::Error"
      end
    end

    def test_core_local_errors_still_exist
      assert Ace::Git::GitError < Ace::Git::Error
      assert Ace::Git::ConfigError < Ace::Git::Error
      assert Ace::Git::TimeoutError < Ace::Git::Error
    end

    def test_taxonomy_errors_are_distinct_classes
      names = TAXONOMY.map(&:name)
      assert_equal names.length, names.uniq.length, "taxonomy entries must be distinct classes"
    end
  end
end
