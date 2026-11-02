# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "rbconfig"

module Ace
  module Lab
    module Auth
      class CredentialHandoffTest < Minitest::Test
        def test_secret_is_never_written_to_a_world_readable_temporary_file
          Dir.mktmpdir do |dir|
            previous = File.umask(0)
            seen_mode = nil
            secret = Object.new
            secret.define_singleton_method(:to_s) do
              entry = Dir.children(dir).first
              seen_mode = File.stat(File.join(dir, entry)).mode & 0o777 if entry
              "test-token"
            end
            handoff = CredentialHandoff.new(dir, recipient: "worker")
            path = handoff.deliver("lease-test", secret)

            assert_equal 0o600, seen_mode
            assert_equal 0o400, File.stat(path).mode & 0o777
            assert_equal "test-token", File.read(path)
          ensure
            File.umask(previous) if previous
          end
        end

        def test_root_issuer_delivers_to_unprivileged_session_under_restrictive_umask
          skip "requires root and a Linux /run directory" unless Process.euid.zero? && RUBY_PLATFORM.include?("linux") && File.directory?("/run")

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir("ace-handoff-test-", "/run") do |dir|
            File.chmod(0o711, dir)
            previous = File.umask(0o077)
            handoff = CredentialHandoff.new(File.join(dir, "credentials"), recipient: account.name, owner_uid: account.uid)
            path = handoff.deliver("lease-test", "temporary-test-token")
            assert_equal 0o711, File.stat(File.dirname(path)).mode & 0o777
            assert_equal account.uid, File.stat(path).uid
            assert_equal 0o400, File.stat(path).mode & 0o777
            script = 'exit(File.read(ENV.fetch("TEST_CREDENTIAL")) == "temporary-test-token" ? 0 : 1)'
            pid = fork do
              Process.groups = []
              Process::GID.change_privilege(account.gid)
              Process::UID.change_privilege(account.uid)
              exec({"TEST_CREDENTIAL" => path}, RbConfig.ruby, "-e", script, unsetenv_others: true)
            end
            _, status = Process.wait2(pid)
            assert status.success?
            assert_equal :cleared, handoff.clear("lease-test")
          ensure
            File.umask(previous) if previous
          end
        end

        def test_session_handoff_does_not_recreate_a_removed_directory
          skip "requires root and a Linux /run directory" unless Process.euid.zero? && RUBY_PLATFORM.include?("linux") && File.directory?("/run")

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir("ace-handoff-test-", "/run") do |dir|
            File.chmod(0o711, dir)
            target = File.join(dir, "removed-session")
            handoff = CredentialHandoff.new(target, recipient: account.name, owner_uid: account.uid, create_root: false)
            assert_raises(Error) { handoff.deliver("lease-test", "temporary-test-token") }
            refute File.exist?(target)
          end
        end

        def test_session_handoff_never_writes_into_a_replaced_directory
          skip "requires root and a Linux /run directory" unless Process.euid.zero? && RUBY_PLATFORM.include?("linux") && File.directory?("/run")

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir("ace-handoff-test-", "/run") do |parent|
            File.chmod(0o711, parent)
            directory = File.join(parent, "session")
            Dir.mkdir(directory, 0o711)
            File.chmod(0o711, directory)
            secret = Object.new
            secret.define_singleton_method(:to_s) do
              Dir.children(directory).each { |name| File.unlink(File.join(directory, name)) }
              Dir.rmdir(directory)
              Dir.mkdir(directory, 0o711)
              File.chmod(0o711, directory)
              "temporary-test-token"
            end
            handoff = CredentialHandoff.new(directory, recipient: account.name, owner_uid: account.uid, create_root: false)
            assert_raises(SystemCallError) { handoff.deliver("lease-test", secret) }
            assert_empty Dir.children(directory)
          end
        end
      end
    end
  end
end
