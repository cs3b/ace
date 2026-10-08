# frozen_string_literal: true

require "fileutils"
require "json"
require "tempfile"
require_relative "../atoms/campaign_contract"
require_relative "../atoms/campaign_policy"

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

        def transaction(dry_run: false, require_lock: false)
          if dry_run
            # No directory or lock-file creation in dry-run mode.
            if require_lock && !File.directory?(root)
              raise Atoms::CampaignContract::Invalid, "campaign lock unavailable"
            end
            return yield unless File.directory?(root)
            lock_path = File.join(root, ".lock")
            if require_lock && !File.file?(lock_path)
              raise Atoms::CampaignContract::Invalid, "campaign lock unavailable"
            end
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
          read_record(id, index: identity_index)
        end

        def registered_id?(id)
          identity_index["subjects"].values.any? { |entry| entry["campaign_ids"].include?(id) }
        end

        def records(subject:)
          index = identity_index
          entry = index["subjects"][Atoms::CampaignContract.digest(subject)]
          return [] unless entry
          entry.fetch("campaign_ids").map { |id| read_record(id, index: index) }
        end

        private def read_record(id, index:)
          identity = index["subjects"].values.find { |entry| entry["campaign_ids"].include?(id) }
          raise Atoms::CampaignContract::Invalid, "unknown indexed campaign #{id}" unless identity
          envelope = JSON.parse(File.read(path(id)))
          record = envelope.fetch("record")
          unless record.is_a?(Hash) && record["id"] == id && record["subject"] == identity["subject"] &&
              envelope["sha256"] == Atoms::CampaignContract.digest(record)
            raise Atoms::CampaignContract::Invalid, "corrupt campaign #{id}: identity or checksum mismatch"
          end
          %w[subject contract_identity contract policy profile bounds phases execution_attempts inherited_findings assessments attempts rounds head_transitions].each do |key|
            raise Atoms::CampaignContract::Invalid, "corrupt campaign #{id}: missing #{key}" unless record.key?(key)
          end
          contract = Atoms::CampaignContract
          unless contract.subject!(record["subject"]) == record["subject"]
            raise contract::Invalid, "corrupt campaign #{id}: noncanonical subject identity"
          end
          contract.string!(record["contract"], "stored requirements")
          unless Digest::SHA256.hexdigest(record["contract"]) == record["contract_identity"]
            raise contract::Invalid, "corrupt campaign #{id}: requirements digest mismatch"
          end
          contract.policy!(record["policy"])
          %w[phases execution_attempts inherited_findings assessments attempts rounds head_transitions].each do |key|
            unless record[key].is_a?(Array) && record[key].all? { |entry| entry.is_a?(Hash) }
              raise contract::Invalid, "corrupt campaign #{id}: invalid #{key} records"
            end
          end
          bounds = Atoms::CampaignPolicy.bounds!(profile: record.fetch("profile"), policy: record.fetch("policy"))
          raise contract::Invalid, "stored campaign bounds differ" unless bounds == record.fetch("bounds")
          phases = record.fetch("phases")
          initial = {"id" => "initial", "profile" => record.fetch("profile"), "round_start" => 0,
            "maximum_rounds" => bounds.fetch("maximum_rounds")}
          raise contract::Invalid, "initial campaign phase differs" unless phases.first == initial
          phases.each_with_index do |phase, index|
            contract.id!(phase["id"], "phase ID")
            unless phase["profile"] == record["profile"] && phase["round_start"].is_a?(Integer) &&
                phase["round_start"].between?(0, record["rounds"].size) &&
                phase["maximum_rounds"].is_a?(Integer) && phase["maximum_rounds"].positive?
              raise contract::Invalid, "invalid campaign phase"
            end
            next if index.zero?
            contract.string!(phase["reason"], "phase reason")
            contract.string!(phase["route"], "phase route")
            previous = phases[index - 1]
            unless phase["round_start"] >= previous["round_start"] &&
                phase["round_start"] - previous["round_start"] <= previous["maximum_rounds"]
              raise contract::Invalid, "campaign phase exceeded budget"
            end
          end
          unless phases.map { |phase| phase["id"] }.uniq.size == phases.size &&
              record["rounds"].size - phases.last["round_start"] <= phases.last["maximum_rounds"]
            raise contract::Invalid, "campaign phase identity or budget differs"
          end
          executions = record.fetch("execution_attempts")
          executions.each do |entry|
            contract.id!(entry["id"], "execution ID")
            unless phases.any? { |phase| phase["id"] == entry["phase_id"] } &&
                record["attempts"].any? { |attempt| attempt["round_id"] == entry["round_id"] } &&
                record["policy"]["required_scopes"].include?(entry["scope"])
              raise contract::Invalid, "execution phase/round/scope differs"
            end
            Atoms::CampaignPolicy.retry_decision(attempts: [entry], round_id: entry["round_id"],
              scope: entry["scope"], provider: entry["provider"])
          end
          unless executions.map { |entry| entry["id"] }.uniq.size == executions.size &&
              executions.group_by { |entry| entry.values_at("phase_id", "round_id", "scope", "provider") }
                .values.all? { |entries| entries.size <= Atoms::CampaignPolicy::INFRASTRUCTURE_RETRIES + 1 }
            raise contract::Invalid, "execution identity or retry budget differs"
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
          raise Atoms::CampaignContract::Invalid, "indexed campaign #{id} unavailable; restore its retained campaign record"
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
          contract = Atoms::CampaignContract
          destination = path(record.fetch("id"))
          subject = contract.subject!(record.fetch("subject"))
          raise contract::Invalid, "noncanonical campaign subject" unless subject == record["subject"]
          index = identity_index
          key = contract.digest(subject)
          owner = index["subjects"].values.find { |entry| entry["campaign_ids"].include?(record["id"]) }
          raise contract::Invalid, "campaign ID belongs to another subject" if owner && owner["subject"] != subject
          unless owner
            entry = index["subjects"][key] ||= {"subject" => subject, "campaign_ids" => []}
            entry["campaign_ids"] << record["id"]
            # Publish the identity first: interrupted creation cannot erase history.
            persist(File.join(root, ".identity-index.json"), "index" => index, "sha256" => contract.digest(index))
          end
          persist(destination, "record" => record, "sha256" => contract.digest(record))
        end

        private

        def identity_index
          contract = Atoms::CampaignContract
          index_path = File.join(root, ".identity-index.json")
          files = Dir.glob(File.join(root, "*.json")).map { |file| File.basename(file, ".json") }
          unless File.file?(index_path)
            raise contract::Invalid, "campaign identity index unavailable; restore retained index" unless files.empty?
            return {"version" => 1, "subjects" => {}}
          end
          envelope = JSON.parse(File.read(index_path))
          index = envelope.fetch("index")
          unless index.is_a?(Hash) && index["version"] == 1 && index["subjects"].is_a?(Hash) &&
              envelope["sha256"] == contract.digest(index)
            raise contract::Invalid, "corrupt campaign identity index"
          end
          ids = []
          index["subjects"].each do |key, entry|
            unless entry.is_a?(Hash) && contract.subject!(entry["subject"]) == entry["subject"] &&
                key == contract.digest(entry["subject"]) && entry["campaign_ids"].is_a?(Array) && !entry["campaign_ids"].empty?
              raise contract::Invalid, "corrupt campaign identity index entry"
            end
            entry["campaign_ids"].each { |id| contract.id!(id, "indexed campaign ID"); ids << id }
          end
          unless ids.uniq == ids && (files - ids).empty?
            raise contract::Invalid, "duplicate or unregistered campaign identity; restore retained index"
          end
          index
        rescue JSON::ParserError, KeyError, TypeError => e
          raise contract::Invalid, "corrupt campaign identity index: #{e.message}"
        end

        def persist(destination, envelope)
          Tempfile.create([".campaign-", ".tmp"], root) do |file|
            file.write(JSON.pretty_generate(envelope))
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
