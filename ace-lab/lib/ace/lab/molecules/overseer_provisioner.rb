# frozen_string_literal: true

require_relative "../errors"

module Ace
  module Lab
    module Molecules
      # Idempotently prepares the project's private overseer folder
      # (ADR-034): the ordinary, gitignored `.ace-tasks/_overseer/`
      # directory plus its `.gitignore` entry. Existing content is never
      # inspected or modified — the folder is private to the overseer that
      # owns it; this provisioner only ensures the folder and the ignore
      # line exist. Re-running reports ok without rewriting anything.
      class OverseerProvisioner
        OVERSEER_PATH = File.join(".ace-tasks", "_overseer")
        IGNORE_PATTERN = %r{\A/?\.ace-tasks/_overseer/?\z}

        attr_reader :dry_run

        def initialize(dry_run: false)
          @dry_run = dry_run
        end

        # @param root [String] absolute project root
        # @return [Hash] {dir:, gitignore:, status:, message:} where
        #   status is created / exists / would_create / failed
        def call(root:)
          directory = File.join(root, OVERSEER_PATH)
          gitignore = File.join(root, ".gitignore")
          dir_present = File.directory?(directory)
          ignore_present = ignore_entry?(gitignore)

          if dir_present && ignore_present
            return {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
                    "status" => "exists", "message" => nil}
          end
          return {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
                  "status" => "would_create", "message" => nil} if dry_run

          begin
            require "fileutils"
            FileUtils.mkdir_p(directory) unless dir_present
            append_ignore_entry(gitignore) unless ignore_present
          rescue SystemCallError => e
            return {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
                    "status" => "failed", "message" => "preparing _overseer failed: #{e.message}"}
          end

          {"dir" => OVERSEER_PATH, "gitignore" => ".gitignore",
           "status" => "created", "message" => nil}
        end

        private

        def ignore_entry?(gitignore)
          return false unless File.file?(gitignore)

          File.foreach(gitignore).any? { |line| IGNORE_PATTERN.match?(line.strip) }
        end

        # Append only — an existing .gitignore is the project's own
        # content and must survive a re-add untouched.
        def append_ignore_entry(gitignore)
          entry = "#{OVERSEER_PATH}/"
          if File.exist?(gitignore) && !File.read(gitignore).end_with?("\n")
            File.open(gitignore, "a") { |file| file.write("\n#{entry}\n") }
          else
            File.open(gitignore, "a") { |file| file.write("#{entry}\n") }
          end
        end
      end
    end
  end
end
