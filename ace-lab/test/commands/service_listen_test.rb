# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    # The serve entrypoint registration and its mode/selection refusals
    # (spec 8x3.t.xz9.4 serve entrypoint). The full listener lifecycle is
    # covered by OrdinaryListenEndToEndTest and the molecule tests.
    class ServiceListenCommandTest < Minitest::Test
      def test_listen_is_a_registered_service_command
        assert Ace::Lab::CLI::REGISTERED_COMMANDS.any? { |name, _| name == "service listen" }
        assert CLI::Commands::Service.const_defined?(:Listen)
      end

      def test_unknown_mode_refuses_before_any_configuration_load
        command = CLI::Commands::Service::Listen.new
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            command.call(mode: "teleport", project: "atlas", config: "/nonexistent.yml")
          end
        end
        assert_includes error.message, "ordinary_merge_invalid_request"
      end

      def test_unreadable_configuration_is_the_unavailable_blocker
        command = CLI::Commands::Service::Listen.new
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            command.call(mode: "ordinary-merge", project: "atlas",
              config: "/nonexistent/receiver.yml")
          end
        end
        assert_includes error.message, "ordinary_merge_unavailable"
      end

      def test_project_mismatch_refuses_as_selection_mismatch
        dir = Dir.mktmpdir("listen-cli")
        config = File.join(dir, "receiver.yml")
        File.write(config, YAML.safe_dump(
          "project" => "borealis", "receiver_id" => "ordinary-receiver",
          "socket_path" => "/tmp/x.sock", "receiver_uid" => Process.uid,
          "principal" => "overseer", "principal_uid" => Process.uid,
          "repo_path" => dir, "policy_path" => "/etc/lab/ace-lab/authorization.yml",
          "execution_identity" => {"checkout_id" => "c", "worktree_id" => "w",
                                   "branch" => "main"}
        ))
        command = CLI::Commands::Service::Listen.new
        error = assert_raises(Ace::Support::Cli::Error) do
          capture_io do
            with_trusted_config(config) { command.call(mode: "ordinary-merge", project: "atlas", config: config) }
          end
        end
        assert_includes error.message, "ordinary_merge_selection_mismatch"
      ensure
        FileUtils.rm_rf(dir)
      end

      # ---- startup regression (spec 8x3.t.xz9.5 integration handoff) -----

      # The CLI delegates lifecycle ownership to the installed composition.
      # Constructor and real transport joins have their separate tests.
      def test_startup_reaches_the_installed_composition_server
        dir = Dir.mktmpdir("listen-startup")
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p(repo)
        git_init_with_commit(repo)
        config = File.join(dir, "receiver.yml")
        File.write(config, YAML.safe_dump(
          "project" => "atlas", "receiver_id" => "ordinary-receiver",
          "socket_path" => File.join(dir, "blocked", "ordinary.sock"),
          "receiver_uid" => Process.uid, "principal" => "overseer",
          "principal_uid" => Process.uid, "repo_path" => repo,
          "policy_path" => File.join(dir, "authorization.yml"),
          "execution_identity" => {"checkout_id" => "c", "worktree_id" => "w",
                                   "branch" => "main"}
        ))
        File.write(File.join(dir, "blocked"), "regular file, not a directory")
        command = CLI::Commands::Service::Listen.new
        server = Object.new
        server.define_singleton_method(:serve) { raise Errno::ENOTDIR }
        server.define_singleton_method(:request_stop) { nil }
        composition = Object.new
        composition.define_singleton_method(:build) { server }
        factory = lambda do |receiver_config:|
          assert_instance_of Molecules::OrdinaryReceiverConfig, receiver_config
          assert_equal config, receiver_config.source
          composition
        end
        Organisms::OrdinaryAuthorityComposition.stub(:new, factory) do
          assert_raises(Errno::ENOTDIR) do
            capture_io { with_trusted_config(config) { command.call(mode: "ordinary-merge", project: "atlas", config: config) } }
          end
        end
      ensure
        FileUtils.rm_rf(dir)
      end

      # A receiver cannot start a private daemon-cwd coordinator when the
      # shared assignment owner has not been installed.
      def test_missing_owner_configuration_refuses_without_local_fallback
        dir = Dir.mktmpdir("listen-startup")
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p(repo)
        git_init_with_commit(repo)
        config = File.join(dir, "receiver.yml")
        File.write(config, YAML.safe_dump(
          "project" => "atlas", "receiver_id" => "ordinary-receiver",
          "socket_path" => File.join(dir, "ordinary.sock"),
          "receiver_uid" => Process.uid, "principal" => "overseer",
          "principal_uid" => Process.uid, "repo_path" => repo,
          "policy_path" => File.join(dir, "authorization.yml"),
          "execution_identity" => {"checkout_id" => "c", "worktree_id" => "w",
                                   "branch" => "main"}
        ))
        command = CLI::Commands::Service::Listen.new
        loader = lambda do |project:|
          assert_equal "atlas", project
          raise InvalidConfigurationError, "ordinary assignment owner configuration is unavailable: #{Molecules::OrdinaryOwnerConfig::PATH}"
        end
        Molecules::OrdinaryOwnerConfig.stub(:load, loader) do
          error = assert_raises(Ace::Support::Cli::Error) do
            capture_io { with_trusted_config(config) { command.call(mode: "ordinary-merge", project: "atlas", config: config) } }
          end
          assert_includes error.message, Molecules::OrdinaryOwnerConfig::PATH
          refute File.exist?(File.join(repo, ".git", "refs", "ace", "execution"))
        end
      ensure
        FileUtils.rm_rf(dir)
      end

      # The REAL CLI executable (subprocess): startup with a temp
      # configuration reaches the closed refusal vocabulary — here the
      # trusted-policy blocker — and NEVER dies with the missing-coordinator
      # ArgumentError.
      def test_real_cli_startup_emits_closed_refusal_never_argument_error
        dir = Dir.mktmpdir("listen-cli-subprocess")
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p(repo)
        config = File.join(dir, "receiver.yml")
        File.write(config, YAML.safe_dump(
          "project" => "atlas", "receiver_id" => "ordinary-receiver",
          "socket_path" => File.join(dir, "ordinary.sock"),
          "receiver_uid" => Process.uid, "principal" => "overseer",
          "principal_uid" => Process.uid, "repo_path" => repo,
          "policy_path" => File.join(dir, "authorization.yml"),
          "execution_identity" => {"checkout_id" => "c", "worktree_id" => "w",
                                   "branch" => "main"}
        ))
        exe = File.expand_path("../../exe/ace-lab", __dir__)
        out, err, status = Open3.capture3("bundle", "exec", "ruby", "-I",
          File.expand_path("../../lib", __dir__), exe,
          "service", "listen", "--mode", "ordinary-merge", "--project", "atlas",
          "--config", config)
        refute_predicate status, :success?
        combined = out + err
        assert_includes combined, "ordinary_merge_unavailable"
        refute_includes combined, "ArgumentError"
        refute_includes combined, "missing keyword"
      ensure
        FileUtils.rm_rf(dir)
      end

      private

      def with_trusted_config(path)
        original = Molecules::GrantResolver.method(:read_verified)
        Molecules::GrantResolver.stub(:read_verified, ->(selected) {
          selected == path ? File.read(path) : original.call(selected)
        }) { yield }
      end

      def git_init_with_commit(repo)
        Open3.capture3("git", "init", "-b", "main", chdir: repo)
        Open3.capture3("git", "config", "user.name", "test", chdir: repo)
        Open3.capture3("git", "config", "user.email", "test@example.com", chdir: repo)
        File.write(File.join(repo, "base.txt"), "base\n")
        Open3.capture3("git", "add", "base.txt", chdir: repo)
        captured = Open3.capture3("git", "commit", "-m", "base", chdir: repo)
        raise "fixture commit failed: #{captured[1]}" unless captured.last.success?
      end

      def complete_policy_document
        {"operations" => {}, "authorizations" => {}, "ordinary" =>
          {"projects" => {"atlas" => {"receiver_id" => "ordinary-receiver"}}}}
      end

      def forge_config
        Molecules::ForgeMergeConfig.new({
          "base_url" => "https://forge.example.com", "owner" => "acme", "repo" => "widget",
          "token" => "test-scoped-token", "merge_timeout_seconds" => 30,
          "escalation_owner" => "host-integrator",
          "review_attachment" => {"enabled" => true}
        })
      end
    end
  end
end
