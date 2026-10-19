# frozen_string_literal: true

require_relative "../errors"
require "open3"

module Ace
  module Lab
    module Molecules
      # Idempotently ensures a Git repository exists at the project path
      # with the declared origin remote (task 8xg.t.sbz.7.1). A missing or
      # empty target is cloned from the remote; an existing repository is
      # verified against the declared remote — a different origin is a
      # contradictory registration that is refused, never overwritten.
      # All Git access goes through argv arrays (ADR-031); failures
      # surface the exit status and the first stderr line only.
      class RepositoryProvisioner
        attr_reader :runner, :dry_run

        def initialize(runner: nil, dry_run: false)
          @runner = runner || method(:run_argv)
          @dry_run = dry_run
        end

        # @param path [String] absolute target directory
        # @param remote [String, nil] declared origin remote URL
        # @return [Hash] {path:, remote:, status:, message:} where status
        #   is created / exists / would_create / failed
        def call(path:, remote:)
          if repository?(path)
            converge_existing(path, remote)
          elsif foreign_directory?(path)
            failure(path, remote,
              "'#{path}' exists and is not an empty directory or a Git repository; " \
              "refusing to take over a foreign location")
          elsif remote.nil?
            failure(path, remote,
              "'#{path}' has no repository and no --remote was given; " \
              "nothing to prepare the project from")
          elsif dry_run
            {"path" => path, "remote" => remote, "status" => "would_create", "message" => nil}
          else
            clone(path, remote)
          end
        end

        private

        def converge_existing(path, remote)
          origin = origin_url(path)
          return {"path" => path, "remote" => origin || remote, "status" => "exists", "message" => nil} if remote.nil?
          return {"path" => path, "remote" => origin, "status" => "exists", "message" => nil} if origin == remote

          if origin
            failure(path, remote,
              "'#{path}' is a Git repository with origin '#{origin}' but the request " \
              "declares '#{remote}'; refusing to overwrite an existing registration")
          elsif dry_run
            {"path" => path, "remote" => remote, "status" => "would_create",
             "message" => "would set origin to '#{remote}'"}
          else
            result = runner.call(["git", "-C", path, "remote", "add", "origin", remote])
            return failure(path, remote, "setting origin on '#{path}' failed: #{git_error(result)}") unless success?(result)

            {"path" => path, "remote" => remote, "status" => "created", "message" => nil}
          end
        end

        def clone(path, remote)
          result = runner.call(["git", "clone", remote, path])
          return failure(path, remote, "cloning '#{remote}' into '#{path}' failed: #{git_error(result)}") unless success?(result)

          {"path" => path, "remote" => remote, "status" => "created", "message" => nil}
        end

        # Read-only probes: safe in dry-run (the prediction contract from
        # ace-lab prepare applies — predictions use read-only filesystem
        # and Git queries, effects are suppressed).
        def repository?(path)
          return false unless File.directory?(path)

          result = runner.call(["git", "-C", path, "rev-parse", "--is-inside-work-tree"])
          success?(result) && result["out"].to_s.strip == "true"
        end

        def foreign_directory?(path)
          File.exist?(path) && !(File.directory?(path) && Dir.children(path).empty?)
        end

        def origin_url(path)
          result = runner.call(["git", "-C", path, "remote", "get-url", "origin"])
          success?(result) ? result["out"].to_s.strip : nil
        end

        def success?(result)
          result["status"] == "ok"
        end

        def git_error(result)
          first_line = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
          detail = first_line ? " #{first_line}" : ""
          "git exited with status #{result['status']}#{detail}"
        end

        def failure(path, remote, message)
          {"path" => path, "remote" => remote, "status" => "failed", "message" => message}
        end

        def run_argv(argv)
          out, err, status = Open3.capture3(*argv)
          {"status" => status.success? ? "ok" : (status.exitstatus || "signal #{status.termsig}"),
           "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError => e
          {"status" => "exec_failed", "out" => "", "err" => e.class.name}
        end
      end
    end
  end
end
