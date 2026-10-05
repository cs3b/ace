# frozen_string_literal: true

require "digest"
require_relative "private_directory"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # Receiver-side collection from its own fixed private handler staging.
      # These bytes are transport input, not accepted evidence. The authority
      # must import them through CanonicalEvidence in its terminal mutation.
      module EvidenceTransfer
        module_function

        def read_staged(root:, evidence:)
          root = PrivateDirectory.verify!(root)
          limits = Molecules::CanonicalEvidence
          unless evidence.is_a?(Array) && evidence.length.between?(1, limits::MAX_ARTIFACTS)
            reject!("Invalid staged evidence count")
          end
          total = 0
          evidence.map do |reference|
            unless reference.is_a?(Hash) && reference.keys.sort == %w[ref sha256] &&
                reference["ref"].is_a?(String) && reference["ref"].match?(%r{\A[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*\z}) &&
                reference["ref"].bytesize <= 256 &&
                reference["ref"].split("/").none? { |part| %w[. ..].include?(part) } &&
                reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/)
              reject!("Invalid staged evidence binding")
            end
            path = root
            parts = reference.fetch("ref").split("/")
            parts[0...-1].each do |part|
              path = File.join(path, part)
              stat = File.lstat(path)
              unless stat.directory? && !stat.symlink? && stat.uid == Process.uid && (stat.mode & 0022).zero?
                reject!("Staged evidence ancestry is not private")
              end
            end
            path = File.join(path, parts.last)
            File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
              stat = file.stat
              unless stat.file? && stat.uid == Process.uid && stat.nlink == 1 &&
                  (stat.mode & 0022).zero? && stat.size <= limits::MAX_ARTIFACT_BYTES
                reject!("Staged evidence is not a bounded private regular file")
              end
              bytes = (file.read(limits::MAX_ARTIFACT_BYTES + 1) || "").b
              total += bytes.bytesize
              unless bytes.bytesize <= limits::MAX_ARTIFACT_BYTES && total <= limits::MAX_TOTAL_BYTES &&
                  Digest::SHA256.hexdigest(bytes) == reference["sha256"]
                reject!("Staged evidence bytes differ or exceed limits")
              end
              bytes
            end
          end
        rescue SystemCallError
          reject!("Staged evidence is unavailable or substituted")
        end

        def reject!(message)
          raise AttemptErrors::ReceiptRejected, message
        end
        private_class_method :reject!
      end
    end
  end
end
