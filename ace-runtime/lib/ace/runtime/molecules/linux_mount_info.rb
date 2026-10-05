# frozen_string_literal: true

require_relative "../errors"

module Ace
  module Runtime
    module Molecules
      # Decodes actual Linux mountinfo records. Paths alone do not select a
      # visible mount; callers must use the pinned descriptor's mnt_id.
      class LinuxMountInfo
        LIMIT = 1_048_576
        ESCAPES = {"040" => " ", "011" => "\t", "012" => "\n", "134" => "\\"}.freeze
        attr_reader :records

        def initialize(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, LIMIT) && !bytes.include?("\0")
            unavailable!("kernel mount table is unavailable")
          end
          @records = bytes.lines.map do |line|
            fields = line.chomp.split(" ")
            separator = fields.index("-")
            unless separator && separator >= 6 && fields.size == separator + 4 &&
                fields[0].match?(/\A[1-9][0-9]*\z/) && fields[1].match?(/\A[0-9]+\z/) &&
                fields[2].match?(/\A[0-9]+:[0-9]+\z/) &&
                fields[6...separator].all? { |field| field == "unbindable" || field.match?(/\A(?:shared|master|propagate_from):[1-9][0-9]*\z/) }
              unavailable!("kernel mount table is malformed")
            end
            root, mountpoint = fields.values_at(3, 4).map { |value| decode(value) }
            unless [root, mountpoint].all? { |path| path.start_with?("/") && File.expand_path(path) == path } &&
                fields[separator + 1].match?(/\A[a-zA-Z0-9_.-]+\z/)
              unavailable!("kernel mount paths/filesystem are malformed")
            end
            {"mount_id" => Integer(fields[0], 10), "parent_id" => Integer(fields[1], 10),
             "major_minor" => fields[2], "root" => root, "mountpoint" => mountpoint,
             "options" => options(fields[5]), "optional_fields" => fields[6...separator],
             "filesystem_type" => fields[separator + 1], "source" => decode(fields[separator + 2]),
             "super_options" => options(fields[separator + 3])}.then { |record| freeze_tree(record) }
          end.freeze
          unless records.map { |record| record.fetch("mount_id") }.uniq.size == records.size
            unavailable!("kernel mount IDs are duplicate")
          end
        end

        def by_id(mount_id)
          record = records.find { |entry| entry.fetch("mount_id") == mount_id }
          unavailable!("pinned object mount is missing") unless record
          record
        end

        def filesystem_path(record, path)
          prefix = record.fetch("mountpoint")
          unless path.is_a?(String) && File.expand_path(path) == path &&
              (path == prefix || prefix == "/" && path.start_with?("/") || path.start_with?(prefix + "/"))
            unavailable!("object is outside its descriptor mount")
          end
          relative = prefix == "/" ? path.delete_prefix("/") : path.delete_prefix(prefix).delete_prefix("/")
          relative.empty? ? record.fetch("root") : File.join(record.fetch("root"), relative)
        end

        private

        def freeze_tree(value)
          case value
          when Hash then value.each { |key, item| key.freeze; freeze_tree(item) }
          when Array then value.each { |item| freeze_tree(item) }
          end
          value.freeze
        end

        def options(value)
          parts = value.split(",", -1)
          unavailable!("kernel mount options are malformed") if parts.any?(&:empty?) || parts.uniq.size != parts.size
          parts.freeze
        end

        def decode(value)
          value.gsub(/\\([^ ]*)/) do
            remaining = Regexp.last_match(1)
            result = +""
            until remaining.empty?
              code = remaining.slice(0, 3)
              unavailable!("kernel mount path escape is malformed") unless ESCAPES.key?(code)
              result << ESCAPES.fetch(code)
              remaining = remaining.slice(3..)
              literal, escaped = remaining.split("\\", 2)
              result << literal
              remaining = escaped || ""
            end
            result
          end
        end

        def unavailable!(message) = raise(RuntimeUnavailableError, message)
      end
    end
  end
end
