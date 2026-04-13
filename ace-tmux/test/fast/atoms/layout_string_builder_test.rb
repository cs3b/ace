# frozen_string_literal: true

require_relative "../../test_helper"

class LayoutStringBuilderTest < Minitest::Test
  Builder = Ace::Tmux::Atoms::LayoutStringBuilder
  Node = Ace::Tmux::Models::LayoutNode
  Pane = Ace::Tmux::Models::Pane

  # --- Helper ---

  def leaf(commands: ["bash"], size: nil)
    Node.new(pane: Pane.new(commands: commands), size: size)
  end

  def container(direction, children)
    Node.new(direction: direction, children: children)
  end

  # --- parse_size ---

  def test_parse_size_nil
    assert_nil Builder.parse_size(nil, 200)
  end

  def test_parse_size_percentage
    assert_equal 80, Builder.parse_size("40%", 200)
  end

  def test_parse_size_absolute
    assert_equal 80, Builder.parse_size("80", 200)
  end

  def test_parse_size_percentage_rounds
    # 33.3% of 200 = 66.6, rounds to 67
    assert_equal 67, Builder.parse_size("33.3%", 200)
  end

  # --- allocate_sizes ---

  def test_allocate_sizes_even_distribution
    children = [leaf, leaf, leaf]
    # 200 total, 2 separators = 198 available, 198/3 = 66 each
    sizes = Builder.allocate_sizes(children, total: 200)
    assert_equal [66, 66, 66], sizes
  end

  def test_allocate_sizes_even_with_remainder
    children = [leaf, leaf]
    # 201 total, 1 separator = 200 available, 200/2 = 100 each
    sizes = Builder.allocate_sizes(children, total: 201)
    assert_equal [100, 100], sizes
  end

  def test_allocate_sizes_explicit_percentage
    children = [leaf(size: "40%"), leaf, leaf]
    # 200 total, 2 separators = 198 available
    # First child: 40% of 198 = 79 (rounded)
    # Remaining: 198 - 79 = 119, split between 2 auto = 59, 60
    sizes = Builder.allocate_sizes(children, total: 200)
    assert_equal 79, sizes[0]
    assert_equal 119, sizes[1] + sizes[2]
  end

  def test_allocate_sizes_single_child
    children = [leaf]
    # 200 total, 0 separators = 200 available
    sizes = Builder.allocate_sizes(children, total: 200)
    assert_equal [200], sizes
  end

  def test_allocate_sizes_all_explicit
    children = [leaf(size: "60%"), leaf(size: "40%")]
    # 200 total, 1 separator = 199 available
    # 60% of 199 = 119, 40% of 199 = 80
    sizes = Builder.allocate_sizes(children, total: 200)
    assert_equal [119, 80], sizes
  end

  # --- layout_checksum ---

  def test_layout_checksum_returns_4_hex_digits
    result = Builder.layout_checksum("200x50,0,0,0")
    assert_match(/\A[0-9a-f]{4}\z/, result)
  end

  def test_layout_checksum_deterministic
    body = "200x50,0,0{80x50,0,0,0,119x50,81,0,1}"
    assert_equal Builder.layout_checksum(body), Builder.layout_checksum(body)
  end

  def test_layout_checksum_varies_with_input
    a = Builder.layout_checksum("200x50,0,0,0")
    b = Builder.layout_checksum("200x50,0,0,1")
    refute_equal a, b
  end

  # --- generate_node ---

  def test_generate_node_single_leaf
    node = leaf
    node.pane_id = 0
    result = Builder.generate_node(node, x: 0, y: 0, width: 200, height: 50)
    assert_equal "200x50,0,0,0", result
  end

  def test_generate_node_two_horizontal_leaves
    l1 = leaf
    l1.pane_id = 0
    l2 = leaf
    l2.pane_id = 1

    root = container(:horizontal, [l1, l2])
    result = Builder.generate_node(root, x: 0, y: 0, width: 200, height: 50)

    # 200 total, 1 separator = 199 available, 199/2 = 99 + 100
    assert_equal "200x50,0,0{100x50,0,0,0,99x50,101,0,1}", result
  end

  def test_generate_node_two_vertical_leaves
    l1 = leaf
    l1.pane_id = 0
    l2 = leaf
    l2.pane_id = 1

    root = container(:vertical, [l1, l2])
    result = Builder.generate_node(root, x: 0, y: 0, width: 200, height: 50)

    # 50 total height, 1 separator = 49 available, 49/2 = 25 + 24
    assert_equal "200x50,0,0[200x25,0,0,0,200x24,0,26,1]", result
  end

  def test_generate_node_nested_layout
    # 3 columns: claude | (bash / htop) | nvim
    l_claude = leaf(commands: ["claude"])
    l_claude.pane_id = 0
    l_bash = leaf(commands: ["bash"])
    l_bash.pane_id = 1
    l_htop = leaf(commands: ["htop"])
    l_htop.pane_id = 2
    l_nvim = leaf(commands: ["nvim"])
    l_nvim.pane_id = 3

    inner = container(:vertical, [l_bash, l_htop])
    root = container(:horizontal, [l_claude, inner, l_nvim])

    result = Builder.generate_node(root, x: 0, y: 0, width: 200, height: 50)

    # Should contain both { } and [ ] for nesting
    assert_includes result, "{"
    assert_includes result, "["
    assert_includes result, "]"
    assert_includes result, "}"

    # Should reference all 4 pane IDs
    assert_includes result, ",0,"  # pane 0 somewhere
    assert_includes result, ",1,"  # pane 1 somewhere (in [] section)
    assert_includes result, ",2"   # pane 2
    assert_includes result, ",3}"  # pane 3 last
  end

  def test_generate_node_with_explicit_sizes
    l1 = leaf(size: "40%")
    l1.pane_id = 0
    l2 = leaf
    l2.pane_id = 1

    root = container(:horizontal, [l1, l2])
    result = Builder.generate_node(root, x: 0, y: 0, width: 200, height: 50)

    # 200 total, 1 separator = 199 available
    # First: 40% of 199 = 80, Second: 199 - 80 = 119
    assert_equal "200x50,0,0{80x50,0,0,0,119x50,81,0,1}", result
  end

  # --- build (full pipeline) ---

  def test_build_produces_checksummed_string
    root = container(:horizontal, [leaf, leaf])
    result = Builder.build(root, width: 200, height: 50, pane_ids: [0, 1])

    # Should start with 4-hex-digit checksum followed by comma
    assert_match(/\A[0-9a-f]{4},/, result)
  end

  def test_build_assigns_pane_ids_in_order
    l1 = leaf(commands: ["a"])
    l2 = leaf(commands: ["b"])
    l3 = leaf(commands: ["c"])
    root = container(:horizontal, [l1, l2, l3])

    Builder.build(root, width: 200, height: 50, pane_ids: [5, 10, 15])

    assert_equal 5, l1.pane_id
    assert_equal 10, l2.pane_id
    assert_equal 15, l3.pane_id
  end

  def test_build_single_leaf_tree
    root = leaf
    result = Builder.build(root, width: 200, height: 50, pane_ids: [0])

    checksum = Builder.layout_checksum("200x50,0,0,0")
    assert_equal "#{checksum},200x50,0,0,0", result
  end

  def test_build_complex_nested_tree
    # 3 columns: [40%] claude | (bash / htop) | nvim [focus]
    root = container(:horizontal, [
      leaf(commands: ["claude"], size: "40%"),
      container(:vertical, [
        leaf(commands: ["bash"]),
        leaf(commands: ["htop"])
      ]),
      leaf(commands: ["nvim"])
    ])

    result = Builder.build(root, width: 200, height: 50, pane_ids: [0, 1, 2, 3])

    # Verify it has checksum + valid structure
    assert_match(/\A[0-9a-f]{4},200x50,0,0\{/, result)
    # Verify checksum matches body
    parts = result.split(",", 2)
    checksum = parts[0]
    body = result[(checksum.length + 1)..]
    assert_equal checksum, Builder.layout_checksum(body)
  end

  def test_build_falls_back_to_sequential_ids_when_pane_ids_short
    l1 = leaf(commands: ["a"])
    l2 = leaf(commands: ["b"])
    l3 = leaf(commands: ["c"])
    root = container(:horizontal, [l1, l2, l3])

    # Only provide 1 pane ID instead of 3
    Builder.build(root, width: 200, height: 50, pane_ids: [5])

    assert_equal 5, l1.pane_id  # from pane_ids
    assert_equal 1, l2.pane_id  # fallback to index
    assert_equal 2, l3.pane_id  # fallback to index
  end

  def test_build_falls_back_to_sequential_ids_when_pane_ids_empty
    l1 = leaf(commands: ["a"])
    l2 = leaf(commands: ["b"])
    root = container(:horizontal, [l1, l2])

    result = Builder.build(root, width: 200, height: 50, pane_ids: [])

    assert_equal 0, l1.pane_id
    assert_equal 1, l2.pane_id
    # Should still produce a valid layout string
    assert_match(/\A[0-9a-f]{4},/, result)
  end
end
