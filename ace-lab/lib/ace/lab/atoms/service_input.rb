# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Lab
    module Atoms
      # Bounded structured input for a named service operation. Only the
      # digest enters the request index; input values never enter the journal.
      module ServiceInput
        MAX_BYTES = 64 * 1024
        FORBIDDEN_KEYS = /credential|password|secret|token|private.key|authorization|\Aenv\z/i
        SHA256 = /\A[0-9a-f]{64}\z/
        RESOURCE = /\A[a-zA-Z0-9_.:\/-]{1,256}\z/

        def self.load(path)
          begin
            flags = File::RDONLY | File::NOFOLLOW | File::NONBLOCK
            data = File.open(path, flags) do |file|
              before = file.stat
              unless before.file? && before.size <= MAX_BYTES && same_file?(before, File.lstat(path))
                raise ArgumentError, "input must be a bounded regular file"
              end
              content = file.read(MAX_BYTES + 1).to_s
              unless content.bytesize <= MAX_BYTES && same_file?(before, file.stat) &&
                  same_file?(before, File.lstat(path))
                raise ArgumentError, "input file changed while reading"
              end
              JSON.parse(content, allow_duplicate_key: false, allow_comments: false,
                allow_nan: false, create_additions: false, max_nesting: 16)
            end
          rescue SystemCallError, IOError
            raise ArgumentError, "input file is unreadable"
          end
          raise ArgumentError, "input must be a JSON object" unless data.is_a?(Hash)
          validate!(data)
          data
        rescue JSON::ParserError
          raise ArgumentError, "input must be valid JSON"
        end

        def self.same_file?(left, right)
          [left.dev, left.ino, left.mode, left.uid, left.gid, left.size, left.mtime, left.ctime] ==
            [right.dev, right.ino, right.mode, right.uid, right.gid, right.size, right.mtime, right.ctime]
        end
        private_class_method :same_file?

        def self.digest(data)
          Digest::SHA256.hexdigest(JSON.generate(canonical(data)))
        end

        def self.target(data)
          target = data["target"]
          raise ArgumentError, "input.target must be an object" unless target.is_a?(Hash)
          resource = target["resource"]
          artifact = target["artifact_digest"]
          raise ArgumentError, "input.target.resource must be a stable resource ID" unless
            resource.is_a?(String) && resource.match?(RESOURCE)
          if artifact && (!artifact.is_a?(String) || !artifact.match?(SHA256))
            raise ArgumentError, "input.target.artifact_digest must be SHA-256"
          end
          {"resource" => resource, "artifact_digest" => artifact}
        end

        def self.canonical(value)
          case value
          when Hash then value.keys.sort.each_with_object({}) { |key, result| result[key] = canonical(value[key]) }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end

        def self.validate!(value, depth = 0)
          raise ArgumentError, "input nesting is too deep" if depth > 16
          case value
          when Hash
            value.each do |key, item|
              raise ArgumentError, "input has a forbidden field" if !key.is_a?(String) || key.match?(FORBIDDEN_KEYS)
              validate!(item, depth + 1)
            end
          when Array then value.each { |item| validate!(item, depth + 1) }
          when String, Integer, Float, TrueClass, FalseClass, NilClass
            raise ArgumentError, "input contains a non-finite number" if value.is_a?(Float) && !value.finite?
          else
            raise ArgumentError, "input contains an unsupported value"
          end
        end
      end
    end
  end
end
