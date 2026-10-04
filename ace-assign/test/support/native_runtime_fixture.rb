# frozen_string_literal: true

require "open3"
require "timeout"

# Each fixture owns its native server and uses a short Darwin-safe socket path.
module NativeRuntimeFixture
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
