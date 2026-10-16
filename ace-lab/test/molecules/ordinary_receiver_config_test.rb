# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

module Ace
  module Lab
    module Molecules
      class OrdinaryReceiverConfigTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir("ordinary-config")
          @repo = File.join(@dir, "repo")
          FileUtils.mkdir_p(@repo)
        end

        def teardown
          FileUtils.rm_rf(@dir)
        end

        def test_valid_configuration_loads_exactly
          config = write_and_load
          assert_equal "atlas", config.project
          assert_equal "ordinary-receiver", config.receiver_id
          assert_equal "/tmp/ordinary.sock", config.socket_path
          assert_equal 4242, config.receiver_uid
          assert_equal "overseer", config.principal
          assert_equal 1337, config.principal_uid
          assert_equal @repo, config.repo_path
          assert_equal %w[branch checkout_id worktree_id], config.execution_identity.keys.sort
        end

        def test_missing_unknown_or_invalid_keys_fail_closed
          document = valid_document
          document.delete("repo_path")
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.new(document)
          end
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.new(valid_document.merge("argv" => ["/bin/merge"]))
          end
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.new(valid_document.merge("socket_path" => "relative.sock"))
          end
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.new(valid_document.merge("receiver_uid" => -1))
          end
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.new(valid_document.merge("repo_path" => "/nonexistent-dir-xyz"))
          end
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.new(
              valid_document.merge("execution_identity" => {"checkout_id" => "c"})
            )
          end
        end

        def test_explicit_project_forge_path_and_socket_group_are_validated
          config = OrdinaryReceiverConfig.new(valid_document.merge(
            "socket_gid" => Process.gid, "forge_config_path" => "/etc/lab/ace-lab/atlas-forge.yml"))
          assert_equal Process.gid, config.socket_gid
          assert_equal "/etc/lab/ace-lab/atlas-forge.yml", config.forge_config_path
          [{"socket_gid" => -1}, {"socket_gid" => "staff"}, {"forge_config_path" => "relative.yml"}].each do |bad|
            assert_raises(Ace::Lab::InvalidConfigurationError) { OrdinaryReceiverConfig.new(valid_document.merge(bad)) }
          end
        end

        def test_unreadable_file_fails_closed
          assert_raises Ace::Lab::InvalidConfigurationError do
            OrdinaryReceiverConfig.load(File.join(@dir, "missing.yml"))
          end
        end

        def test_requester_owned_configuration_cannot_select_receiver_identity
          skip "requires an unprivileged requester" if Process.uid.zero?
          path = File.join(@dir, "receiver.yml")
          File.write(path, YAML.safe_dump(valid_document))
          assert_raises(Ace::Lab::InvalidConfigurationError) { OrdinaryReceiverConfig.load(path) }
        end

        private

        def write_and_load
          path = File.join(@dir, "receiver.yml")
          File.write(path, YAML.safe_dump(valid_document))
          GrantResolver.stub(:read_verified, ->(selected) {
            assert_equal path, selected
            File.read(selected)
          }) { OrdinaryReceiverConfig.load(path) }
        end

        def valid_document
          {
            "project" => "atlas", "receiver_id" => "ordinary-receiver",
            "socket_path" => "/tmp/ordinary.sock", "receiver_uid" => 4242,
            "principal" => "overseer", "principal_uid" => 1337,
            "repo_path" => @repo, "policy_path" => "/etc/lab/ace-lab/authorization.yml",
            "execution_identity" => {"checkout_id" => "checkout-1", "worktree_id" => "wt-1",
                                     "branch" => "main"}
          }
        end
      end
    end
  end
end
