# frozen_string_literal: true

require "json"
require "ace/support/cli"
require_relative "support"
require_relative "../../molecules/native_source"
require_relative "../../organisms/native_source_builder"

module Ace
  module Herdr
    module CLI
      module Commands
        class NativeSource < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc "Describe, build, or verify the packaged guarded native source without running Herdr"
          argument :operation, desc: "selection, build, or verify"
          option :source, type: :string, desc: "Clean local Git checkout containing the pinned baseline"
          option :output, type: :string, desc: "New build artifact directory"
          option :target, type: :string, desc: "Selected Linux target"
          option :artifact, type: :string, desc: "Build artifact directory to verify"

          def initialize(selection: nil, builder: nil)
            @selection = selection
            @builder = builder
          end

          def call(operation: nil, **options)
            selection = @selection || Molecules::NativeSource.new
            supplied = options.select { |key, value| %i[source output target artifact].include?(key) && !value.nil? }.keys
            result = case operation
            when "selection"
              cli_error("selection accepts no build/artifact options") unless supplied.empty?
              selection.description
            when "verify"
              cli_error("verify requires only --artifact") unless supplied == [:artifact] && !options[:artifact].empty?
              selection.verify_artifact(directory: options.fetch(:artifact))
            when "build"
              unless supplied.sort == %i[output source target] && supplied.all? { |key| !options[key].empty? }
                cli_error("build requires --source, --output and --target")
              end
              builder = @builder || Organisms::NativeSourceBuilder.new(selection: selection)
              builder.build(source: options.fetch(:source), output: options.fetch(:output), target: options.fetch(:target))
            else
              cli_error("native-source operation must be selection, build, or verify")
            end
            puts JSON.generate(result)
          rescue Molecules::NativeSource::Error => error
            raise Ace::Support::Cli::Error, error.message
          end
        end
      end
    end
  end
end
