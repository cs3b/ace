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
            print_inventory_summary(results)
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def print_inventory_summary(results)
            source_breakdown = results.first&.fetch(:source_breakdown, {})
            return if source_breakdown.nil? || source_breakdown.empty?

            puts "inventory sources: #{format_source_breakdown(source_breakdown)}"
            return unless source_breakdown.length == 1

            source = source_breakdown.keys.first
            puts "note: only '#{source}' skills were discovered. if you installed additional ace-* packages recently, rerun `ace-handbook sync` after installation."
          end

          def format_source_breakdown(source_breakdown)
            source_breakdown.map { |source, count| "#{source}:#{count}" }.join(", ")
          end
        end
      end
    end
  end
end
