# frozen_string_literal: true

module Ace
  module Lab
    module Organisms
      # Assembles the lab status report: configuration classification plus
      # the read-only state scan. Strictly read-only observability — no
      # authorization gate (the fail-closed CallerAuthorizer path belongs
      # to the topology query commands), no writes, no services started,
      # no installer dependency (task 8xg.t.sbz.6.0).
      class StatusService
        def initialize(classifier: nil, runtime_reader: nil, scanner: nil, root: nil)
          @classifier = classifier || Molecules::ConfigStateClassifier
          @runtime_reader = runtime_reader || Molecules::ConfigStateClassifier
          @scanner = scanner || Molecules::LabStateScanner
          @root = root || Dir.pwd
        end

        # Production factory: resolves the cascade like the query commands
        # do, but a broken cascade becomes the report's :invalid section
        # instead of an exception.
        def self.from_config(root: nil)
          root ||= Dir.pwd
          documents, cascade_error = begin
            [Ace::Lab.cascade_documents, nil]
          rescue Ace::Lab::InvalidConfigurationError => e
            [nil, e.message]
          end
          new(root: root).build(documents: documents, cascade_error: cascade_error)
        end

        # @param documents [Array<Hash>, nil]
        # @param cascade_error [String, nil]
        # @return [Models::StatusReport]
        def build(documents:, cascade_error: nil)
          config = @classifier.classify(documents: documents, cascade_error: cascade_error, root: @root)
          runtime = @runtime_reader.runtime_config(root: @root)
          Models::StatusReport.new(
            config: config,
            runtime_config: runtime,
            state: @scanner.scan(root: @root),
            root: @root
          )
        end
      end
    end
  end
end
