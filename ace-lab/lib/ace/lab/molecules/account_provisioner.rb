# frozen_string_literal: true

require_relative "../errors"
require "open3"
require "etc"
require "securerandom"

module Ace
  module Lab
    module Molecules
      # Idempotently ensures a lab account exists, per the trusted install
      # manifest. Existing accounts are reported with their uid; missing
      # accounts either fail with an actionable message (create: false, or
      # creation without administrator privileges) or are created through
      # the platform's own account tooling (darwin dscl / linux useradd),
      # always with argv arrays (ADR-031) — never a shell string. Every
      # failure message names the account and the remedy; command failures
      # surface only the exit status and the first stderr line, never file
      # content.
      class AccountProvisioner
        DEFAULT_SHELL = "/bin/zsh"
        DARWIN_PRIMARY_GROUP = 20

        attr_reader :runner, :account_lookup, :privileged, :platform, :dry_run

        def initialize(runner: nil, account_lookup: nil, privileged: nil, platform: nil, dry_run: false)
          @runner = runner || method(:run_argv)
          @account_lookup = account_lookup || method(:lookup_passwd)
          @privileged = privileged || -> { Process.euid.zero? }
          @platform = platform || Ace::Lab.host_platform
          @dry_run = dry_run
        end

        # @param account [Hash] normalized manifest account entry
        # @return [Hash] {username:, status:, uid:, message:}
        def call(account:)
          username = account["username"]
          existing = account_lookup.call(username)
          if existing
            return {"username" => username, "status" => "exists", "uid" => existing.uid,
              "message" => nil} if existing.dir == account["home"]

            # Drift is reported, not repaired: the manifest home stays
            # authoritative (key default paths derive from it).
            {"username" => username, "status" => "exists", "uid" => existing.uid,
             "message" => "account '#{username}' home is '#{existing.dir}' but the manifest " \
              "declares '#{account["home"]}'; the manifest home is authoritative for key paths"}
          else

            unless account["create"]
              return failure(username,
                "account '#{username}' does not exist; create it manually (administrator action) " \
                "or set create: true in the install manifest")
            end

            unless privileged.call
              return failure(username,
                "creating account '#{username}' requires administrator privileges; rerun ace-lab prepare " \
                "with sudo or create the account manually")
            end

            # Platform support is classified BEFORE the dry-run
            # prediction: --dry-run must predict the wet failure on an
            # unsupported platform, not would_create.
            creation = case platform
                       when "darwin" then :create_darwin
                       when "linux" then :create_linux
                       end
            if creation.nil?
              return failure(username,
                "unsupported platform '#{platform}' for account creation; create account '#{username}' " \
                "manually and set create: false in the install manifest")
            end

            if dry_run
              return {"username" => username, "status" => "would_create", "uid" => nil, "message" => nil}
            end

            send(creation, account)
          end
        end

        private

        def failure(username, message)
          {"username" => username, "status" => "failed", "uid" => nil, "message" => message}
        end

        def created(username, uid)
          {"username" => username, "status" => "created", "uid" => uid, "message" => nil}
        end

        def create_darwin(account)
          username = account["username"]
          listing = invoke(["dscl", ".", "-list", "/Users", "UniqueID"])
          return failure(username, listing["message"]) unless listing["ok"]

          uid = next_darwin_uid(listing["out"])
          steps = [
            ["dscl", ".", "-create", "/Users/#{username}", "RealName", username],
            ["dscl", ".", "-create", "/Users/#{username}", "UniqueID", uid.to_s],
            ["dscl", ".", "-create", "/Users/#{username}", "PrimaryGroupID", DARWIN_PRIMARY_GROUP.to_s],
            ["dscl", ".", "-create", "/Users/#{username}", "UserShell", DEFAULT_SHELL],
            ["dscl", ".", "-create", "/Users/#{username}", "NFSHomeDirectory", account["home"]],
            ["dscl", ".", "-create", "/Users/#{username}", "GeneratedUID", SecureRandom.uuid],
            ["dscl", ".", "-create", "/Users/#{username}", "Password", "*"],
            ["createhomedir", "-c", "-u", username]
          ]
          steps.each do |argv|
            result = invoke(argv)
            return failure(username, result["message"]) unless result["ok"]
          end

          created(username, uid)
        end

        # Allocate the next free UniqueID above the current maximum,
        # ignoring the reserved high sentinel values (darwin's `nobody`
        # reports 4294967294). Parse only the trailing UniqueID column
        # of each `dscl -list` line — digits inside account names such
        # as `deploy-2026` must never be taken for a UID. Deliberately
        # simple: dscl owns the directory; concurrent creation is
        # reconciled by the idempotent re-run.
        def next_darwin_uid(out)
          ids = out.lines.filter_map { |line| line[/\s(\d+)\s*\z/, 1] }
            .map(&:to_i).reject { |id| id >= 2**31 }
          return 501 if ids.empty?

          [ids.max + 1, 501].max
        end

        def create_linux(account)
          username = account["username"]
          result = invoke([
            "useradd", "-m", "-s", DEFAULT_SHELL, "-d", account["home"], username
          ])
          return failure(username, result["message"]) unless result["ok"]

          entry = account_lookup.call(username)
          if entry
            created(username, entry.uid)
          else
            {"username" => username, "status" => "created", "uid" => nil,
             "message" => "account '#{username}' was created but its uid could not be " \
               "resolved yet; rerun ace-lab prepare to report it"}
          end
        end

        # @return [Hash] {ok:, out:, message:} — failure message carries
        #   the exit status and the first stderr line only, never command
        #   output bodies or file content.
        def invoke(argv)
          result = runner.call(argv)
          if result["status"] == "ok"
            {"ok" => true, "out" => result["out"], "message" => nil}
          elsif result["status"] == "enoent"
            {"ok" => false, "out" => result["out"],
             "message" => "#{argv.first} not found in PATH; install it and rerun ace-lab prepare"}
          elsif result["status"] == "exec_failed"
            # Exec-level SystemCallError, not a subprocess exit status —
            # render the errno class so the message never says "exit failed".
            {"ok" => false, "out" => result["out"],
             "message" => "command could not be executed (#{argv.first}, #{result['err']})"}
          else
            first_line = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
            # Round 5 (C2): a signal-killed child has no exitstatus —
            # the runner renders "signal <termsig>" instead of nil.
            message = "command failed (#{argv.first}, #{exit_detail(result['status'])})"
            message += ": #{first_line}" if first_line
            {"ok" => false, "out" => result["out"], "message" => message}
          end
        end

        def exit_detail(status)
          status.is_a?(Integer) ? "exit #{status}" : status.to_s
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

        def lookup_passwd(username)
          Etc.getpwnam(username)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
