# frozen_string_literal: true

require "digest"

module Ace
  module Assign
    module Atoms
      # Git's fixed cat-file batch framing. Owners select process, immutable
      # repository, deadline and byte/count limits before invoking this codec.
      module GitBlobBatch
        OID = /\A[0-9a-f]{40}\z/
        class Invalid < StandardError
          attr_reader :reason
          def initialize(reason)
            @reason = reason
            super("invalid Git blob batch #{reason}")
          end
        end

        def self.sizes(oids, output)
          unless oids.is_a?(Array) && oids.all? { |oid| oid.is_a?(String) && OID.match?(oid) } && output.is_a?(String)
            raise Invalid, :selector
          end
          lines = output.b.lines
          raise Invalid, :count unless lines.size == oids.size
          lines.zip(oids).map do |line, oid|
            match = /\A([0-9a-f]{40}) blob (0|[1-9][0-9]*)\n\z/.match(line)
            raise Invalid, :metadata unless match && match[1] == oid
            match[2].to_i
          end
        end

        def self.decode(entries, output)
          unless entries.is_a?(Array) && entries.all? { |entry|
              entry.is_a?(Array) && entry.size == 2 && entry[0].is_a?(String) && OID.match?(entry[0]) &&
                entry[1].is_a?(Integer) && entry[1] >= 0 } && output.is_a?(String)
            raise Invalid, :selector
          end
          output = output.b
          offset = 0
          entries.map do |oid, size|
            ending = output.index("\n", offset)
            unless ending && ending - offset <= 127 && output.byteslice(offset, ending - offset) == "#{oid} blob #{size}"
              raise Invalid, :header
            end
            offset = ending + 1
            content = output.byteslice(offset, size)
            unless content&.bytesize == size && output.byteslice(offset + size, 1) == "\n" &&
                Digest::SHA1.new.update("blob #{size}\0").update(content).hexdigest == oid
              raise Invalid, :bytes
            end
            offset += size + 1
            content
          end.tap { raise Invalid, :trailing unless offset == output.bytesize }
        end
      end
    end
  end
end
