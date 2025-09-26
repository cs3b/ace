# frozen_string_literal: true

module Ace
  module GitCommit
    module Models
      # CommitOptions encapsulates all options for a commit operation
      class CommitOptions
        attr_accessor :intention, :message, :model, :files,
                      :only_staged, :dry_run, :debug, :force

        def initialize(
          intention: nil,
          message: nil,
          model: nil,
          files: [],
          only_staged: false,
          dry_run: false,
          debug: false,
          force: false
        )
          @intention = intention
          @message = message
          @model = model
          @files = files || []
          @only_staged = only_staged
          @dry_run = dry_run
          @debug = debug
          @force = force
        end

        # Check if we should use LLM generation
        # @return [Boolean] True if LLM should be used
        def use_llm?
          @message.nil? || @message.empty?
        end

        # Check if specific files are targeted
        # @return [Boolean] True if specific files provided
        def specific_files?
          !@files.empty?
        end

        # Check if we should stage all changes
        # @return [Boolean] True if all changes should be staged
        def stage_all?
          !@only_staged && !specific_files?
        end

        # Convert to hash for debugging
        # @return [Hash] Options as hash
        def to_h
          {
            intention: @intention,
            message: @message,
            model: @model,
            files: @files,
            only_staged: @only_staged,
            dry_run: @dry_run,
            debug: @debug,
            force: @force
          }
        end
      end
    end
  end
end