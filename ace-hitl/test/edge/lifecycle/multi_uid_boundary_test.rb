# frozen_string_literal: true

require "test_helper"
require "etc"
require "json"
require "open3"
require "fileutils"

# REAL multi-UID acceptance for the scoped store boundary (spec
# 8wq.t.34i SC1/SC2): the suite forks the installed service under one
# unprivileged OS account and drives it through the real AF_UNIX socket
# with two distinct requester accounts and a transport account. Kernel
# peer credentials decide identity; store files prove OS-level
# isolation; races commit one terminal transition. Mocked ownership
# alone cannot prove any of this.
#
# The fixture REQUIRES root (euid 0): only root may drop children to
# other existing accounts. Without root it reports one explicit skip —
# the installed OS-boundary acceptance additionally joins vs2 and
# lab-config:gad.b and is never claimed complete from local unit runs.
class MultiUidBoundaryTest < AceHitlTestCase
  SERVICE_USERS = %w[daemon _daemon nobody www-data _www messagebus _messagebus sshd _sshd lp _lp].freeze
  REQUESTER_USERS = %w[nobody www-data _www daemon lp _lp sshd _sshd messagebus _messagebus].freeze

  def test_multi_uid_boundary
    skip "multi-UID acceptance requires root (re-run under sudo/CI); local unit runs stay unproven" unless Process.euid.zero?

    accounts = select_accounts
    scratch = File.join(Dir.tmpdir, "ace-hitl-multiiuid-#{Process.pid}")
    FileUtils.mkdir_p(scratch)
    FileUtils.chmod(0o755, scratch)

    service_uid = accounts[:service].uid
    common_gid = accounts[:requester_a].gid
    store_root = File.join(scratch, "store")
    socket_dir = File.join(scratch, "boundary")
    socket_path = File.join(socket_dir, "hitl.sock")
    FileUtils.mkdir_p(store_root)
    FileUtils.chown(service_uid, common_gid, store_root)
    FileUtils.mkdir_p(socket_dir)
    FileUtils.chown(service_uid, common_gid, socket_dir)
    FileUtils.chmod(0o750, socket_dir)

    @socket_path = socket_path
    @service_uid = service_uid
    service_pid = spawn_service(store_root: store_root, socket_path: socket_path,
      service_uid: service_uid, gid: common_gid)
    wait_for_socket(socket_path)

    assignment = "8x3edge"
    attempt = "edge01"

    # --- SC1: requester isolation ---------------------------------------
    created = run_as(accounts[:requester_a], gid: common_gid,
      argv: ["create", "req0001", assignment, attempt])
    assert created["ok"], "requester A creates its own request: #{created}"

    own = run_as(accounts[:requester_a], gid: common_gid, argv: ["read", "req0001"])
    assert own["ok"], "the requester reads its own request: #{own}"
    assert_equal accounts[:requester_a].name, own["result"]["requester"],
      "the request records the KERNEL identity of the creating peer"

    foreign = run_as(accounts[:requester_b], gid: common_gid, argv: ["read", "req0001"])
    refute foreign["ok"], "a foreign identity cannot read another requester's request"

    foreign = run_as(accounts[:requester_b], gid: common_gid, argv: ["consume", "req0001", "1"])
    refute foreign["ok"], "a foreign identity cannot consume another requester's answer"

    # Forged payload identity: the payload `requester` field is not a
    # boundary parameter — it can never make requester B the requester.
    forged = run_as(accounts[:requester_b], gid: common_gid,
      argv: ["forge", "req0002", assignment, attempt, accounts[:requester_a].name])
    refute forged["ok"], "a forged payload requester is refused"
    forged2 = run_as(accounts[:requester_a], gid: common_gid,
      argv: ["forge", "req0002", assignment, attempt, accounts[:requester_b].name])
    refute forged2["ok"], "even a valid peer cannot inject a requester field"

    # --- SC1: OS-level filesystem isolation ------------------------------
    probe = run_as(accounts[:requester_b], gid: common_gid,
      argv: ["directread", File.join(store_root, "requests", "req0001.json")])
    refute probe["ok"], "the store's request files are unreadable to a foreign uid"
    assert_includes probe["error"], "Errno::EACCES" if probe.key?("error")

    mode = run_as(accounts[:requester_b], gid: common_gid,
      argv: ["peekmode", store_root])
    assert mode["ok"]
    assert_equal 0o711, mode["result"]["mode"], "the store root is traverse-only"

    # --- transport path ----------------------------------------------------
    delivered = run_as(accounts[:transport], gid: common_gid,
      argv: ["deliver", "req0001", "approved-by-captain"])
    assert delivered["ok"], "the configured transport delivers: #{delivered}"
    assert_equal true, delivered["result"]["delivered"]

    consumed = run_as(accounts[:requester_a], gid: common_gid,
      argv: ["consume", "req0001", "5"])
    assert consumed["ok"], "the requester consumes its answer: #{consumed}"
    assert_equal "approved-by-captain", consumed["result"]["answer"]

    # The consumed answer file never leaks: requester B cannot read it.
    answer_probe = run_as(accounts[:requester_b], gid: common_gid,
      argv: ["directread", File.join(store_root, "answers", "req0001.answer")])
    refute answer_probe["ok"], "the consumed answer never outlives the request on disk"

    # --- SC2: one terminal transition under cancel/consume races ----------
    run_as(accounts[:requester_a], gid: common_gid, argv: ["create", "req0003", assignment, attempt])
    run_as(accounts[:transport], gid: common_gid, argv: ["deliver", "req0003", "race-answer"])

    racer_cancel = Thread.new do
      run_as(accounts[:requester_a], gid: common_gid, argv: ["cancel", "req0003"])
    end
    racer_consume = Thread.new do
      run_as(accounts[:requester_a], gid: common_gid, argv: ["consume", "req0003", "5"])
    end
    cancel_result = racer_cancel.value
    consume_result = racer_consume.value

    states = run_as(accounts[:transport], gid: common_gid, argv: ["states"])
    assert states["ok"]
    state = states["result"].find { |record| record["id"] == "req0003" }
    assert state, "the raced request has a public projection"
    assert %w[consumed cancelled].include?(state["state"]),
      "exactly ONE terminal transition wins the race (got #{state["state"]})"

    if state["state"] == "consumed"
      assert consume_result["ok"], "the consume winner returns the answer: #{consume_result}"
      refute cancel_result["ok"], "the cancel loser fails closed: #{cancel_result}"
      assert_match(/already consumed/, cancel_result["error"]) if cancel_result.key?("error")
    else
      assert cancel_result["ok"], "the cancel winner commits: #{cancel_result}"
      refute consume_result["ok"], "the consume loser fails closed: #{consume_result}"
    end

    # --- SC2: reused process id / stale identity gains nothing ------------
    # The boundary authorizes by peer uid and live binding facts — never
    # by pid, env, or recorded runtime strings. A NEW child process
    # (fresh pid) of a foreign uid cannot consume the terminal request.
    late = run_as(accounts[:requester_b], gid: common_gid, argv: ["consume", "req0003", "1"])
    refute late["ok"], "a foreign fresh-pid consumer never touches another's request"

    # --- store file ownership stays service-owned -------------------------
    store_stat = File.stat(File.join(store_root, "requests"))
    assert_equal service_uid, store_stat.uid, "requests/ is service-owned"
    assert_equal 0o700, store_stat.mode & 0o777
  ensure
    if service_pid
      begin
        Process.kill("TERM", service_pid)
        Process.wait(service_pid)
      rescue StandardError
        nil
      end
    end
    FileUtils.remove_entry(scratch) if scratch && File.exist?(scratch)
  end

  private

  # Distinct, existing, unprivileged accounts for service/requesters/
  # transport; the fixture never creates users or groups.
  def select_accounts
    service = SERVICE_USERS.filter_map do |name|
      begin
        Etc.getpwnam(name)
      rescue ArgumentError
        nil
      end
    end.uniq(&:uid).reject { |u| u.uid.zero? || u.uid == Process.uid }.first
    requesters = REQUESTER_USERS.filter_map do |name|
      begin
        Etc.getpwnam(name)
      rescue ArgumentError
        nil
      end
    end.uniq(&:uid).reject { |u| u.uid.zero? || u.uid == Process.uid || u.uid == service&.uid }

    skip "no usable unprivileged accounts for the multi-UID fixture" unless service && requesters.length >= 2

    {service: service, requester_a: requesters[0], requester_b: requesters[1],
     transport: requesters[2] || requesters[0]}
  end

  # Fork the service child, drop it to the service identity (with the
  # shared connect group), and let it serve the REAL dispatch loop.
  def spawn_service(store_root:, socket_path:, service_uid:, gid:)
    pid = fork do
      begin
        Process::Sys.setgid(gid)
        Process::Sys.setuid(service_uid)
        service = Ace::Hitl::Lifecycle::Service.new(
          root: store_root,
          binding: open_binding,
          policy: open_policy,
          socket_path: socket_path,
          group: Etc.getgrgid(gid).name
        )
        service.run
      rescue StandardError
        exit! 1
      end
    end
    raise "service child failed to start" unless pid
    pid
  end

  # Fork a child dropped to the target identity; one op per child, one
  # JSON result line back over a pipe.
  def run_as(account, gid:, argv:)
    load_paths = monorepo_load_paths
    reader, writer = IO.pipe
    pid = fork do
      reader.close
      $stdout.reopen(writer)
      $stderr.reopen(File::NULL)
      writer.close
      begin
        Process::Sys.setgid(gid)
        Process::Sys.setuid(account.uid)
        ENV["ACE_HITL_SOCKET"] = @socket_path
        ENV["ACE_HITL_SERVICE_UID"] = @service_uid.to_s
        args = [RbConfig.ruby]
        load_paths.each { |path| args << "-I" << path }
        args << File.expand_path("support/boundary_child.rb", __dir__)
        args.concat(argv)
        Process.exec(*args)      rescue StandardError
        exit! 1
      end
    end
    writer.close
    output = reader.read
    reader.close
    _pid, status = Process.wait2(pid)
    line = output.lines.find { |candidate| candidate.strip.start_with?("{") }
    unless line
      return {"ok" => false, "op" => argv[0], "error" => "child crashed",
              "detail" => output.strip[0, 200], "exit" => status.exitstatus}
    end

    JSON.parse(line)
  end

  def wait_for_socket(socket_path)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
    until File.exist?(socket_path)
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        raise "the boundary socket never appeared"
      end

      sleep 0.05
    end
  end

  # Every checkout lib dir the child needs to load ace-hitl without
  # bundler (the service and the boundary child are bare interpreters).
  def monorepo_load_paths
    @monorepo_load_paths ||= $LOAD_PATH.select do |path|
      path.start_with?(File.expand_path("../../../..", __dir__)) && File.directory?(path)
    end.uniq
  end

  def open_binding
    Class.new(Ace::Hitl::Lifecycle::Binding) do
      def validate_request(**); end

      def require_active(**); end

      def with_active(**)
        yield
      end
    end.new
  end

  def open_policy
    Class.new do
      def transport?(_peer, project: nil)
        true
      end

      def service_uid; end
    end.new
  end
end
