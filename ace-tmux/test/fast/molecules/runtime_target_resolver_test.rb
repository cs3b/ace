# frozen_string_literal: true

require_relative "../../test_helper"

class RuntimeTargetResolverTest < Minitest::Test
  def test_resolve_session_prefers_explicit_flag
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: MockExecutor.new,
      env: {"ACE_TMUX_SESSION" => "env-session", "TMUX" => "/tmp/socket"}
    )

    target = resolver.resolve_session(session: "cli-session")

    assert_equal "cli-session", target.session
    assert_equal "explicit", target.source
  end

  def test_resolve_window_uses_env_window_with_resolved_session
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: MockExecutor.new(
        capture_responses: {
          'tmux list-windows -t dev -F #{window_id}	#{window_index}	#{window_name}	#{window_active}' => mock_result(stdout: "@7\t4\tlogs\t1")
        }
      ),
      env: {"ACE_TMUX_SESSION" => "dev", "ACE_TMUX_WINDOW" => "logs"}
    )

    target = resolver.resolve_window

    assert_equal "dev", target.session
    assert_equal "logs", target.window
    assert_equal "@7", target.window_target
    assert_equal "env", target.source
  end

  def test_resolve_window_preserves_raw_window_id_when_lookup_is_unavailable
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: MockExecutor.new(capture_responses: {:default => mock_result(success: false, exit_code: 1)}),
      env: {"ACE_TMUX_SESSION" => "dev"}
    )

    target = resolver.resolve_window(window: "@7")

    assert_equal "dev", target.session
    assert_equal "@7", target.window
    assert_equal "@7", target.window_target
    assert_equal "explicit", target.source
  end

  def test_resolve_pane_uses_live_tmux_when_needed
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t dev: -p #{window_id}	#{window_index}	#{window_name}' => mock_result(stdout: "@3\t2\twork"),
        'tmux display-message -t @3 -p #{pane_index}' => mock_result(stdout: "0")
      }
    )
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: executor,
      env: {"ACE_TMUX_SESSION" => "dev", "TMUX" => "/tmp/socket"}
    )

    target = resolver.resolve_pane

    assert_equal "dev", target.session
    assert_equal "work", target.window
    assert_equal "0", target.pane
    assert_equal "@3.0", target.pane_target
    assert_equal "live", target.source
  end

  def test_resolve_pane_accepts_current_window_dot_shorthand
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: MockExecutor.new(
        capture_responses: {
          'tmux list-windows -t dev -F #{window_id}	#{window_index}	#{window_name}	#{window_active}' => mock_result(stdout: "@2\t3\tace.t.n1d\t1")
        }
      ),
      env: {"ACE_TMUX_SESSION" => "dev", "ACE_TMUX_WINDOW" => "ace.t.n1d"}
    )

    target = resolver.resolve_pane(pane: ".3")

    assert_equal "dev", target.session
    assert_equal "ace.t.n1d", target.window
    assert_equal "3", target.pane
    assert_equal "@2.3", target.pane_target
    assert_equal "explicit", target.source
  end

  def test_resolve_pane_keeps_accepting_bare_index_in_current_window
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: MockExecutor.new(
        capture_responses: {
          'tmux list-windows -t dev -F #{window_id}	#{window_index}	#{window_name}	#{window_active}' => mock_result(stdout: "@2\t3\tace.t.n1d\t1")
        }
      ),
      env: {"ACE_TMUX_SESSION" => "dev", "ACE_TMUX_WINDOW" => "ace.t.n1d"}
    )

    target = resolver.resolve_pane(pane: "3")

    assert_equal "dev", target.session
    assert_equal "ace.t.n1d", target.window
    assert_equal "3", target.pane
    assert_equal "@2.3", target.pane_target
    assert_equal "explicit", target.source
  end

  def test_resolve_pane_resolves_dotted_full_target_through_window_id
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: MockExecutor.new(
        capture_responses: {
          'tmux list-windows -t default -F #{window_id}	#{window_index}	#{window_name}	#{window_active}' => mock_result(stdout: "@2\t3\tace.t.n1d\t0")
        }
      ),
      env: {}
    )

    target = resolver.resolve_pane(pane: "default:ace.t.n1d.3")

    assert_equal "default", target.session
    assert_equal "ace.t.n1d", target.window
    assert_equal "3", target.pane
    assert_equal "@2.3", target.pane_target
  end

  def test_resolve_pane_accepts_raw_window_id_pane_target
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: MockExecutor.new, env: {})

    target = resolver.resolve_pane(pane: "@2.3")

    assert_equal "@2.3", target.pane
    assert_equal "@2.3", target.pane_target
  end

  def test_resolve_pane_rejects_colon_form_and_teaches_dotted_target
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: MockExecutor.new, env: {})

    error = assert_raises(Ace::Tmux::ValidationError) { resolver.resolve_pane(pane: "default:3:1") }

    assert_equal "Invalid pane target 'default:3:1'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'.", error.message
  end

  def test_resolve_pane_rejects_window_id_without_pane_suffix
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: MockExecutor.new, env: {})

    error = assert_raises(Ace::Tmux::ValidationError) { resolver.resolve_pane(pane: "@1") }

    assert_equal "Invalid pane target '@1'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'. '@1' is a tmux window id, not a pane target.", error.message
  end

  def test_resolve_session_raises_when_no_context_exists
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: MockExecutor.new, env: {})

    assert_raises(Ace::Tmux::TargetResolutionError) { resolver.resolve_session }
  end

  def test_resolve_window_uses_explicit_session_active_window_fallback_outside_tmux
    executor = MockExecutor.new(
      capture_responses: {
        'tmux display-message -t demo: -p #{window_id}	#{window_index}	#{window_name}' => mock_result(stdout: ""),
        'tmux list-windows -t demo -F #{window_id}	#{window_index}	#{window_name}	#{window_active}' => mock_result(stdout: "@1\t1\twork\t1\n@2\t2\tlogs\t0")
      }
    )
    resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
      executor: executor,
      env: {"ACE_TMUX_SESSION" => "demo"}
    )

    target = resolver.resolve_window

    assert_equal "demo", target.session
    assert_equal "work", target.window
    assert_equal "@1", target.window_target
    assert_equal "live", target.source
  end
end
