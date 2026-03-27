# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module RecordOptionValidator
        module_function

        MP4_UNSUPPORTED_ERROR =
          "Unsupported format: mp4. Use gif, or use --backend vhs --format webm for compatibility output."

        def normalize_backend(value)
          return nil if value.nil?

          backend = value.to_s.strip.downcase
          return backend if %w[asciinema vhs].include?(backend)

          raise ArgumentError, "Unknown backend '#{backend}'. Valid: asciinema, vhs"
        end

        def normalize_format(value, supported_formats:, allow_nil: true)
          return nil if value.nil? && allow_nil

          format = value.to_s.downcase
          raise ArgumentError, MP4_UNSUPPORTED_ERROR if format == "mp4"
          raise ArgumentError, "Unsupported format: #{format}" unless supported_formats.include?(format)

          format
        end

        def validate_yaml_backend_format!(backend:, format:)
          return unless format == "webm" && backend != "vhs"

          raise ArgumentError, "Format 'webm' requires --backend vhs when recording YAML tapes"
        end

        def validate_raw_tape_backend!(backend:)
          return if backend.nil? || backend == "vhs"

          raise ArgumentError, "Raw .tape recordings support backend 'vhs' only"
        end
      end
    end
  end
end
