# frozen_string_literal: true
require "fileutils"
require "tmpdir"
require_relative "receipt_transfer"

module Ace
  module Assign
    module Authority
      module CampaignRoundTransfer
        def self.decode(input:, sha256:)
          admitted = ReceiptTransfer.decode(input: input, receipt_sha256: sha256,
            artifact_field: "artifacts", reference_key: "path")
          text = input.bytes(index: 0).dup.force_encoding(Encoding::UTF_8)
          raise ArgumentError, "round JSON encoding differs" unless text.valid_encoding? && !text.include?("\0")
          envelope = JSON.parse(text, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
          unless envelope.keys.sort == %w[artifacts round version] && envelope["version"].is_a?(Integer) && envelope["version"] == 1 &&
              envelope["round"].is_a?(Hash) && envelope["artifacts"].all? { |ref| relative_path?(ref["path"]) }
            raise ArgumentError, "round envelope differs"
          end
          {round: envelope.fetch("round"), references: envelope.fetch("artifacts"),
            bytes: admitted.fetch(:artifacts), sha256: sha256}.freeze
        rescue JSON::ParserError, KeyError, TypeError
          raise ArgumentError, "round envelope is malformed"
        end

        def self.relative_path?(path)
          path.is_a?(String) && path.encoding == Encoding::UTF_8 && path.valid_encoding? && path.bytesize.between?(1, 256) &&
            !path.start_with?("/") && !path.include?("\\") && !path.include?("\0") &&
            path.split("/", -1).none? { |component| component.empty? || %w[. ..].include?(component) }
        end

        # Paths are private materialization names, never source filesystem reads.
        # The original R1 replay digest binds all supplied bytes independently.
        def self.materialize(admitted:, repository:, request_id:)
          base = File.join(repository, ".ace-local", "review", "campaign-inputs")
          FileUtils.mkdir_p(base, mode: 0o700)
          PrivateDirectory.verify!(base)
          final = File.join(base, Digest::SHA256.hexdigest(request_id))
          if File.exist?(final)
            PrivateDirectory.verify!(final)
            verify_materialization!(admitted, final)
          else
            temporary = Dir.mktmpdir("round-", base)
            admitted.fetch(:references).zip(admitted.fetch(:bytes)).each do |reference, bytes|
              path = File.join(temporary, reference.fetch("path"))
              FileUtils.mkdir_p(File.dirname(path), mode: 0o700)
              File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
                file.write(bytes)
                file.flush
                file.fsync
              end
            end
            File.rename(temporary, final)
            temporary = nil
            File.open(base, File::RDONLY) { |directory| directory.fsync }
          end
          admitted.fetch(:references).to_h { |reference| [reference.fetch("path"), File.join(final, reference.fetch("path"))] }.freeze
        ensure
          FileUtils.remove_entry(temporary) if temporary && File.directory?(temporary)
        end

        def self.verify_materialization!(admitted, root)
          expected = admitted.fetch(:references).map { |ref| ref.fetch("path") }.sort
          actual = Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).reject { |path| File.directory?(path) }
            .map { |path| path.delete_prefix(root + "/") }.sort
          raise AttemptErrors::Conflict, "round materialization differs" unless expected == actual
          admitted.fetch(:references).each do |reference|
            path = File.join(root, reference.fetch("path"))
            PrivateDirectory.verify!(File.dirname(path))
            File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
              stat = file.stat
              unless stat.file? && stat.uid == Process.uid && stat.nlink == 1 && (stat.mode & 0o777) == 0o600 &&
                  stat.size <= 64 * 1024 && Digest::SHA256.hexdigest(file.read(64 * 1024 + 1)) == reference.fetch("sha256")
                raise AttemptErrors::Conflict, "round materialization bytes differ"
              end
            end
          end
        end
      end
    end
  end
end
