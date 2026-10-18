# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class ProjectRootTest < AceCoworkerTestCase
        def test_uses_git_toplevel_and_falls_back_to_cwd
          dir = Dir.mktmpdir("coworker-root")
          runner = ->(*args) {
            assert_equal ["-C", dir, "rev-parse", "--show-toplevel"], args
            ["/some/root\n", "", CoworkerFixture::SuccessStatus.ok]
          }
          assert_equal "/some/root", ProjectRoot.new(git_runner: runner).resolve(from: dir)

          failing = ->(*_args) { ["", "fatal", CoworkerFixture::SuccessStatus.new(false)] }
          assert_equal File.expand_path(dir), ProjectRoot.new(git_runner: failing).resolve(from: dir)
        ensure
          FileUtils.remove_entry(dir)
        end
      end
    end
  end
end
