# frozen_string_literal: true

module Ace
  module Sim
    module Molecules
      class SourceResolver
        def resolve(source)
          normalized = source.to_s.strip
          raise Ace::Sim::ValidationError, "source cannot be empty" if normalized.empty?

          expanded = File.expand_path(normalized)
          raise Ace::Sim::ValidationError, "source file not found: #{normalized}" unless File.file?(expanded)
          raise Ace::Sim::ValidationError, "source file is not readable: #{normalized}" unless File.readable?(expanded)

          {"path" => expanded}
        end
      end
    end
  end
end
