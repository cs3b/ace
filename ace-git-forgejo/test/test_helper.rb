# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/git"
require "ace/git/forgejo"

# Base test case for ace-git-forgejo tests
class AceGitForgejoTestCase < AceTestCase
  def setup
    super
    Ace::Git.reset_config!
    # Hermetic: no ambient fj keys file may influence the alias-conflict
    # guard; dedicated tests override @default_keys_path_stub with a path.
    RepositoryBindingStub.install(nil)
  end

  def teardown
    RepositoryBindingStub.remove
    Ace::Git.reset_config!
    super
  end

  # Keeps the fj keys-file lookup pointing nowhere unless a test overrides it.
  module RepositoryBindingStub
    def self.install(path)
      @original = Ace::Git::Forgejo::RepositoryBinding.method(:default_keys_path)
      Ace::Git::Forgejo::RepositoryBinding.define_singleton_method(:default_keys_path) { path }
    end

    def self.remove
      original = @original
      Ace::Git::Forgejo::RepositoryBinding.define_singleton_method(:default_keys_path, original)
    end
  end

  # Build a scripted runner from a hash of full-command => response.
  # Response: Hash result, or [:stderr, exit_code] shorthand for failure.
  def scripted_runner(responses)
    lambda do |args:, timeout: nil, env: nil|
      key = args.join(" ")
      response = responses.fetch(key) do
        flunk("Unexpected command in test: #{key}")
      end
      if response.is_a?(Array)
        {success: false, stdout: "", stderr: response[0], exit_code: response[1]}
      else
        response
      end
    end
  end
end
