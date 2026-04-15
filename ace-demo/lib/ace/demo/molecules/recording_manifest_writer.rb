# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Demo
    module Molecules
      class RecordingManifestWriter
        def write(recording:)
          target_path = manifest_path_for(recording)
          FileUtils.mkdir_p(File.dirname(target_path))
          File.write(target_path, JSON.pretty_generate(payload(recording)))
          target_path
        end

        private

        def manifest_path_for(recording)
          source_path = recording.cast_path || recording.visual_path || "demo"
          ext = File.extname(source_path)
          base = source_path.sub(/#{Regexp.escape(ext)}\z/, "")
          "#{base}.recording.json"
        end

        def payload(recording)
          verification = recording.verification
          {
            backend: recording.backend,
            tape_path: recording.tape_path,
            cast_path: recording.cast_path,
            visual_path: recording.visual_path,
            sandbox_path: recording.sandbox_path,
            verification: verification && {
              status: verification.status,
              classification: verification.classification,
              summary: verification.summary,
              retryable: verification.retryable?,
              report_path: verification.report_path,
              details: verification.details
            }
          }.compact
        end
      end
    end
  end
end
