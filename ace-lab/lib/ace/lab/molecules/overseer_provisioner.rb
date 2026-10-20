# frozen_string_literal: true

require_relative "../errors"
require "open3"

module Ace
  module Lab
    module Molecules
      # Idempotently prepares the project's private overseer folder
      # (ADR-034): the ordinary, gitignored `.ace-tasks/_overseer/`
      # directory plus its `.gitignore` entry. Existing content is never
      # inspected or modified — the folder is private to the overseer that
      # owns it; this provisioner only ensures the folder and the ignore
      # rule exist. Re-running reports ok without rewriting anything.
      #
      # Whether the folder is ACTUALLY ignored is decided by real Git
      # evaluation (`git check-ignore`), never by scanning `.gitignore`
      # lines: a later negation (`!.ace-tasks/_overseer/`) un-ignores an
      # earlier positive line, so line matching would report a private
      # folder as ignored while Git would commit it (LAB-5). When Git
      # reports the folder as not effectively ignored, the effective rule
      # is appended (append-only — the project's own content survives)
      # and the decision is re-evaluated to confirm.
      #
      # The provisioner runs with installer privileges on a freshly
      # cloned repository whose contents are NOT root-trusted: every
      # write is preceded by lstat checks refusing symbolic links under
      # the project root (a committed `.gitignore` or `.ace-tasks`
      # symlink must never redirect a privileged write outside the
      # project — LAB-1).
      class OverseerProvisioner
        OVERSEER_PATH = File.join(".ace-tasks", "_overseer")
        OVERSEER_IGNORE_PATH = ".ace-tasks/_overseer"

        attr_reader :dry_run

        # @param runner [Proc, nil] argv runner seam (git check-ignore)
        def initialize(runner: nil, dry_run: false)
          @runner = runner || method(:run_argv)
          @dry_run = dry_run
        end

        # @param root [String] absolute project root
        # @return [Hash] {dir:, gitignore:, status:, message:} where
        #   status is created / exists / would_create / failed
        def call(root:)
          directory = File.join(root, OVERSEER_PATH)
          gitignore = File.join(root, ".gitignore")

          unsafe = unsafe_symlink_reason(root)
          return failed(unsafe) if unsafe

          # A repo-controlled symlink at the ignore path is refused up
          # front — no privileged read-through either (git check-ignore
          # would follow the link): same trust posture as the LAB-1
          # write refusals.
          gitignore_stat = begin
            File.lstat(gitignore)
          rescue Errno::ENOENT, Errno::ENOTDIR
            nil
          end
          if gitignore_stat&.symlink?
            return failed("'#{gitignore}' is a symbolic link; refusing to follow it with " \
              "installer privileges (remove the link and rerun)")
          end

          # Dry-run prediction for a repository the clone step would
          # create: no work tree exists to evaluate yet — predict the
          # rule the wet run appends.
          ignore = if dry_run && !File.directory?(root)
            {"status" => "ok", "ignored" => false, "message" => nil}
          else
            ignore_decision(root)
          end
          return failed(ignore["message"]) if ignore["status"] == "failed"

          dir_present = File.directory?(directory)
          if dir_present && ignore["ignored"]
            return {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
                    "status" => "exists", "message" => nil}
          end
          return {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
                  "status" => "would_create", "message" => nil} if dry_run

          begin
            require "fileutils"
            FileUtils.mkdir_p(directory) unless dir_present
            append_ignore_entry(gitignore) unless ignore["ignored"]
          rescue SystemCallError => e
            return failed("preparing _overseer failed: #{e.message}")
          end

          unless ignore["ignored"]
            confirmed = ignore_decision(root)
            if confirmed["status"] == "failed"
              return failed(confirmed["message"])
            end
            unless confirmed["ignored"]
              return failed("'#{OVERSEER_IGNORE_PATH}' is still not ignored by Git after " \
                "appending the rule to '#{gitignore}'; fix the project's ignore rules manually")
            end
          end

          {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
           "status" => "created", "message" => nil}
        end

        private

        # A repository-controlled symlink under the project root must
        # never be followed by a privileged read or write: refuse before
        # any mutation. Applies to the `.ace-tasks` component of the
        # private folder path (a symlinked `.gitignore` is refused below
        # before it is read or appended).
        def unsafe_symlink_reason(root)
          %w[.ace-tasks .ace-tasks/_overseer].each do |component|
            path = File.join(root, component)
            stat = File.lstat(path)
            if stat.symlink?
              return "'#{path}' is a symbolic link; refusing to follow it with installer " \
                "privileges (remove the link and rerun)"
            end
          rescue Errno::ENOENT, Errno::ENOTDIR
            nil
          end
          nil
        end

        # Real Git ignore evaluation: ok means ignored, exit 1 means not
        # ignored, anything else (dubious ownership, missing git, not a
        # repository) is a concrete failure — a decision this molecule
        # cannot make must never be guessed.
        def ignore_decision(root)
          result = @runner.call(["git", "-C", root, "check-ignore", "--", OVERSEER_IGNORE_PATH])
          case result["status"]
          when "ok"
            {"status" => "ok", "ignored" => true, "message" => nil}
          when 1, "1" # exit 1: evaluated and NOT ignored
            {"status" => "ok", "ignored" => false, "message" => nil}
          else
            detail = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
            {"status" => "failed", "ignored" => nil,
             "message" => "cannot evaluate Git ignore rules for '#{root}' " \
               "(git check-ignore exited with #{result['status']}#{": #{detail}" if detail})"}
          end
        end

        # Append only — an existing .gitignore is the project's own
        # content and must survive a re-add untouched. A symlinked
        # .gitignore (checked again here, immediately before the open)
        # is refused rather than followed.
        def append_ignore_entry(gitignore)
          stat = begin
            File.lstat(gitignore)
          rescue Errno::ENOENT, Errno::ENOTDIR
            nil
          end
          if stat&.symlink?
            raise SystemCallError.new(
              "'#{gitignore}' is a symbolic link; refusing to follow it with installer privileges", 0)
          end

          entry = "#{OVERSEER_IGNORE_PATH}/"
          if stat && !File.read(gitignore).end_with?("\n")
            File.open(gitignore, "a") { |file| file.write("\n#{entry}\n") }
          else
            File.open(gitignore, "a") { |file| file.write("#{entry}\n") }
          end
        end

        def failed(message)
          {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
           "status" => "failed", "message" => message}
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
