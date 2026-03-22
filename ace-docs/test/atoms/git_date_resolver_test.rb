# frozen_string_literal: true

require "test_helper"
require "ace/docs/molecules/git_date_resolver"

module Ace
  module Docs
    module Molecules
      class GitDateResolverTest < Minitest::Test
        def test_returns_date_when_git_log_succeeds
          status = Object.new
          status.define_singleton_method(:success?) { true }

          Open3.stub :capture3, ["2026-03-19\n", "", status] do
            result = GitDateResolver.last_updated_for("README.md")
            assert_equal Date.new(2026, 3, 19), result
          end
        end

        def test_returns_nil_when_git_log_fails
          status = Object.new
          status.define_singleton_method(:success?) { false }

          Open3.stub :capture3, ["", "err", status] do
            assert_nil GitDateResolver.last_updated_for("README.md")
          end
        end
      end
    end
  end
end
