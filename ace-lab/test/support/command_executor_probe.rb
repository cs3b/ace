# frozen_string_literal: true
# Disposable Linux root kernel fixture. Not an installed authority or CLI proof.
require "ace/lab/organisms/command_executor"
require "ace/lab/molecules/command_owner_admission"
require "tmpdir"
require "fileutils"

Reply = Struct.new(:data, :replayed, keyword_init: true)
class ProbeOwner
  attr_reader :events, :child, :result
  def initialize(definition, mode)
    @definition, @mode, @events = definition, mode, []
  end
  def call(operation, params, **)
    @events << operation
    case operation
    when "command_status" then Reply.new(data: {"phase" => "admitted", "definition" => @definition}, replayed: false)
    when "command_claim" then Reply.new(data: {}, replayed: @mode == "replay_claim")
    when "command_bind"
      @child = params.fetch("child")
      raise SecurityError, "lost bind acknowledgment" if @mode == "lost_bind"
      Reply.new(data: {}, replayed: false)
    when "command_complete"
      @result = params.fetch("result")
      Reply.new(data: {}, replayed: false)
    else raise "unexpected owner operation"
    end
  end
end
mode = ARGV.fetch(0)
Dir.mktmpdir("ace-command-probe-", "/run") do |directory|
  File.chmod(0o755, directory)
  account = Etc.getpwnam("nobody")
  if mode == "policy"
    accepted = File.join(directory, "accepted")
    Dir.mkdir(accepted, 0o755)
    executable = File.join(accepted, "probe")
    File.write(executable, "#!/bin/sh\nexit 0\n")
    File.chmod(0o755, executable)
    listener = UNIXServer.new(File.join(directory, "caller.sock"))
    File.chmod(0o666, listener.path)
    caller = fork do
      listener.close
      Process.groups = []
      Process::GID.change_privilege(account.gid)
      Process::UID.change_privilege(account.uid)
      channel = UNIXSocket.new(File.join(directory, "caller.sock"))
      channel.read(1)
      exit! 0
    end
    channel = listener.accept
    peer = Ace::Assign::Authority::OrdinaryPeer.new.capture(channel)
    executor = Etc.getpwnam("daemon")
    document = {"version" => 1, "projects" => {"ace" => {
      "launcher" => {"socket_path" => "/run/lab/labd.sock", "identity_path" => "/run/lab/labd-command-identity.json"},
      "default_executor" => "probe", "default_services" => [], "services" => {},
      "executors" => {"probe" => {"uid" => executor.uid, "gid" => executor.gid, "groups" => [], "home" => "/nonexistent",
        "cwd" => accepted, "path" => ["/usr/bin", "/bin"], "environment" => {}}},
      "commands" => {"probe" => {"argv" => ["./probe"], "executable_sha256" => Digest::SHA256.file(executable).hexdigest,
        "source" => {"head" => nil, "tree" => nil}}},
      "grants" => [{"kind" => "operator", "uid" => account.uid, "command" => "probe", "executor" => "probe", "services" => []}]}}}
    path = File.join(directory, "policy.json")
    File.write(path, JSON.generate(document))
    File.chmod(0o644, path)
    admission = Ace::Lab::Molecules::CommandOwnerAdmission.new(base: Object.new, project: "ace", policy_loader: lambda {
      Ace::Lab::Molecules::CommandPolicy.new(JSON.parse(Ace::Lab::Molecules::GrantResolver.read_verified(path)), project: "ace") })
    selection = {"argv" => ["./probe"], "executor" => nil, "services" => nil, "pane" => nil}
    call = -> { admission.command_request!(selection: selection, peer: peer, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5) }
    definition = call.call
    denied = []
    link = File.join(directory, "system-bin")
    File.symlink("/usr/bin", link)
    Ace::Lab::Molecules::GrantResolver.trusted_directory!(link)
    File.lchown(account.uid, account.gid, link)
    begin
      Ace::Lab::Molecules::GrantResolver.trusted_directory!(link)
    rescue Ace::Lab::Error
      denied << "requester_owned_alias"
    ensure
      File.unlink(link)
    end
    File.chmod(0o777, accepted)
    begin
      call.call
    rescue Ace::Runtime::Error, Ace::Lab::Error, SecurityError
      denied << "writable_source"
    ensure
      File.chmod(0o755, accepted)
    end
    File.write(executable, "#!/bin/sh\nexit 17\n")
    begin
      call.call
    rescue Ace::Runtime::Error, Ace::Lab::Error, SecurityError
      denied << "changed_executable"
    end
    channel.write("E")
    channel.close
    listener.close
    Process.waitpid(caller)
    puts JSON.generate({"kind" => definition["requester_kind"], "caller_uid" => peer["uid"], "executor_uid" => definition.dig("executor", "uid"), "denied" => denied})
    next
  end
  if %w[detached detached_disconnect].include?(mode)
    # Fixture owner reaps any escaped process after recording the failure; it
    # never substitutes for the command helper's own cleanup acceptance.
    prctl = Fiddle::Function.new(Fiddle::Handle::DEFAULT["prctl"],
      [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG], Fiddle::TYPE_INT)
    raise "fixture subreaper unavailable" unless prctl.call(36, 1, 0, 0, 0).zero?
  end
  program = case mode
  when "detached", "detached_disconnect" then <<~PYTHON
    import os,time,json
    r,w=os.pipe()
    child=os.fork()
    if child == 0:
      os.close(r)
      os.setsid()
      detached=os.fork()
      if detached != 0:
        os._exit(0)
      pid=os.getpid()
      birth=open('/proc/self/stat').read().rpartition(')')[2].split()[19]
      print(json.dumps({'detached_pid':pid,'birth':birth}),flush=True)
      os.write(w,b'R')
      os.close(w)
      time.sleep(60)
      os._exit(0)
    os.close(w)
    os.read(r,1)
    os.close(r)
    os.waitpid(child,0)
    #{mode == "detached_disconnect" ? "time.sleep(60)" : "os._exit(17)"}
  PYTHON
  when "pty" then "import os,signal; print('TTY='+str(os.isatty(0)),flush=True); os.kill(os.getpid(),signal.SIGTERM)"
  when "getpass" then "import getpass,os,struct,fcntl,termios; x=getpass.getpass('OTP: '); print('GOT='+str(len(x))); print('SIZE='+str(struct.unpack('HHHH',fcntl.ioctl(0,termios.TIOCGWINSZ,bytes(8)))[:2]),flush=True)"
  else "import os,sys,json; print(json.dumps({'uid':os.getuid(),'gid':os.getgid(),'groups':os.getgroups(),'cwd':os.getcwd(),'tty':os.isatty(0),'data':sys.stdin.read()})); sys.exit(17)"
  end
  definition = {"requester" => {"uid" => 1000}, "secret_references" => {}, "argv" => ["/usr/bin/python3", "-c", program],
    "executor" => {"uid" => account.uid, "gid" => account.gid, "groups" => [], "home" => "/nonexistent",
      "cwd" => directory, "path" => ["/usr/bin", "/bin"], "environment" => {"LANG" => "C.UTF-8"}}}
  client, server = UNIXSocket.pair
  result_read, result_write = IO.pipe
  helper = fork do
    client.close
    result_read.close
    owner = ProbeOwner.new(definition, mode)
    begin
      Ace::Lab::Organisms::CommandExecutor.new(project: "ace", owner: owner).run(socket: server,
        request: {"execution_id" => "fixture", "caller" => {"uid" => 1000}, "tty" => %w[pty getpass].include?(mode), "rows" => 24, "cols" => 80})
      error = nil
      error_details = nil
    rescue Exception => exception
      error = exception.class.name
      error_details = {"message" => exception.message, "backtrace" => exception.backtrace.first(8)}
    ensure
      result_write.write(JSON.generate({"events" => owner.events, "child" => owner.child, "result" => owner.result, "error" => error, "error_details" => error_details}))
      result_write.close
      server.close
    end
    exit! 0
  end
  server.close
  result_write.close
  frames = []
  while (line = client.gets)
    frame = JSON.parse(line)
    frames << frame
    if frame["type"] == "started"
      if mode == "getpass"
        client.write(JSON.generate({"type" => "resize", "rows" => 31, "cols" => 97}) + "\n")
      else
        client.write(JSON.generate({"type" => "input", "data" => Base64.strict_encode64("hello")}) + "\n") unless mode == "pty"
        client.write(JSON.generate({"type" => "eof"}) + "\n") unless mode == "pty"
      end
    end
    if mode == "getpass" && frame["type"] == "output" && Base64.strict_decode64(frame["data"]).include?("OTP:")
      client.write(JSON.generate({"type" => "input", "data" => Base64.strict_encode64("123456\n")}) + "\n")
    end
    if mode == "detached_disconnect" && frame["type"] == "output" && Base64.strict_decode64(frame.fetch("data")).include?("detached_pid")
      break # Actual transport loss while leader and detached descendant live.
    end
    break if frame["type"] == "result"
  end
  client.close
  result = JSON.parse(result_read.read)
  Process.waitpid(helper)
  if %w[detached detached_disconnect].include?(mode)
    bytes = frames.select { |frame| frame["type"] == "output" }.map { |frame| Base64.strict_decode64(frame.fetch("data")) }.join
    observed = JSON.parse(bytes.lines.find { |line| line.include?("detached_pid") })
    pid = observed.fetch("detached_pid")
    stat = "/proc/#{pid}/stat"
    remaining = File.exist?(stat) && File.read(stat).rpartition(")").last.split.fetch(19) == observed.fetch("birth")
    result["detached"] = observed.merge("survived_cleanup" => remaining)
    if remaining
      # Exact original birth and adoption by fixture owner are mandatory. This
      # cleanup records a product failure; it cannot make the test pass.
      fields = File.read(stat).rpartition(")").last.split
      raise "escaped fixture child has foreign owner" unless fields.fetch(1).to_i == Process.pid
      Process.kill("KILL", pid)
      Process.waitpid(pid)
    end
  end
  puts JSON.generate(result.merge("frames" => frames))
end
