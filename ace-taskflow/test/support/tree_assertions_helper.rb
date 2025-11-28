# frozen_string_literal: true

module TreeAssertionsHelper
  # Assert that output contains a tree node with the given name
  # Handles both single (├─, └─) and double (├──, └──) tree connector variants
  #
  # @param output [String] The output to search within
  # @param node_name [String] The name of the tree node to find
  # @param message [String, nil] Optional custom error message
  # @return [Boolean] Result of the assertion
  def assert_output_has_tree_node(output, node_name, message = nil)
    # Escape special regex characters in node_name
    escaped_name = Regexp.escape(node_name)

    # Check for both single and double connector variants
    single_connector_pattern = /├─\s*#{escaped_name}|└─\s*#{escaped_name}/
    double_connector_pattern = /├──\s*#{escaped_name}|└──\s*#{escaped_name}/

    has_single_connector = output.match?(single_connector_pattern)
    has_double_connector = output.match?(double_connector_pattern)

    has_tree_node = has_single_connector || has_double_connector

    default_message = "Expected tree connector for '#{node_name}' not found in output"
    assert has_tree_node, message || default_message

    has_tree_node
  end
end