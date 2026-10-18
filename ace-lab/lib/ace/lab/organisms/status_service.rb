# frozen_string_literal: true

require "open3"

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
          @root = root || resolve_project_root
        end

        # Production factory: a service that resolves the cascade on each
        # call, so every report observes current files. A broken cascade
        # becomes the report's :invalid section instead of an exception.
        def self.from_config(root: nil)
          new(root: root)
        end

        # @return [Models::StatusReport]
        def report
          documents, cascade_error = begin
            [Ace::Lab.cascade_documents, nil]
          rescue Ace::Lab::InvalidConfigurationError => e
            [nil, e.message]
          end
          build(documents: documents, cascade_error: cascade_error)
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

        private

        # State locations belong to the project root, not the caller's cwd:
        # running from a subdirectory must not misreport an initialized lab
        # as absent. Same resolution as ace-coworker's ProjectRoot (git
        # worktree top), falling back to the cwd outside a repository.
        def resolve_project_root
          out, _err, status = Open3.capture3("git", "rev-parse", "--show-toplevel")
          return Dir.pwd unless status.success?

          root = out.to_s.strip
          root.empty? ? Dir.pwd : root
        rescue StandardError
          Dir.pwd
        end
      end
    end
  end
end
