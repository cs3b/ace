# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/owned_child_scope"
require "tempfile"

class OwnedChildScopeTest < AceRuntimeTestCase
  def test_empty_virtual_child_inventory_is_a_valid_empty_set
    scope = Ace::Runtime::Molecules::OwnedChildScope.allocate
    scope.instance_variable_set(:@owner, Process.pid)
    actual_open = File.method(:open)
    Tempfile.create("empty-child-inventory") do |empty|
      boundary = lambda do |path, mode, &block|
        assert_equal "/proc/self/task/#{Process.pid}/children", path
        actual_open.call(empty.path, mode, &block)
      end
      File.stub(:open, boundary) { assert_equal [], scope.send(:children) }
    end
  end
end
