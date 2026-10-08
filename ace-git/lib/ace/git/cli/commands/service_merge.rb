# frozen_string_literal: true
require_relative "../../organisms/service_merge"

module Ace
  module Git
    module CLI
      module Commands
        class ServiceMerge < Ace::Support::Cli::Command
          desc "Execute a fixed receiver-owned exact-head PR envelope"

          def initialize(input: nil, producer: nil, root: nil, operation: "merge")
            @input, @producer, @root, @operation = input, producer, root, operation
          end

          def call(**options)
            raise ArgumentError, "fixed PR entry accepts no options" unless options.empty?
            bytes = (@input || $stdin).read(Organisms::ServiceMerge::MAX_INPUT + 1)
            result = (@producer || Organisms::ServiceMerge.new(operation: @operation)).call(bytes: bytes, root: @root || Dir.pwd)
            puts JSON.generate(result)
          rescue Ace::Git::Error, ArgumentError, SystemCallError, IOError => error
            # No stdout receipt on an unverified/uncertain effect. The existing
            # receiver retains its original dispatch instead of retrying it.
            raise Ace::Support::Cli::Error, error.message
          end
        end
      end
    end
  end
end
