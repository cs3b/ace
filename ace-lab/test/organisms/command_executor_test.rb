# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/organisms/command_executor"

class CommandExecutorTest < Minitest::Test
  def test_real_root_with_nonroot_effective_uid_refuses_before_owner_contact
    klass = Ace::Lab::Organisms::CommandExecutor
    klass.const_set(:RUBY_PLATFORM, "linux-controlled-guard")
    owner = Object.new
    owner.define_singleton_method(:call) { |*| raise "must not contact owner" }
    Process.stub(:uid, 0) do
      Process.stub(:euid, 1000) do
        assert_raises(SecurityError) { klass.new(project: "ace", owner: owner).run(socket: nil, request: {}) }
      end
    end
  ensure
    klass.send(:remove_const, :RUBY_PLATFORM) if klass&.const_defined?(:RUBY_PLATFORM, false)
  end
end
