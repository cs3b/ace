# frozen_string_literal: true
require "json"

module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class Base < Ace::Support::Cli::Command
            option :format, default: "json", desc: "Output format: json or text"
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress text output; JSON is always emitted"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Include complete text projection"
            option :dry_run, type: :boolean, desc: "Validate without creating or writing campaign state"

            private

            def read_json(path)
              Atoms::CampaignContract.string!(path, "input file")
              JSON.parse(File.read(path))
            end

            def run(options)
              unless %w[json text].include?(options[:format])
                raise Atoms::CampaignContract::Invalid, "--format must be json or text"
              end
              payload = yield Organisms::CampaignManager.new
              emit(payload, options)
              payload
            rescue Atoms::CampaignContract::Invalid, JSON::ParserError, SystemCallError, TypeError, KeyError => e
              payload = {"accepted" => false, "error" => e.message, "reasons" => [e.message]}
              emit(payload, options)
              raise Ace::Support::Cli::Error, e.message
            end

            def emit(payload, options)
              if options[:format] == "text"
                return if options[:quiet]
                puts options[:verbose] ? JSON.pretty_generate(payload) :
                  "Campaign #{payload['campaign_id'] || '?'}: #{payload['completed_rounds'] || 0} rounds, " \
                  "#{payload['clean_streak'] || 0} clean; #{payload['accepted'] ? 'accepted' : 'pending/blocked'}"
                puts Array(payload["reasons"]).join("; ") unless Array(payload["reasons"]).empty?
              else
                puts JSON.generate(payload)
              end
            end
          end
        end
      end
    end
  end
end
