# frozen_string_literal: true

require_relative "../../test_helper"

class LayoutNodeTest < Minitest::Test
  Node = Ace::Tmux::Models::LayoutNode
  Pane = Ace::Tmux::Models::Pane

  def test_leaf_node
    pane = Pane.new(commands: ["vim"])
    node = Node.new(pane: pane, size: "40%")

    assert node.leaf?
    refute node.container?
    assert_equal pane, node.pane
    assert_equal "40%", node.size
    assert_nil node.direction
    assert_equal [], node.children
  end

  def test_container_node
    child1 = Node.new(pane: Pane.new(commands: ["vim"]))
    child2 = Node.new(pane: Pane.new(commands: ["bash"]))
    node = Node.new(direction: :horizontal, children: [child1, child2])

    assert node.container?
    refute node.leaf?
    assert_equal :horizontal, node.direction
    assert_equal 2, node.children.length
    assert_nil node.pane
  end

  def test_leaf_count_leaf
    node = Node.new(pane: Pane.new(commands: ["vim"]))
    assert_equal 1, node.leaf_count
  end

  def test_leaf_count_flat_container
    children = 3.times.map { Node.new(pane: Pane.new(commands: ["bash"])) }
    node = Node.new(direction: :horizontal, children: children)
    assert_equal 3, node.leaf_count
  end

  def test_leaf_count_nested
    inner = Node.new(direction: :vertical, children: [
      Node.new(pane: Pane.new(commands: ["bash"])),
      Node.new(pane: Pane.new(commands: ["htop"]))
    ])
    root = Node.new(direction: :horizontal, children: [
      Node.new(pane: Pane.new(commands: ["claude"])),
      inner,
      Node.new(pane: Pane.new(commands: ["nvim"]))
    ])
    assert_equal 4, root.leaf_count
  end

  def test_leaves_returns_all_leaves_dfs
    leaf_a = Node.new(pane: Pane.new(commands: ["a"]))
    leaf_b = Node.new(pane: Pane.new(commands: ["b"]))
    leaf_c = Node.new(pane: Pane.new(commands: ["c"]))
    leaf_d = Node.new(pane: Pane.new(commands: ["d"]))

    inner = Node.new(direction: :vertical, children: [leaf_b, leaf_c])
    root = Node.new(direction: :horizontal, children: [leaf_a, inner, leaf_d])

    leaves = root.leaves
    assert_equal 4, leaves.length
    assert_equal %w[a b c d], leaves.map { |l| l.pane.commands.first }
  end

  def test_leaves_of_leaf_returns_self
    node = Node.new(pane: Pane.new(commands: ["vim"]))
    assert_equal [node], node.leaves
  end

  def test_pane_id_accessor
    node = Node.new(pane: Pane.new(commands: ["vim"]))
    assert_nil node.pane_id

    node.pane_id = 5
    assert_equal 5, node.pane_id
  end

  def test_default_initialization
    node = Node.new
    assert node.container?
    assert_nil node.direction
    assert_equal [], node.children
    assert_nil node.pane
    assert_nil node.size
    assert_nil node.pane_id
  end
end
