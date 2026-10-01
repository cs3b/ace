# frozen_string_literal: true

require "fileutils"
require "json"
require "tempfile"
require_relative "../atoms/campaign_contract"

module Ace
  module Review
    module Molecules
      # One lock protects campaign identity allocation and append-only history.
      # Records are checksummed and replaced atomically, including partial work.
      class CampaignStore
        attr_reader :root

        def initialize(root:)
          @root = File.expand_path(root)
        end

        def transaction(dry_run: false)
          if dry_run
            # No directory or lock-file creation in dry-run mode.
            return yield unless File.directory?(root)
            lock_path = File.join(root, ".lock")
            return yield unless File.file?(lock_path)
            return File.open(lock_path, File::RDONLY) { |lock| lock.flock(File::LOCK_SH); yield }
          end
          FileUtils.mkdir_p(root)
          File.open(File.join(root, ".lock"), File::RDWR | File::CREAT, 0o600) do |lock|
            lock.flock(File::LOCK_EX)
            yield
          end
        end

        def path(id)
          Atoms::CampaignContract.id!(id, "campaign ID")
          File.join(root, "#{id}.json")
        end

        def read(id)
          envelope = JSON.parse(File.read(path(id)))
          record = envelope.fetch("record")
          unless record.is_a?(Hash) && record["id"] == id &&
              envelope["sha256"] == Atoms::CampaignContract.digest(record)
            raise Atoms::CampaignContract::Invalid, "corrupt campaign #{id}: identity or checksum mismatch"
          end
          %w[subject contract_identity contract policy inherited_findings assessments attempts rounds head_transitions].each do |key|
            raise Atoms::CampaignContract::Invalid, "corrupt campaign #{id}: missing #{key}" unless record.key?(key)
          end
          contract = Atoms::CampaignContract
          contract.subject!(record["subject"])
          contract.string!(record["contract"], "stored requirements")
          unless Digest::SHA256.hexdigest(record["contract"]) == record["contract_identity"]
            raise contract::Invalid, "corrupt campaign #{id}: requirements digest mismatch"
          end
          contract.policy!(record["policy"])
          %w[inherited_findings assessments attempts rounds head_transitions].each do |key|
            unless record[key].is_a?(Array) && record[key].all? { |entry| entry.is_a?(Hash) }
              raise contract::Invalid, "corrupt campaign #{id}: invalid #{key} records"
            end
          end
          (record["attempts"] + record["rounds"]).each do |attempt|
            unless attempt["binding"].is_a?(Hash) && attempt["sessions"].is_a?(Array) &&
                attempt["sessions"].all? { |session| session.is_a?(Hash) } && attempt["assessments"].is_a?(Array)
              raise contract::Invalid, "corrupt campaign #{id}: invalid round/attempt binding"
            end
          end
          record
        rescue JSON::ParserError, KeyError, TypeError => e
          raise Atoms::CampaignContract::Invalid, "corrupt campaign #{id}: #{e.message}"
        rescue Errno::ENOENT
          raise Atoms::CampaignContract::Invalid, "unknown campaign #{id}"
        end

        def records
          Dir.glob(File.join(root, "*.json")).sort.map { |file| read(File.basename(file, ".json")) }
        end

        # Feedback status changes through its owner lifecycle. Keep the exact
        # verified source bytes so later resolutions cannot erase history.
        def snapshot_finding(reference, repo_root:, dry_run: false)
          return reference if dry_run
          source = File.expand_path(reference.fetch("path"), repo_root)
          bytes = File.binread(source)
          sha = Digest::SHA256.hexdigest(bytes)
          raise Atoms::CampaignContract::Invalid, "finding source changed during recording" unless sha == reference["sha256"]
          directory = File.join(root, "evidence")
          FileUtils.mkdir_p(directory)
          destination = File.join(directory, "#{sha}.s.md")
          if File.exist?(destination)
            unless Digest::SHA256.file(destination).hexdigest == sha
              raise Atoms::CampaignContract::Invalid, "corrupt retained finding snapshot"
            end
          else
            Tempfile.create([".finding-", ".tmp"], directory) do |file|
              file.write(bytes)
              file.flush
              file.fsync
              File.rename(file.path, destination)
              File.open(directory, File::RDONLY, &:fsync)
            end
          end
          {"path" => destination.delete_prefix(repo_root + File::SEPARATOR), "sha256" => sha}
        end

        def write(record)
          destination = path(record.fetch("id"))
          content = JSON.pretty_generate("record" => record, "sha256" => Atoms::CampaignContract.digest(record))
          Tempfile.create([".campaign-", ".tmp"], root) do |file|
            file.write(content)
            file.flush
            file.fsync
            File.rename(file.path, destination)
            File.open(root, File::RDONLY, &:fsync)
          end
        end
      end
    end
  end
end
