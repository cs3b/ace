# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "timeout"

# Opt in via a test-runner environment override. The test owns a named
# native server and never connects to the operator's active session.
class RuntimeRetainedShellTest < AceAssignTestCase
  def test_submitted_command_exit_preserves_the_same_writable_prepared_target
    runtime_name = ENV["ACE_NATIVE_RUNTIME"]
    skip "requires explicit ACE_NATIVE_RUNTIME fixture override" unless %w[herdr tmux].include?(runtime_name)

    @scratch = Dir.mktmpdir("ace-native", "/tmp")
    @fixture_env = %w[HERDR_CONFIG_PATH HERDR_SOCKET_PATH HERDR_SESSION HERDR_PANE HERDR_WORKSPACE_ID
      XDG_CONFIG_HOME TMUX ACE_TMUX_SESSION].to_h { |key| [key, ENV[key]] }
    if runtime_name == "herdr"
      start_herdr
    else
      @tmux_socket = File.join(@scratch, "tmux.sock")
      native("tmux", "-S", @tmux_socket, "-f", "/dev/null", "new-session", "-d", "-s", "proof", "-c", @scratch)
      native("tmux", "-S", @tmux_socket, "set-option", "-g", "default-shell", "/bin/bash")
      ENV["TMUX"] = "#{@tmux_socket},#{Process.pid},0"
      ENV["ACE_TMUX_SESSION"] = "proof"
    end
    Ace::Runtime.reset_registry!
    runner = Ace::Assign::Molecules::RuntimeControlSurfaceRunner.new(runtime: runtime_name)
    window = runner.ensure_window(name: "retain-proof", root: @scratch)
    pane = runner.prepare_pane(window: window)
    marker = File.join(@scratch, "first")
    runner.run_invocation_in_pane(pane_target: pane, command: ["sh", "-c", "printf first > #{marker}"],
      working_dir: @scratch)
    wait_until { File.file?(marker) }
    assert_equal "first", File.read(marker)
    # Native observation establishes the retained shell before a second
    # command; pane existence or remain-on-exit alone cannot satisfy it.
    if runtime_name == "herdr"
      info = JSON.parse(native("herdr", "pane", "process-info", "--pane", pane))
        .fetch("result").fetch("process_info")
      assert_kind_of Integer, info["shell_pid"], "submitted command replaced the prepared shell"
    else
      assert_equal "0", native("tmux", "display-message", "-p", "-t", pane, '#{pane_dead}').strip,
        "submitted command left a dead prepared pane"
    end
    marker2 = File.join(@scratch, "second")
    runner.run_invocation_in_pane(pane_target: pane, command: ["sh", "-c", "printf second > #{marker2}"],
      working_dir: @scratch)
    wait_until { File.file?(marker2) }
    assert_equal "second", File.read(marker2)
    assert_equal pane, runner.prepare_pane(window: window), "retained target was split or replaced"
    verify_pointer_replacement(runner) if runtime_name == "herdr"
  ensure
    if @pid
      Process.kill("TERM", -@pid) rescue nil
      Process.wait(@pid) rescue nil
    end
    native("tmux", "-S", @tmux_socket, "kill-server") if @tmux_socket
    @log&.close
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
    @fixture_env&.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    Ace::Runtime.reset_registry!
  end

  def verify_pointer_replacement(runner)
    created = JSON.parse(native("herdr", "tab", "create", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID"),
      "--label", "foreign-proof", "--cwd", @scratch))
    tab = created.fetch("result").fetch("tab").fetch("tab_id")
    old = runner.prepare_pane(window: tab)
    digest = Digest::SHA256.hexdigest("#{ENV.fetch('HERDR_WORKSPACE_ID')}\0foreign-proof")
    path = File.join(Dir.home, ".ace/local/herdr/runtime-tabs", "#{digest}.json")
    assert_equal %w[id prepared_pane], JSON.parse(File.read(path)).keys.sort
    native("herdr", "pane", "close", old)
    fresh = Ace::Assign::Molecules::RuntimeControlSurfaceRunner.new(runtime: "herdr")
    replacement = fresh.prepare_pane(window: tab)
    refute_equal old, replacement
    assert_equal %w[id prepared_pane], JSON.parse(File.read(path)).keys.sort
    restarted = Ace::Assign::Molecules::RuntimeControlSurfaceRunner.new(runtime: "herdr")
    assert_equal replacement, restarted.prepare_pane(window: tab)
    assert_equal tab, restarted.ensure_window(name: "foreign-proof", root: @scratch)
    assert_equal replacement, restarted.prepare_pane(window: tab)
    assert_raises(Ace::Assign::Error) { restarted.ensure_window(name: "foreign-proof", root: "/") }
    assert_equal replacement, restarted.prepare_pane(window: tab)
  end

  def start_herdr
    session = "ace-retain-#{Process.pid}"
    @log = File.open(File.join(@scratch, "server.log"), "w")
    ENV["XDG_CONFIG_HOME"] = @scratch
    ENV["HERDR_CONFIG_PATH"] = File.join(@scratch, "config.toml")
    File.write(ENV["HERDR_CONFIG_PATH"], "[terminal]\ndefault_shell = \"/bin/bash\"\nshell_mode = \"non_login\"\n")
    @pid = Process.spawn("herdr", "--session", session, "server", out: @log, err: @log, pgroup: true)
    socket = File.join(@scratch, "herdr/sessions", session, "herdr.sock")
    begin
      wait_until { File.socket?(socket) }
    rescue Timeout::Error
      flunk "isolated native server did not start: #{File.read(@log.path)}"
    end
    created = native("herdr", "--session", session, "workspace", "create", "--cwd", @scratch,
      "--label", "retention-proof", "--no-focus")
    caller = JSON.parse(created).fetch("result").fetch("root_pane")
    ENV["HERDR_SOCKET_PATH"] = socket
    ENV["HERDR_SESSION"] = session
    ENV["HERDR_PANE"] = caller.fetch("pane_id")
    ENV["HERDR_WORKSPACE_ID"] = caller.fetch("workspace_id")
  end

  def native(*argv)
    stdout, stderr, status = Open3.capture3(*argv)
    assert status.success?, "#{argv.take(3).join(' ')} failed: #{stderr}"
    stdout
  end

  def wait_until
    Timeout.timeout(10) { sleep(0.02) until yield }
  end
end
