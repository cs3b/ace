# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "test_helper"

module Forgejo
  # Selected-repository binding matrix: every provider subprocess carries the
  # selected host/owner/repository; two servers sharing PR/issue numbers with
  # conflicting cwd, remote order, and default login cannot cross-route; all
  # pre-send failures classify with zero wrongly targeted subprocesses.
  class RepositoryBindingTest < AceGitForgejoTestCase
    LAB_A = Ace::Git::ResolvedServer.new(name: "lab-a", provider: :forgejo, url: "https://forge.example.com/lab-a/repo")
    LAB_B = Ace::Git::ResolvedServer.new(name: "lab-b", provider: :forgejo, url: "https://other.example.com:3443/lab-b/repo")
    SHA = "a" * 40

    def test_every_subprocess_of_selected_server_carries_its_identity
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
        assert_equal "fj", argv.first
        next if argv == %w[fj version] # control probe, host-scoped only

        assert_equal ["-H", "https://other.example.com:3443"], argv[1, 2],
          "every subprocess must carry the selected authority"
        assert_nil argv.index("-C"), "cwd must never be used for targeting"
        assert_includes argv.join(" "), "lab-b/repo",
          "every subprocess must reference the selected repository"
      end
      pr_view = commands.argvs.find { |argv| argv.include?("pr") && argv.include?("view") && argv.last.end_with?("#7") }
      assert_equal "lab-b/repo#7", pr_view.last, "PR reads must use the qualified selected-repository reference"
    end

    def test_same_numbers_on_two_servers_never_cross_route
      commands = recording_runner(lab_b_fixtures.merge(lab_a_fixtures))
      lab_a = Ace::Git::Forgejo::Provider.new(server: LAB_A, runner: commands.recorder)
      lab_b = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)

      pr_a = lab_a.pull_request(number: 7)
      pr_b = lab_b.pull_request(number: 7)

      assert_equal "https://forge.example.com/lab-a/repo/pulls/7", pr_a.url
      assert_equal "https://other.example.com:3443/lab-b/repo/pulls/7", pr_b.url
      views = commands.argvs.select { |argv| argv.include?("pr") && argv.include?("view") && argv.last.end_with?("#7") }
      assert_equal 2, views.length
      assert_equal ["-H", "https://forge.example.com", "--style", "minimal", "pr", "view", "lab-a/repo#7"], views[0][1..]
      assert_equal ["-H", "https://other.example.com:3443", "--style", "minimal", "pr", "view", "lab-b/repo#7"], views[1][1..]
    end

    def test_unobserved_cli_version_refuses_all_operations_with_zero_mutation_subprocesses
      # Usage scenario 2: a CLI that cannot target the selected repository.
      commands = recording_runner(
        "fj version" => {success: true, stdout: "fj v0.9.9\n", stderr: "", exit_code: 0}
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)

      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.pull_request(number: 7) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.pull_request_for_branch(branch: "feature") }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.pull_request_diff(number: 7) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.recent_pull_requests(limit: 5) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.issue(number: 7) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.checks(ref: SHA) }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { provider.repository }
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        provider.update_pull_request(number: 7, expected_head: SHA, title: "Reviewed")
      end

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

      assert_empty commands.argvs, "malformed selection must fail before any subprocess launch"
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
          "only control probes may run; no repository or mutation subprocess"
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
        "fj version" => {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0},
        "fj -H https://forge.example.com --style minimal pr view lab-a/repo#7" => {
          success: true, stdout: view(99, "Open", "feature"), stderr: "", exit_code: 0
        }
      )
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_A, runner: commands.recorder)
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) { provider.pull_request(number: 7) }
      assert_match(/#99/, error.message)
      assert_match(/selected pull request #7/, error.message)

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
      searches = 0
      runner = lambda do |args:, timeout: nil, env: nil|
        argvs << args
        key = args.join(" ")
        case key
        when "fj version"
          {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0}
        when "fj -H https://other.example.com:3443 --style minimal pr search --state open -r lab-b/repo"
          searches += 1
          if searches == 1
            {success: true, stdout: "0 pull requests\n", stderr: "", exit_code: 0}
          else
            {success: true, stdout: "1 pull requests\n#7: Ship it (by lab-builder)\n", stderr: "", exit_code: 0}
          end
        when "fj -H https://other.example.com:3443 pr create Ship it --head feature --base main -r lab-b/repo"
          {success: true, stdout: "", stderr: "", exit_code: 0}
        when "fj -H https://other.example.com:3443 --style minimal pr view lab-b/repo#7"
          {success: true, stdout: view(7, "Open", "feature"), stderr: "", exit_code: 0}
        when "fj -H https://other.example.com:3443 --style minimal pr view lab-b/repo#7 commits"
          {success: true, stdout: "commit #{SHA} (+1, -0)\n", stderr: "", exit_code: 0}
        else
          flunk("Unexpected command in test: #{key}")
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
        next if argv == %w[fj version] # control probe

        assert_equal "https://other.example.com:3443", argv[2], "every subprocess targets the selected authority"
      end
      assert_equal 1, argvs.count { |argv| argv.include?("create") }, "exactly one create, no automatic retry"
      assert_equal 2, argvs.count { |argv| argv.join(" ").include?("pr search") },
        "create pre-check and reconciliation each search the selected repository"
    end

    def test_refusals_classify_before_any_subprocess
      commands = recording_runner
      provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)

      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        provider.create_pull_request(
          head_repository_url: "https://other.example.com:3443/forker/repo", head_ref: "feature",
          base_ref: "main", expected_head: SHA, title: "Ship it"
        )
      end
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        provider.ready_pull_request(number: 7, expected_head: SHA)
      end
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        provider.merge_pull_request(number: 7, expected_head: SHA, method: :squash)
      end
      assert_raises(Ace::Git::ConfigError) { provider.pull_request_diff(number: "abc") }
      assert_raises(Ace::Git::ConfigError) { provider.update_pull_request(number: "", expected_head: SHA, title: "t") }

      assert_empty commands.argvs, "refusals must classify before any repository subprocess"
    end

    def test_conflicting_fj_alias_refuses_repository_operations
      keys_path = File.join(Dir.tmpdir, "uj0-alias-test-#{Process.pid}-conflict.json")
      File.write(keys_path, {
        "hosts" => {}, "aliases" => {"other.example.com:3443" => "evil.example.test"}, "default_ssh" => []
      }.to_json)
      stub_keys_path(keys_path) do
        commands = recording_runner(
          "fj version" => {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0}
        )
        provider = Ace::Git::Forgejo::Provider.new(server: LAB_B, runner: commands.recorder)
        error = assert_raises(Ace::Git::ConfigError) { provider.pull_request(number: 7) }
        assert_match(/redirects selected host other\.example\.com:3443/, error.message)
        assert_match(/evil\.example\.test/, error.message)
        assert_equal [["fj", "version"]], commands.argvs.uniq,
          "alias conflict refuses before any repository subprocess"
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
        pr = provider.pull_request(number: 7)
        assert_equal 7, pr.number
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

    def lab_a_fixtures
      prefix = "fj -H https://forge.example.com --style minimal"
      {
        "#{prefix} pr view lab-a/repo#7" => {success: true, stdout: view(7, "Open", "feature"), stderr: "", exit_code: 0},
        "#{prefix} pr view lab-a/repo#7 commits" => {success: true, stdout: "commit #{SHA} (+1, -0)\n", stderr: "", exit_code: 0}
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
        }
      }
    end

    def recording_runner(responses = {})
      argvs = []
      recorder = lambda do |args:, timeout: nil, env: nil|
        argvs << args
        assert_equal({"LC_ALL" => "C"}, env, "runner env must stay fixed; no login or config injection")
        response = responses[args.join(" ")]
        if response
          response
        else
          {success: false, stdout: "", stderr: "unexpected command: #{args.join(' ')}", exit_code: 2}
        end
      end
      Struct.new(:argvs, :recorder).new(argvs, recorder)
    end
  end
end
