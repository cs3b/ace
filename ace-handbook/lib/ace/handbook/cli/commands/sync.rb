# frozen_string_literal: true

module Ace
  module Handbook
    module CLI
      module Commands
        class Sync < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Project canonical handbook skills into provider-native folders"

          option :provider, aliases: ["-p"], desc: "Limit sync to a single provider"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress sync summary output"

          def initialize(syncer: nil)
            super()
            @syncer = syncer || Ace::Handbook::Organisms::ProviderSyncer.new
          end

          def call(provider: nil, quiet: false, **)
            results = @syncer.sync(provider: provider)
            return if quiet

            results.each do |result|
              puts "synced #{result[:provider]} -> #{result[:relative_output_dir]} " \
                   "(#{result[:projected_skills]} skills, #{result[:updated_files]} updated, " \
                   "#{result[:removed_entries]} removed)"
            end
          rescue StandardError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
