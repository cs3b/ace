# frozen_string_literal: true

require_relative "../test_helper"

class SetupExecutorTmuxTest < Minitest::Test
  def setup
    @executor = Ace::Test::EndToEndRunner::Molecules::SetupExecutor.new
  end

  def test_tmux_session_uses_run_id_when_available
    skip "tmux not available" unless system("tmux", "-V", out: File::NULL, err: File::NULL)

    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{"tmux-session" => {"name-source" => "run-id"}}],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEST-001",
        run_id: "8pny7t0"
      )

      assert result[:success]
      assert_equal "8pny7t0", result[:tmux_session]
      assert system("tmux", "has-session", "-t", "8pny7t0", out: File::NULL, err: File::NULL)
    ensure
      @executor.teardown
    end
  end

  def test_tmux_session_falls_back_to_scenario_name
    skip "tmux not available" unless system("tmux", "-V", out: File::NULL, err: File::NULL)

    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: ["tmux-session"],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEST-001"
      )

      assert result[:success]
      assert_equal "TS-TEST-001-e2e", result[:tmux_session]
      assert system("tmux", "has-session", "-t", "TS-TEST-001-e2e", out: File::NULL, err: File::NULL)
    ensure
      @executor.teardown
    end
  end

  def test_tmux_teardown_removes_session
    skip "tmux not available" unless system("tmux", "-V", out: File::NULL, err: File::NULL)

    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: ["tmux-session"],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEARDOWN-001"
      )

      assert result[:success]
      session_name = result[:tmux_session]
      assert system("tmux", "has-session", "-t", session_name, out: File::NULL, err: File::NULL)

      @executor.teardown

      refute system("tmux", "has-session", "-t", session_name, out: File::NULL, err: File::NULL)
    end
  end
end
