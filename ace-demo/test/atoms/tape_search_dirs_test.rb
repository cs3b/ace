# frozen_string_literal: true

require_relative "../test_helper"

class TapeSearchDirsTest < AceDemoTestCase
  def test_build_returns_cascade_order
    dirs = Ace::Demo::Atoms::TapeSearchDirs.build(
      cwd: "/tmp/project",
      home_dir: "/tmp/home",
      gem_root: "/tmp/gem"
    )

    assert_equal [
      "/tmp/project/.ace/demo/tapes",
      "/tmp/home/.ace/demo/tapes",
      "/tmp/gem/.ace-defaults/demo/tapes"
    ], dirs
  end
end
