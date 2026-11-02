# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "rbconfig"

module Ace
  module Lab
    module Auth
      class RootProjectionTest < Minitest::Test
        def test_session_can_read_its_projection_but_not_replace_root_owned_directories
          skip "requires root and Linux /run" unless Process.euid.zero? && RUBY_PLATFORM.include?("linux") && File.directory?("/run")

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir("ace-projection-test-", "/run") do |root|
            File.chmod(0o711, root)
            handoff = CredentialHandoff.new(File.join(root, "credentials"), recipient: account.name, owner_uid: account.uid)
            credential = handoff.deliver("lease-test", "synthetic-token")
            profile = {"issuer" => {"url" => "http://127.0.0.1:3000", "account" => "worker"}}
            projection = nil
            Plugins::ForgejoProvider.new.with_exec_environment(profile: profile, credential: credential) do |env|
              projection = env.fetch("XDG_DATA_HOME")
              login_dir = File.join(projection, "forgejo-cli")
              [projection, login_dir].each do |dir|
                assert_equal 0, File.stat(dir).uid
                assert_equal 0o711, File.stat(dir).mode & 0o777
              end
              assert_equal account.uid, File.stat(File.join(login_dir, "keys.json")).uid
              assert_equal account.uid, File.stat(env.fetch("GIT_ASKPASS")).uid
              script = 'exit(File.read(File.join(ENV.fetch("XDG_DATA_HOME"), "forgejo-cli", "keys.json")).include?("synthetic-token") && !File.writable?(ENV.fetch("XDG_DATA_HOME")) && !File.writable?(File.join(ENV.fetch("XDG_DATA_HOME"), "forgejo-cli")) ? 0 : 1)'
              runner = SessionRunner.new(uid: account.uid, cwd: "/tmp")
              assert_equal 0, runner.call([RbConfig.ruby, "-e", script], env)
            end
            refute File.exist?(projection)
            handoff.clear("lease-test")
          end
        end
      end
    end
  end
end
