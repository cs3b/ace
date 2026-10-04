# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "test_helper"

module Forgejo
  # Selected-repository binding matrix: every provider call carries the
  # selected host/owner/repository — `fj` subprocesses through `-H` plus the
  # qualified reference, API exchanges through the selected-repository URL —
  # and two servers sharing PR/issue numbers with conflicting cwd, remote
  # order, and default login cannot cross-route; all pre-send failures
  # classify with zero wrongly targeted requests.
  class RepositoryBindingTest < AceGitForgejoTestCase
    LAB_A = Ace::Git::ResolvedServer.new(name: "lab-a", provider: :forgejo, url: "https://forge.example.com/lab-a/repo")
    LAB_B = Ace::Git::ResolvedServer.new(name: "lab-b", provider: :forgejo, url: "https://other.example.com:3443/lab-b/repo")
    SHA = "a" * 40

    def test_every_request_of_selected_server_carries_its_identity
      commands = recording_runner(lab_b_fixtures)
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)

      provider.pull_request(number: 7)
      provider.pull_request_diff(number: 7)
      provider.pull_request_for_branch(branch: "feature")
      provider.recent_pull_requests(limit: 5)
      provider.issue(number: 7)
      provider.checks(ref: SHA)
      provider.repository

      refute_empty commands.argvs
      commands.argvs.each do |argv|
        case argv.first
        when "fj"
          next if argv == %w[fj version] # control probe, host-scoped only

          assert_equal ["-H", "https://other.example.com:3443"], argv[1, 2],
            "every subprocess must carry the selected authority"
          assert_nil argv.index("-C"), "cwd must never be used for targeting"
          assert_includes argv.join(" "), "lab-b/repo",
            "every subprocess must reference the selected repository"
        when "forgejo-http"
          assert_includes argv[2], "https://other.example.com:3443/api/v1/repos/lab-b/repo/",
            "every API exchange must target the selected repository on the selected authority"
        else
          flunk("unexpected transport: #{argv.first}")
        end
      end
      api_read = commands.argvs.find { |argv| argv.first == "forgejo-http" && argv[2]&.end_with?("/pulls/7") }
      assert api_read, "pull request identity reads must ride the selected-repository API route"
      pr_view = commands.argvs.find { |argv| argv.include?("pr") && argv.include?("view") && argv.last.end_with?("#7") }
      assert_equal "lab-b/repo#7", pr_view.last, "fj PR reads must use the qualified selected-repository reference"
    end

    def test_same_numbers_on_two_servers_never_cross_route
      commands = recording_runner(
        lab_b_fixtures.merge(lab_a_fixtures).merge("forgejo-api" => lambda do |args|
          api_ok(args[2].to_s.include?("forge.example.com") ? pr_payload(repo: "lab-a/repo") : pr_payload(repo: "lab-b/repo"))
        end)
      )
      lab_a = Ace::Git::Forgejo::Provider.new(server: LAB_A, runner: commands.recorder)
      lab_b = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)

      pr_a = lab_a.pull_request(number: 7)
      pr_b = lab_b.pull_request(number: 7)

      assert_equal "https://forge.example.com/lab-a/repo/pulls/7", pr_a.url
      assert_equal "https://other.example.com:3443/lab-b/repo/pulls/7", pr_b.url
      api_reads = commands.argvs.select { |argv| argv.first == "forgejo-http" && argv[2]&.end_with?("/pulls/7") }
      assert_equal 2, api_reads.length
      assert_equal "https://forge.example.com/api/v1/repos/lab-a/repo/pulls/7", api_reads[0][2]
      assert_equal "https://other.example.com:3443/api/v1/repos/lab-b/repo/pulls/7", api_reads[1][2]
    end

    def test_unobserved_cli_version_refuses_cli_operations_with_zero_mutation_subprocesses
      # An fj whose argv surface was never observed must not inherit CLI
      # capabilities; API-backed reads and mutations have their own
      # transport and capability gates and do not consult the CLI probe.
      commands = recording_runner(
        "fj version" => {success: true, stdout: "fj v0.9.9\n", stderr: "", exit_code: 0},
        "forgejo-api" => api_ok(pr_payload)
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)

      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.pull_request_for_branch(branch: "feature") }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.pull_request_diff(number: 7) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.recent_pull_requests(limit: 5) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.issue(number: 7) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.checks(ref: SHA) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.repository }

      assert commands.argvs.any?, "the version gate must probe before refusing"
      commands.argvs.each do |argv|
        assert_equal %w[fj version], argv,
          "a refused CLI may only run the version probe; zero repository or mutation subprocesses"
      end
    end

    def test_malformed_selection_fails_as_configuration_before_any_subprocess
      commands = recording_runner
      broken = Ace::Git::ResolvedServer.new(name: "broken", provider: :forgejo, url: "https://forge.example.com")
      provider = Ace::Git::Forgejo::Provider.new(server: broken, runner: commands.recorder)

      error = assert_raises(Ace::Git::ConfigError) { provider.pull_request(number: 7) }
      assert_match(/owner\/repository/, error.message)

      auth_error = assert_raises(Ace::Git::ConfigError) { provider.authenticated? }
      assert_match(/owner\/repository/, auth_error.message)

      assert_empty commands.argvs, "malformed selection must fail before any request"
    end

    def test_cli_missing_and_failed_auth_classify_without_repository_commands
      missing = recording_runner(
        "fj version" => {success: false, stdout: "", stderr: "command not found", exit_code: 127}
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: missing.recorder)
      assert_raises(Ace::Git::ProviderCliMissingError) { provider.check_available! }

      no_login = recording_runner(
        "fj version" => {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0},
        "fj auth list" => {success: true, stdout: "forge.example.com\n", stderr: "", exit_code: 0}
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: no_login.recorder)
      error = assert_raises(Ace::Git::ProviderAuthenticationError) { provider.check_authenticated! }
      assert_match(/other\.example\.com:3443/, error.message)

      (missing.argvs + no_login.argvs).each do |argv|
        assert_includes %w[version auth], argv[1],
          "only control probes may run; no repository or mutation request"
      end
    end

    def test_exact_authority_authentication_ignores_superstring_hosts
      commands = recording_runner(
        "fj version" => {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0},
        "fj auth list" => {success: true, stdout: "sub.forge.example.com\nforge.example.com.evil.test\n", stderr: "", exit_code: 0}
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_A, runner: commands.recorder)
      refute provider.authenticated?, "substring or suffixed host lines must not satisfy the selected authority"
    end

    def test_conflicting_returned_identity_fails_closed
      commands = recording_runner(
        "forgejo-api" => api_ok(pr_payload(number: 99))
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_A, runner: commands.recorder)
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) { provider.pull_request(number: 7) }
      assert_match(/#99/, error.message)
      assert_match(/for selected #7/, error.message)

      commands = recording_runner(
        "fj version" => {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0},
        "fj -H https://forge.example.com --style minimal repo view lab-a/repo" => {
          success: true, stdout: "other/other\nView online at https://forge.example.com/other/other\n", stderr: "", exit_code: 0
        }
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_A, runner: commands.recorder)
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) { provider.repository }
      assert_match(%r{other/other}, error.message)
      assert_match(%r{lab-a/repo}, error.message)
    end

    def test_create_and_reconciliation_stay_on_selected_identity_throughout
      argvs = []
      lists = 0
      runner = lambda do |args:, timeout: nil, env: nil|
        argvs << args
        path = args[2].to_s
        case path
        when "https://other.example.com:3443/api/v1/repos/lab-b/repo"
          api_ok({"id" => 2, "full_name" => "lab-b/repo", "owner" => {"id" => 20, "login" => "lab-b"}})
        when "https://other.example.com:3443/api/v1/version"
          api_ok({"version" => "8.0.5"})
        when "https://other.example.com:3443/api/v1/repos/lab-b/repo/pulls?state=open&page=1&limit=50"
          lists += 1
          api_ok(lists == 1 ? [] : [pr_payload])
        when "https://other.example.com:3443/api/v1/repos/lab-b/repo/pulls"
          assert_equal "POST", args[1]
          assert_equal({"title" => "WIP: Ship it", "base" => "main", "head" => "feature"}, args[3])
          api_created(pr_payload)
        when "https://other.example.com:3443/api/v1/repos/lab-b/repo/pulls/7"
          api_ok(pr_payload)
        else
          flunk("Unexpected request: #{args.join(' ')}")
        end
      end

      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: runner)
      receipt = provider.create_pull_request(
        head_repository_url: LAB_B.url, head_ref: "feature", base_ref: "main",
        expected_head: SHA, title: "Ship it"
      )
      assert_equal :created, receipt.idempotency
      assert_equal 7, receipt.pull_request.number

      argvs.each do |argv|
        assert_equal "https://other.example.com:3443", argv[2].to_s[/\Ahttps:\/\/[^\/]+/],
          "every request targets the selected authority"
      end
      assert_equal 1, argvs.count { |argv| argv[1] == "POST" && argv[2].end_with?("/repos/lab-b/repo/pulls") },
        "exactly one create send, no automatic retry"
      assert_equal 1, argvs.count { |argv| argv[2].include?("/pulls?state=open") },
        "the pre-send lookup lists the selected repository"
      assert_equal 1, argvs.count { |argv| argv[2].end_with?("/pulls/7") },
        "the accepted create is proven by one authoritative read-back"
    end

    def test_mutations_never_run_for_classified_pre_send_refusals
      argvs = []
      runner = lambda do |args:, **|
        argvs << args
        path = args[2].to_s
        if path.include?("/pulls?state=open")
          api_ok([])
        else
          flunk("no request may follow the refusal: #{args.join(' ')}")
        end
      end
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: runner)

      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        provider.create_pull_request(
          head_repository_url: "https://evil.example.com/forker/repo", head_ref: "feature",
          base_ref: "main", expected_head: SHA, title: "Ship it"
        )
      end
      assert_raises(ArgumentError) { provider.merge_pull_request(number: 7, expected_head: SHA, method: :fast_forward) }
      assert_raises(Ace::Git::ConfigError) { provider.pull_request_diff(number: "abc") }
      assert_raises(Ace::Git::ConfigError) { provider.update_pull_request(number: "", expected_head: SHA, title: "t") }

      assert argvs.all? { |argv| argv[2].to_s.include?("/pulls?state=open") },
        "only the create pre-check may read; no mutation may be sent for refused work"
    end

    def test_conflicting_fj_alias_refuses_api_operations_too
      keys_path = File.join(Dir.tmpdir, "uj0-alias-test-#{Process.pid}-conflict.json")
      File.write(keys_path, {
        "hosts" => {}, "aliases" => {"other.example.com:3443" => "evil.example.test"}, "default_ssh" => []
      }.to_json)
      stub_keys_path(keys_path) do
        commands = recording_runner
        provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)
        error = assert_raises(Ace::Git::ConfigError) { provider.pull_request(number: 7) }
        assert_match(/redirects selected host other\.example\.com:3443/, error.message)
        assert_match(/evil\.example\.test/, error.message)
        assert_empty commands.argvs,
          "alias conflict refuses before any API exchange or subprocess"
      end
    ensure
      File.delete(keys_path) if keys_path && File.exist?(keys_path)
    end

    def test_benign_alias_and_missing_keys_file_allow_operations
      benign_path = File.join(Dir.tmpdir, "uj0-alias-test-#{Process.pid}-benign.json")
      File.write(benign_path, {
        "hosts" => {}, "aliases" => {"ssh.other.example.com" => "other.example.com:3443"}, "default_ssh" => []
      }.to_json)
      stub_keys_path(benign_path) do
        commands = recording_runner(lab_b_fixtures)
        provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)
        assert_equal 7, provider.pull_request(number: 7).number
      end

      stub_keys_path(nil) do
        commands = recording_runner(lab_b_fixtures)
        provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)
        assert_equal 7, provider.pull_request(number: 7).number
      end
    ensure
      File.delete(benign_path) if benign_path && File.exist?(benign_path)
    end

    def test_default_keys_path_finds_macos_bundle_dir_credentials
      home = File.join(Dir.tmpdir, "qk12-fj-home-#{Process.pid}")
      current = File.join(home, "Library", "Application Support", "forgejo-cli.forgejo-cli", "keys.json")
      FileUtils.mkdir_p(File.dirname(current))
      File.write(current, {"hosts" => {}}.to_json)
      # Setup installs a nil lookup stub; restore the real implementation.
      RepositoryBindingStub.remove
      Dir.stub(:home, home) do
        assert_equal current, Ace::Git::Forgejo::RepositoryBinding.default_keys_path
      end

      # The legacy vendor-prefixed bundle dir is the fallback.
      FileUtils.rm_rf(File.dirname(current))
      legacy = File.join(home, "Library", "Application Support", "Cyborus.forgejo-cli", "keys.json")
      FileUtils.mkdir_p(File.dirname(legacy))
      File.write(legacy, {"hosts" => {}}.to_json)
      Dir.stub(:home, home) do
        assert_equal legacy, Ace::Git::Forgejo::RepositoryBinding.default_keys_path
      end
    ensure
      RepositoryBindingStub.install(nil)
      FileUtils.rm_rf(home) if home && File.exist?(home)
    end

    private

    def stub_keys_path(path, &block)
      Ace::Git::Forgejo::RepositoryBinding.singleton_class.send(:alias_method, :original_keys_path_lookup, :default_keys_path)
      Ace::Git::Forgejo::RepositoryBinding.define_singleton_method(:default_keys_path) { path }
      block.call
    ensure
      Ace::Git::Forgejo::RepositoryBinding.singleton_class.send(:alias_method, :default_keys_path, :original_keys_path_lookup)
      Ace::Git::Forgejo::RepositoryBinding.singleton_class.send(:remove_method, :original_keys_path_lookup)
    end

    def view(number, state, head_ref)
      # Real fj v0.6.0 minimal-style shape (em-dash byline, From segment).
      <<~TEXT
        Ship it ##{number}
        By lab-builder — #{state} — +10 -2
        From `#{head_ref}` into `main`
      TEXT
    end

    def api_ok(payload)
      {success: true, status: 200, stdout: payload.to_json, stderr: "", exit_code: 0}
    end

    def api_created(payload)
      {success: true, status: 201, stdout: payload.to_json, stderr: "", exit_code: 0}
    end

    def pr_payload(number: 7, repo: "lab-b/repo")
      {
        "number" => number,
        "title" => "WIP: Ship it",
        "body" => "Ship the thing",
        "state" => "open",
        "draft" => true,
        "merged" => false,
        "merged_at" => nil,
        "merge_commit_sha" => nil,
        "user" => {"login" => "lab-builder"},
        "head" => {"label" => "#{repo}:feature", "ref" => "feature", "sha" => SHA,
                   "repo" => {"full_name" => repo, "id" => 2}},
        "base" => {"label" => "main", "ref" => "main", "sha" => "b" * 40,
                   "repo" => {"full_name" => repo, "id" => 2}}
      }
    end

    def lab_a_fixtures
      prefix = "fj -H https://forge.example.com --style minimal"
      {
        "#{prefix} pr view lab-a/repo#7" => {success: true, stdout: view(7, "Open", "feature"), stderr: "", exit_code: 0},
        "#{prefix} pr view lab-a/repo#7 commits" => {success: true, stdout: "commit #{SHA} (+1, -0)\n", stderr: "", exit_code: 0},
        "forgejo-api" => api_ok(pr_payload(repo: "lab-a/repo"))
      }
    end

    def lab_b_fixtures
      prefix = "fj -H https://other.example.com:3443 --style minimal"
      {
        "fj version" => {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0},
        "#{prefix} pr view lab-b/repo#7" => {success: true, stdout: view(7, "Open", "feature"), stderr: "", exit_code: 0},
        "#{prefix} pr view lab-b/repo#7 commits" => {success: true, stdout: "commit #{SHA} (+1, -0)\n", stderr: "", exit_code: 0},
        "fj -H https://other.example.com:3443 pr view lab-b/repo#7 diff" => {
          success: true, stdout: "diff --git a/x b/x\n", stderr: "", exit_code: 0
        },
        "#{prefix} pr search --state all -r lab-b/repo" => {
          success: true, stdout: "1 pull requests\n#7: Ship it (by lab-builder)\n", stderr: "", exit_code: 0
        },
        "#{prefix} issue view lab-b/repo#7" => {
          success: true, stdout: "Broken thing #7\nBy lab-builder — Open — +0 -0\n", stderr: "", exit_code: 0
        },
        "#{prefix} actions tasks -r lab-b/repo" => {
          success: true, stdout: "1 tasks\n#12 (#{SHA}) success test-suite 23s (push): subject\n", stderr: "", exit_code: 0
        },
        "#{prefix} repo view lab-b/repo" => {
          success: true, stdout: "lab-b/repo\n> Selected repository\nView online at https://other.example.com:3443/lab-b/repo\n",
          stderr: "", exit_code: 0
        },
        "forgejo-api" => api_ok(pr_payload)
      }
    end

    def recording_runner(responses = {})
      argvs = []
      recorder = lambda do |args:, timeout: nil, env: nil|
        argvs << args
        # Only the fj transport spawns a subprocess; its env contract is
        # fixed. API exchanges carry no subprocess environment.
        assert_equal({"LC_ALL" => "C"}, env, "runner env must stay fixed; no login or config injection") if args.first == "fj"
        response = if args.first == "forgejo-http"
          fixture = responses["forgejo-api"]
          fixture.respond_to?(:call) ? fixture.call(args) : fixture
        else
          responses[args.join(" ")]
        end
        unless response
          {success: false, stdout: "", stderr: "unexpected command: #{args.join(' ')}", exit_code: 2}
        else
          response
        end
      end
      Struct.new(:argvs, :recorder).new(argvs, recorder)
    end
  end
end
