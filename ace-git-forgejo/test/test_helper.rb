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
  end

  def teardown
    Ace::Git.reset_config!
    super
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
