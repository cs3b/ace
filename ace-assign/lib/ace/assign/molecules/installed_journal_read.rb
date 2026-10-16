# frozen_string_literal: true

require "ace/herdr/molecules/bounded_process"
require_relative "evidence_journal"
require_relative "canonical_read_commands"

module Ace
  module Assign
    module Molecules
      # Read the installed owner's immutable Git objects without opening its
      # private writer lock/cache, copying the repository, or contacting it.
      # Source selection is supplied only by verified installation policy.
      class InstalledJournalRead
        include CanonicalReadCommands
        ENVIRONMENT = {"PATH" => "/usr/bin:/bin", "LC_ALL" => "C",
          "GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_SYSTEM" => "/dev/null",
          "GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_TERMINAL_PROMPT" => "0",
          "GIT_ALLOW_PROTOCOL" => "", "GIT_NO_REPLACE_OBJECTS" => "1",
          "GIT_NO_LAZY_FETCH" => "1", "GIT_OPTIONAL_LOCKS" => "0"}.freeze
        ENTRY_LIMIT = 100_000

        def initialize(repo_root:, ref:, owner_uid:)
          unless repo_root.is_a?(String) && repo_root.start_with?("/") &&
              !repo_root.include?("\0") && File.expand_path(repo_root) == repo_root &&
              ref.is_a?(String) && ref.match?(%r{\Arefs/[a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)+\z}) &&
              owner_uid.is_a?(Integer) && owner_uid.positive?
            raise ArgumentError, "installed journal selection is malformed"
          end
          @repo_root, @ref, @owner_uid = repo_root.dup.freeze, ref.dup.freeze, owner_uid
          @mutex = Mutex.new
        end

        def with(deadline:)
          refuse!("read_busy") unless @mutex.try_lock
          begin
            @deadline = deadline
            remaining
            verify_source!
            @view = File.join(@repo_root, ".git")
            @commit = run!(["rev-parse", "--verify", @ref], limit: 128).stdout.strip
            refuse!("ref_unavailable") unless @commit.match?(OID)
            result = yield self
            verify_source!
            result
          ensure
            @view = @commit = @deadline = nil
            @mutex.unlock
          end
        rescue SystemCallError, IOError, Timeout::Error, Herdr::Molecules::BoundedProcess::PostLaunchError
          refuse!("source_unavailable")
        end

        private

        def refuse!(reason)
          raise AttemptErrors::EvidenceUnavailable, "installed journal read unavailable: #{reason}"
        end

        def remaining
          refuse!("deadline") unless @deadline.is_a?(Numeric) && @deadline.finite?
          value = @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          refuse!("deadline") unless value.positive?
          value
        end

        def verify_source!
          # Caller-writable ancestors can replace even a correctly owned leaf.
          current = File.join(@repo_root, ".git")
          loop do
            stat = File.lstat(current)
            unless stat.directory? && !stat.symlink? && [0, @owner_uid].include?(stat.uid) &&
                (stat.mode & 0o022).zero?
              refuse!("storage_owner")
            end
            if [@repo_root, File.join(@repo_root, ".git")].include?(current) && stat.uid != @owner_uid
              refuse!("repository_owner")
            end
            break if current == "/"
            current = File.dirname(current)
          end
          %w[commondir shallow reftable info/grafts objects/info/alternates objects/info/http-alternates].each do |name|
            path = File.join(@repo_root, ".git", name)
            refuse!("redirected_storage") if File.exist?(path) || File.symlink?(path)
          end
          @entries = 0
          %w[objects refs config HEAD packed-refs].each do |name|
            path = File.join(@repo_root, ".git", name)
            next if %w[HEAD packed-refs].include?(name) && !File.exist?(path) && !File.symlink?(path)
            verify_tree!(path)
          end
          verify_config!
        end

        def verify_tree!(path)
          remaining
          @entries += 1
          refuse!("storage_inventory_limit") if @entries > ENTRY_LIMIT
          stat = File.lstat(path)
          unless !stat.symlink? && (stat.file? || stat.directory?) &&
              [0, @owner_uid].include?(stat.uid) && (stat.mode & 0o022).zero?
            refuse!("storage_owner")
          end
          Dir.each_child(path) { |name| verify_tree!(File.join(path, name)) } if stat.directory?
        end

        def verify_config!
          bytes = File.open(File.join(@repo_root, ".git/config"), File::RDONLY | File::NOFOLLOW) { |io| io.read(65_537) }
          refuse!("config_limit") if bytes.bytesize > 65_536
          result = Herdr::Molecules::BoundedProcess.call(
            ["/usr/bin/git", "config", "--no-includes", "--null", "--list", "--file", "/dev/stdin"],
            environment: ENVIRONMENT, chdir: "/", stdin_data: bytes,
            timeout_s: remaining, output_limit: 65_536)
          refuse!("config_unavailable") unless result.status.success? && !result.oversized
          result.stdout.split("\0").each do |entry|
            key, value = entry.split("\n", 2)
            if key.start_with?("include.", "includeif.", "extensions.") || key == "core.worktree" ||
                key == "core.repositoryformatversion" && value != "0"
              refuse!("redirected_configuration")
            end
          end
        end

        def read_result(argv, **options)
          run!(argv, **options, allow_failure: true)
        end

        def run!(argv, stdin_data: "", limit:, allow_failure: false)
          # All ref-based reads in one observation use the same immutable tip.
          selected = argv.map { |arg| arg == @ref && @commit ? @commit : arg }
          result = Herdr::Molecules::BoundedProcess.call([
            "/usr/bin/git", "--git-dir=#{@view}", "--no-pager",
            "-c", "safe.directory=#{@repo_root}", "-c", "core.hooksPath=/dev/null",
            "-c", "core.fsmonitor=false", "-c", "protocol.allow=never", *selected],
            environment: ENVIRONMENT, chdir: @repo_root, stdin_data: stdin_data,
            timeout_s: remaining, output_limit: [limit, BYTE_LIMIT].min, stderr_limit: 65_536)
          refuse!("resource_limit") if result.oversized
          refuse!("git_unavailable") unless allow_failure || result.status.success?
          result
        end
      end
    end
  end
end
