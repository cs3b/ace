# frozen_string_literal: true

require_relative "../../test_helper"

class ArgvCoalescerTest < AceSupportCliTestCase
  def test_top_level_require_exposes_canonical_constant
    assert_equal Ace::Support::Cli::ArgvCoalescer, Ace::Support::Cli::ArgvCollector
  end

  def test_coalesces_matching_flags
    result = Ace::Support::Cli::ArgvCoalescer.call(
      ["--tag", "a", "--other", "--tag=b"],
      flags: {"--tag" => ["-t"]}
    )

    assert_equal ["--other", "--tag", "a,b"], result
  end
end
