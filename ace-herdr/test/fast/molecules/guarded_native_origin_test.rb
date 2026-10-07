# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/herdr/molecules/guarded_native_origin"

class GuardedNativeOriginTest < Minitest::Test
  Origin = Ace::Herdr::Molecules::GuardedNativeOrigin
  def origin
    {"terminal_id" => "term_ab", "runtime_incarnation" => "12345678-1234-1234-1234-123456789abc",
      "child" => {"pid" => 101, "parent_pid" => 90, "uid" => 13001, "gid" => 13001, "groups" => [13001],
        "host" => "worker", "started_at" => "linux:12345678-1234-1234-1234-123456789abc:10"}}
  end
  def verify(value)
    Origin.verify!(value, terminal_id: origin.fetch("terminal_id"), child: origin.fetch("child"))
  end
  def test_source_origin_joins_exact_terminal_child_and_is_detached_immutable
    source = origin
    accepted = verify(source)
    assert_equal source, accepted
    source["child"]["groups"] << 99999
    assert_equal [13001], accepted.dig("child", "groups")
    assert_raises(FrozenError) { accepted.dig("child", "host").replace("other") }
    assert_raises(FrozenError) { accepted["terminal_id"] = "term_bb" }
  end
  def test_unknown_malformed_replaced_or_noncanonical_native_values_refuse
    variants = [origin.merge("other" => true), origin.merge("terminal_id" => "pane"), origin.merge("runtime_incarnation" => "bad"),
      origin.merge("runtime_incarnation" => "\xff".b), origin.merge("child" => nil), origin.merge("child" => origin.fetch("child").merge("pid" => 102)),
      origin.merge("child" => origin.fetch("child").merge("groups" => [13001, 13001])),
      origin.merge("child" => origin.fetch("child").merge("uid" => 13001.0)),
      origin.merge("child" => origin.fetch("child").merge("started_at" => "linux:boot:10")),
      origin.merge("child" => origin.fetch("child").merge("host" => "secret\n"))]
    variants.each { |value| assert_raises(Ace::Runtime::RuntimeUnavailableError) { verify(value) } }
  end
  def test_integer_and_birth_bounds_match_pinned_native_schema
    value = origin
    value["child"]["pid"] = 0
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { Origin.verify!(value, terminal_id: "term_ab", child: value["child"]) }
    value["child"]["pid"] = 101
    value["child"]["started_at"] = "linux:12345678-1234-1234-1234-123456789abc:18446744073709551616"
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { Origin.verify!(value, terminal_id: "term_ab", child: value["child"]) }
    value["child"]["started_at"] = "linux:12345678-1234-1234-1234-123456789abc:0010"
    assert_equal value, Origin.verify!(value, terminal_id: "term_ab", child: value["child"])
  end
end
