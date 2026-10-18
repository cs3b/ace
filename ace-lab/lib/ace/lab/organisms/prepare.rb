# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/install_manifest_loader"
require_relative "../molecules/account_provisioner"
require_relative "../molecules/directory_provisioner"
require_relative "../molecules/key_provisioner"
require_relative "../molecules/role_verifier"

module Ace
  module Lab
    module Organisms
      # Orchestrates the preparation phase (L8.1) from the trusted install
      # manifest: accounts → directories → keys → roles, in that fixed
      # order, each through its idempotent provisioner molecule. The
      # aggregated report is the contract consumed by `ace-lab project add`
      # (7.1) and `ace-lab install` (7.2); `ok` means zero failed items.
      # Key and role items whose account failed are reported as dependency
      # failures instead of being attempted. No state is written beyond
      # what the manifest declares — this organism owns no journal.
      class Prepare
        attr_reader :manifest_path, :dry_run, :platform

        def initialize(manifest_path: nil, runner: nil, account_lookup: nil, privileged: nil,
          platform: nil, dry_run: false)
          @manifest_path = manifest_path || Ace::Lab.install_manifest_path
          @runner = runner
          @account_lookup = account_lookup
          @privileged = privileged
          @platform = platform
          @dry_run = dry_run
        end

        # @param dry_run [Boolean, nil] per-call override of the
        #   constructor default (the CLI passes its --dry-run here)
        # @return [Hash] aggregated report (ok / dry_run / machine /
        #   manifest / accounts / directories / keys / roles)
        # @raise [Ace::Lab::InvalidConfigurationError] missing, untrusted,
        #   unparseable or schema-invalid manifest
        def call(dry_run: nil)
          @effective_dry_run = dry_run.nil? ? self.dry_run : dry_run
          manifest = Molecules::InstallManifestLoader.load(path: manifest_path, platform: platform)
          accounts = prepare_accounts(manifest["accounts"])
          available = available_accounts(accounts)
          directories = prepare_directories(manifest["directories"])
          keys = prepare_keys(manifest["keys"], manifest["machine"], manifest["accounts"], available)
          roles = prepare_roles(manifest["roles"], available)

          {
            "ok" => [accounts, directories, keys, roles].flatten.none? { |item| item["status"] == "failed" },
            "dry_run" => @effective_dry_run,
            "machine" => manifest["machine"],
            "manifest" => manifest_path,
            "accounts" => accounts,
            "directories" => directories,
            "keys" => keys,
            "roles" => roles
          }
        end

        private

        def account_provisioner
          Molecules::AccountProvisioner.new(
            runner: @runner, account_lookup: @account_lookup, privileged: @privileged,
            platform: @platform, dry_run: @effective_dry_run
          )
        end

        def prepare_accounts(entries)
          provisioner = account_provisioner
          entries.map { |account| provisioner.call(account: account) }
        end

        def prepare_directories(entries)
          provisioner = Molecules::DirectoryProvisioner.new(account_lookup: @account_lookup, dry_run: @effective_dry_run)
          entries.map { |directory| provisioner.call(directory: directory) }
        end

        def prepare_keys(entries, machine, manifest_accounts, available)
          provisioner = Molecules::KeyProvisioner.new(
            runner: @runner, account_lookup: @account_lookup, dry_run: @effective_dry_run
          )
          by_username = manifest_accounts.to_h { |account| [account["username"], account] }
          entries.map do |key|
            account = by_username.fetch(key["account"])
            if available.include?(account["username"])
              provisioner.call(key: key, account: account, machine: machine)
            else
              {"account" => account["username"], "path" => key["path"], "status" => "failed",
               "fingerprint" => nil,
               "message" => "account '#{account['username']}' is not available; fix the account phase first"}
            end
          end
        end

        def prepare_roles(entries, available)
          provisioner = Molecules::RoleVerifier.new(account_lookup: @account_lookup)
          entries.map do |role|
            if available.include?(role["account"])
              provisioner.call(role: role)
            else
              {"id" => role["id"], "account" => role["account"], "instructions" => role["instructions"],
               "status" => "failed",
               "message" => "account '#{role['account']}' is not available; fix the account phase first"}
            end
          end
        end

        def available_accounts(account_reports)
          account_reports.reject { |report| report["status"] == "failed" }
            .map { |report| report["username"] }
        end
      end
    end
  end
end
