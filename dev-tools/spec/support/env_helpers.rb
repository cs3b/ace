# frozen_string_literal: true

# Provides a concise, reliable way to mutate ENV during a spec while ensuring
# the original environment is always restored—­even if the example raises.
#
# Usage:
#
#   it "uses a temporary environment" do
#     with_modified_env("LANG" => "C", "FOO" => nil) do
#       # inside the block, ENV["LANG"] == "C" and ENV["FOO"] has been deleted
#     end
#     # outside the block, ENV is exactly as it was before the helper ran
#   end
#
module EnvHelpers
  # Temporarily sets/deletes environment variables for the duration of the block
  # and restores the original ENV afterwards.
  #
  # @param changes [Hash<String, String, nil>] keys to set (or delete if value is nil)
  # @yield the block to execute with the modified environment
  # @return returns the block's return value
  def with_modified_env(changes)
    saved_env = ENV.to_hash
    changes.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value.to_s
    end

    yield
  ensure
    ENV.replace(saved_env)
  end
end

# Make the helper available to all specs.
RSpec.configure do |config|
  config.include EnvHelpers
end
