# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../../ace-assign/test/support/prepared_registration_fixture"
require_relative "../../../ace-assign/test/support/ordinary_native_observation"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"
require "ace/lab/molecules/command_owner_admission"
require "delegate"

# Real journal, registration, native-bound start, candidate transfer, Unix read,
# policy/compiler and immutable-view checks. Only installed root ownership and
# launcher/native observation are controlled. This neither runs a child nor
# supplies a canonical successful-test receipt or installed-runtime acceptance.
class CommandOwnerCandidateIntegrationTest < Minitest::Test
  Assign = Ace::Assign
  Lab = Ace::Lab
  class InstalledStat < SimpleDelegator
    def uid = 0
  end

  def test_real_canonical_candidate_drives_production_admission_claim_download_and_historical_validation
    fixture do
      reference = current_reference
      selected = selection(reference)
      definition = scoped(reference) { @admission.command_request!(selection: selected, peer: @peer, execution_id: "test1", deadline: deadline) }
      assert_equal @head, definition.dig("source", "head")
      assert_equal reference, definition.dig("candidate", "reference")
      assert_equal @native.bindings.fetch("producer"), definition.fetch("native_binding")
      refute_equal selected.fetch("argv"), definition.fetch("argv")
      assert_includes definition.fetch("argv"), File.join(@views, "test1/config/runner.json")
      scoped(reference) do
        assert @admission.command_claim!(definition: definition, caller: @peer, launcher: @launcher, deadline: deadline)
        assert_equal @canonical_bundle, @admission.command_candidate!(definition: definition, peer: @launcher, deadline: deadline)
      end
      materialize(definition)
      assert @admission.command_test_evidence!(definition: definition, deadline: deadline)
      # The original CLI can disappear; historical proof uses its retained
      # admitted native binding plus the canonical still-active producer.
      @admission.instance_variable_get(:@peer).stub(:live!, ->(*) { flunk "historical evidence must not probe the old requester CLI" }) do
        assert @admission.command_test_evidence!(definition: definition, deadline: deadline, historical: true)
      end
      submit(generation: 2, candidate_generation: 1, mutation: "candidate2")
      assert_raises(Assign::AttemptErrors::Conflict) do
        @admission.command_test_evidence!(definition: definition, deadline: deadline)
      end
      assert @admission.command_test_evidence!(definition: definition, deadline: deadline, historical: true)
      @admission.with_command_scope(reference: reference, deadline: deadline, historical: true) do
        assert_raises(Assign::AttemptErrors::EvidenceUnavailable) do
          @admission.command_request!(selection: selected, peer: @peer, execution_id: "test1", deadline: deadline)
        end
      end
      assert_raises(Assign::AttemptErrors::Conflict) do
        scoped(reference) { @admission.command_claim!(definition: definition, caller: @peer, launcher: @launcher, deadline: deadline) }
      end
      configuration = File.join(@views, "test1/config/runner.json")
      File.binwrite(configuration, "tampered")
      assert_raises(Assign::AttemptErrors::ReceiptRejected) do
        @admission.command_test_evidence!(definition: definition, deadline: deadline, historical: true)
      end
      File.unlink(configuration)
      assert_raises(Assign::AttemptErrors::ReceiptRejected) do
        @admission.command_test_evidence!(definition: definition, deadline: deadline, historical: true)
      end
    end
  end

  def test_real_git_uses_repository_root_when_kernel_reports_another_owner
    fixture do
      reference = current_reference
      definition = scoped(reference) { @admission.command_request!(selection: selection(reference), peer: @peer, execution_id: "test1", deadline: deadline) }
      materialize(definition)
      process = Ace::Herdr::Molecules::BoundedProcess
      original = process.method(:call)
      # Git's real ownership-check fixture switch models only its UID
      # observation; actual Git discovery/config/source checks still execute.
      process.stub(:call, lambda { |argv, **options|
        if argv.first == "/usr/bin/git" && argv.any? { |item| item.start_with?("safe.directory=") }
          options = options.merge(environment: options.fetch(:environment).merge("GIT_TEST_ASSUME_DIFFERENT_OWNER" => "1"))
        end
        original.call(argv, **options)
      }) do
        assert @admission.command_test_evidence!(definition: definition, deadline: deadline)
      end
    end
  end

  def test_native_origin_scope_lifetime_and_current_policy_are_not_inferred_from_caller_labels
    fixture do
      reference = current_reference
      assert_raises(Lab::InvalidConfigurationError) do
        @admission.command_request!(selection: selection(reference), peer: @peer, execution_id: "test1", deadline: deadline)
      end
      @native.selected = "supervisor"
      assert_raises(Assign::AttemptErrors::UnauthorizedIdentity) do
        scoped(reference) { @admission.command_request!(selection: selection(reference).merge("pane" => "w1:pS"), peer: @peer, execution_id: "test1", deadline: deadline) }
      end
      @native.selected = "producer"
      definition = scoped(reference) { @admission.command_request!(selection: selection(reference), peer: @peer, execution_id: "test1", deadline: deadline) }
      materialize(definition)
      @policy_document.fetch("projects").fetch("atlas").fetch("grants").clear
      assert_raises(Assign::AttemptErrors::ReceiptRejected) do
        @admission.command_test_evidence!(definition: definition, deadline: deadline, historical: true)
      end
      @native.revoked = true
      assert_raises(Assign::AttemptErrors::UnauthorizedIdentity) do
        @owner.with_candidate_reference(reference: reference, deadline: deadline) { flunk "revoked native producer cannot resolve a view" }
      end
    end
  end

  private

  def deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
  def scoped(reference, &block) = @admission.with_command_scope(reference: reference, deadline: deadline, &block)
  def selection(reference) = {"argv" => ["bin/ace-test", "feat"], "executor" => nil, "services" => nil, "pane" => "w1:p1", "candidate" => reference}
  def current_reference = @client.call("candidate_reference", {"assignment_id" => "producer", "attempt_id" => "producer-run"}).data
  def submit(generation: 1, candidate_generation: 0, mutation: "candidate")
    @native.selected = "producer"
    @client.call("submit_candidate", {"assignment_id" => "producer", "attempt_id" => "producer-run", "head" => @head,
      "candidate_generation" => candidate_generation, "pane" => "w1:p1", "expected_generation" => generation},
      mutation_id: mutation, upload_parts: [@bundle], purpose: :candidate)
  end
  def git(path, *args)
    out, err, status = Open3.capture3("/usr/bin/git", "-C", path, *args)
    raise err unless status.success?
    out
  end

  def materialize(definition)
    root = File.join(@views, "test1")
    Dir.mkdir(root, 0o755)
    materialized = Assign::Authority::CandidateTransfer.new(root: @scratch).materialize_repository(
      bytes: @canonical_bundle, sha256: Digest::SHA256.hexdigest(@canonical_bundle), size: @canonical_bundle.bytesize,
      head: @head, tree: definition.dig("source", "tree"), root: @scratch)
    File.rename(materialized.fetch("directory"), File.join(root, "source"))
    Dir.mkdir(File.join(root, "config"), 0o755)
    runtime = Lab::Molecules::CommandTestRuntime.new(@profile)
    File.binwrite(File.join(root, "config/Gemfile"), runtime.gemfile(root))
    File.binwrite(File.join(root, "config/runner.json"), runtime.configuration(root))
    Find.find(File.join(root, "source"), ignore_error: false) do |path|
      File.chmod(File.directory?(path) ? 0o555 : 0o444, path)
    end
  end

  def fixture
    skip "nonroot host ownership-projection fixture; actual root IO has its own kernel fixture" if Process.uid.zero?
    Dir.mktmpdir("lab-canonical-command-", Etc.getpwuid(Process.uid).dir) do |root|
      File.chmod(0o700, root)
      repository, inputs, @scratch, @views, installed = %w[repo inputs scratch views installed].map { |name| File.join(root, name) }
      FileUtils.mkdir_p([repository, inputs, @scratch, @views, installed], mode: 0o700)
      git(repository, "init", "-b", "main")
      FileUtils.mkdir_p(File.join(repository, "pkg"))
      File.binwrite(File.join(repository, "pkg/source.txt"), "Canonical candidate bytes.\n")
      git(repository, "add", ".")
      git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "candidate")
      @head = git(repository, "rev-parse", "HEAD").strip
      git(repository, "bundle", "create", File.join(root, "candidate.bundle"), "--all")
      @bundle = File.binread(File.join(root, "candidate.bundle"))
      journal = Assign::Molecules::EvidenceJournal.new(repo_root: repository, checkout_root: File.join(root, "checkout"))
      service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
      @native = Assign::OrdinaryNativeObservation.new(service)
      @native.head = @head
      process = Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid)
      @native.bindings = %w[producer supervisor].each_with_index.to_h do |name, index|
        [name, {"runtime" => "herdr", "session" => "w1", "pane" => ["w1:p1", "w1:pS"][index], "agent" => "pi",
          "agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid}, "process_identity" => process}]
      end
      build_policy(installed)
      @admission = Lab::Molecules::CommandOwnerAdmission.new(base: @native, project: "atlas", candidate_owner: -> { @owner },
        policy_loader: -> { Lab::Molecules::CommandPolicy.new(@policy_document, project: "atlas") })
      @owner = Assign::Authority::OrdinaryLifecycle.new(project: "atlas", admission: @native, journal: journal,
        exclusion: Assign::Molecules::LifecycleExclusion.new(root: File.join(root, "exclusion")), input_root: inputs)
      server = Assign::Authority::OrdinaryServer.new(admission: @native, lifecycle: Assign::Authority::Router.new(handlers: [@owner]))
      thread = Thread.new { server.serve }
      Timeout.timeout(3) { sleep 0.005 until File.socket?(service.fetch("socket_path")) }
      @client = Assign::Authority::OrdinaryClient.new(project_id: "atlas", service: service, scratch_root: @scratch, verify_selection: -> {})
      @native.selected = "supervisor"
      work = Assign::PreparedRegistrationFixture.build(root: inputs, scope: "010.01", definition: {
        "session_id" => "producer", "project_id" => "atlas", "task_id" => "8xf.t.ei9.5", "name" => "producer",
        "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
      @client.call("register_assignment", work.header(expected_generation: 0).merge("pane" => "w1:pS"),
        mutation_id: "register", upload_parts: [work.bundle], purpose: :candidate)
      @native.selected = "producer"
      @client.call("start_attempt", {"assignment_id" => "producer", "attempt_id" => "producer-run", "expected_generation" => 0,
        "head" => @head, "pane" => "w1:p1", "scope" => "010.01"}, mutation_id: "start")
      submit
      @owner.with_candidate_reference(reference: current_reference, deadline: deadline) { |_, _, _, bytes| @canonical_bundle = bytes }
      left, right = UNIXSocket.pair
      @peer = Assign::Authority::OrdinaryPeer.new.capture(left)
      @launcher = {"uid" => 0, "pid" => 42, "started_at" => "controlled-root-launcher", "host" => "fixture"}
      # Named installed-root/kernel boundaries only: real file bytes and modes,
      # projected root ownership (host tests cannot create installed root data).
      lstat, read, directory, root_path = File.method(:lstat), Lab::Molecules::GrantResolver.method(:read_verified),
        Lab::Molecules::GrantResolver.method(:trusted_directory!), Ace::Runtime::Molecules::ProtectedSocket.method(:root_path!)
      controlled = ->(path) { path == installed || path.start_with?(installed + "/") || path == @views || path.start_with?(@views + "/") }
      File.stub(:lstat, ->(path) { stat = lstat.call(path); controlled.call(path) ? InstalledStat.new(stat) : stat }) do
        Lab::Molecules::GrantResolver.stub(:read_verified, ->(path) { controlled.call(path) ? File.binread(path) : read.call(path) }) do
          Lab::Molecules::GrantResolver.stub(:trusted_directory!, ->(path) { controlled.call(path) ? File.directory?(path) : directory.call(path) }) do
            Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, ->(path, **options) { controlled.call(path) ? File.directory?(path) : root_path.call(path, **options) }) do
              @admission.stub(:command_launcher!, ->(peer:, **) { raise Assign::AttemptErrors::UnauthorizedIdentity unless peer == @launcher; peer }) { yield }
            end
          end
        end
      end
    ensure
      left&.close; right&.close
      server&.request_stop; server&.stop
      assert thread.join(3), "canonical owner must drain" if thread
      Find.find(@views, ignore_error: false) { |path| File.chmod(0o700, path) if File.directory?(path) } if @views && File.directory?(@views)
    end
  end

  def build_policy(installed)
    gems = File.join(installed, "gems")
    %w[cache specifications gems].each { |name| FileUtils.mkdir_p(File.join(gems, name)) }
    File.binwrite(File.join(gems, "cache/fixture-dependency-1.0.0.gem"), "controlled runtime archive bytes")
    File.binwrite(File.join(gems, "specifications/fixture-dependency-1.0.0.gemspec"), "data never evaluated")
    FileUtils.mkdir_p(File.join(gems, "gems/fixture-dependency-1.0.0"))
    executable = "/usr/bin/true"
    digest = Digest::SHA256.file(executable).hexdigest
    @profile = {"schema" => "ruby-test-runtime/v1", "gem_paths" => [gems],
      "gems" => {"fixture-dependency" => {"version" => "1.0.0", "sha256" => Digest::SHA256.hexdigest("controlled runtime archive bytes")}},
      "source_gems" => {"fixture-source" => "pkg"}, "package" => "pkg",
      "argv" => [executable, executable, "--config-path", "@configuration", "--report-dir", "@output"],
      "executable_sha256" => digest, "entrypoint_sha256" => digest}
    profile_path = File.join(installed, "runtime.json")
    File.binwrite(profile_path, JSON.generate(@profile))
    @policy_document = {"version" => 1, "projects" => {"atlas" => {
      "launcher" => {"socket_path" => "/run/lab/fixture.sock", "identity_path" => "/run/lab/fixture.json"},
      "default_executor" => "worker", "default_services" => [],
      "executors" => {"worker" => {"uid" => Process.uid.nonzero? || 65534, "gid" => Process.gid.nonzero? || 65534,
        "groups" => [], "home" => "/usr/bin", "cwd" => "/usr/bin", "path" => ["/usr/bin"], "environment" => {}}},
      "services" => {}, "commands" => {"tests" => {"argv" => ["bin/ace-test", "feat"], "executable_sha256" => digest,
        "source" => {"kind" => "ordinary-candidate", "root" => @views, "runtime_path" => profile_path,
          "runtime_sha256" => Digest::SHA256.file(profile_path).hexdigest}, "purpose" => "test"}},
      "grants" => [{"kind" => "agent", "uid" => Process.uid.nonzero? || 65534, "command" => "tests", "executor" => "worker", "services" => []}]}}}
  end
end
