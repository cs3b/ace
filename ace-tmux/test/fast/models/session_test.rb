# frozen_string_literal: true

require_relative "../../test_helper"

class SessionModelTest < Minitest::Test
  def test_minimal_initialization
    session = Ace::Tmux::Models::Session.new(name: "dev")

    assert_equal "dev", session.name
    assert_nil session.root
    assert_equal [], session.windows
    assert_nil session.pre_window
    assert_nil session.startup_window
    assert_equal [], session.on_project_start
    assert_equal [], session.on_project_exit
    assert_equal true, session.attach
    assert_nil session.tmux_options
  end

  def test_full_initialization
    window = Ace::Tmux::Models::Window.new(name: "editor")
    session = Ace::Tmux::Models::Session.new(
      name: "dev",
      root: "~/projects/app",
      windows: [window],
      pre_window: "nvm use 18",
      startup_window: "editor",
      on_project_start: ["docker-compose up -d"],
      on_project_exit: ["docker-compose down"],
      attach: false,
      tmux_options: "-f ~/.tmux.special.conf"
    )

    assert_equal "dev", session.name
    assert_equal "~/projects/app", session.root
    assert_equal 1, session.windows.length
    assert_equal "nvm use 18", session.pre_window
    assert_equal "editor", session.startup_window
    assert_equal ["docker-compose up -d"], session.on_project_start
    assert_equal ["docker-compose down"], session.on_project_exit
    assert_equal false, session.attach
    assert_equal "-f ~/.tmux.special.conf", session.tmux_options
  end

  def test_attach_predicate
    assert Ace::Tmux::Models::Session.new(name: "s", attach: true).attach?
    refute Ace::Tmux::Models::Session.new(name: "s", attach: false).attach?
    assert Ace::Tmux::Models::Session.new(name: "s").attach?
  end

  def test_on_project_start_coerces_to_array
    session = Ace::Tmux::Models::Session.new(
      name: "dev",
      on_project_start: "docker-compose up"
    )
    assert_equal ["docker-compose up"], session.on_project_start
  end

  def test_to_h
    session = Ace::Tmux::Models::Session.new(
      name: "dev",
      root: "~/app",
      startup_window: "editor"
    )

    hash = session.to_h
    assert_equal "dev", hash["name"]
    assert_equal "~/app", hash["root"]
    assert_equal "editor", hash["startup_window"]
    assert_equal true, hash["attach"]
    assert_equal [], hash["windows"]
  end

  def test_to_h_omits_empty_hooks
    session = Ace::Tmux::Models::Session.new(name: "dev")
    hash = session.to_h

    refute hash.key?("on_project_start")
    refute hash.key?("on_project_exit")
  end

  def test_root_writer_overrides_initial_root
    session = Ace::Tmux::Models::Session.new(name: "dev", root: "~/original")
    assert_equal "~/original", session.root

    session.root = "~/override"
    assert_equal "~/override", session.root
  end

  def test_root_writer_sets_nil_root
    session = Ace::Tmux::Models::Session.new(name: "dev")
    assert_nil session.root

    session.root = "~/new-root"
    assert_equal "~/new-root", session.root
  end
end
