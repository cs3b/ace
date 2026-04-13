# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentTargetTest < AceAssignTestCase
  class Resolver
    include Ace::Assign::CLI::Commands::AssignmentTarget

    public :resolve_assignment_target
    public :parse_assignment_target
  end

  def test_parse_assignment_id_without_scope
    target = Resolver.new.parse_assignment_target("8pg4g1")

    assert_equal "8pg4g1", target.assignment_id
    assert_nil target.scope
  end

  def test_parse_assignment_with_scope
    target = Resolver.new.parse_assignment_target("8pg4g1@010.01")

    assert_equal "8pg4g1", target.assignment_id
    assert_equal "010.01", target.scope
  end

  def test_parse_assignment_with_empty_scope_raises
    error = assert_raises(Ace::Support::Cli::Error) do
      Resolver.new.parse_assignment_target("8pg4g1@")
    end

    assert_includes error.message, "scope after '@' cannot be empty"
  end

  def test_parse_assignment_without_id_raises
    error = assert_raises(Ace::Support::Cli::Error) do
      Resolver.new.parse_assignment_target("@010")
    end

    assert_includes error.message, "requires assignment ID before '@'"
  end

  def test_resolve_assignment_target_uses_explicit_assignment_only
    target = Resolver.new.resolve_assignment_target(assignment: "8pg4g1@010.01")

    assert_equal "8pg4g1", target.assignment_id
    assert_equal "010.01", target.scope
  end

  def test_resolve_assignment_target_ignores_ace_assign_id_env
    previous = ENV["ACE_ASSIGN_ID"]
    ENV["ACE_ASSIGN_ID"] = "8pg4g1@010.01"

    target = Resolver.new.resolve_assignment_target({})
    assert_nil target.assignment_id
    assert_nil target.scope
  ensure
    if previous.nil?
      ENV.delete("ACE_ASSIGN_ID")
    else
      ENV["ACE_ASSIGN_ID"] = previous
    end
  end
end
