# frozen_string_literal: true
require "json"

module Ace
  module Assign
    module CLI
      module Commands
        class Delivery < Ace::Support::Cli::Command
          desc "Execute or reconcile attempt-bound forge delivery"
          option :assignment, required: true, desc: "Managed assignment ID"
          option :attempt, required: true, desc: "Active delivery attempt ID"
          option :operation, required: true, desc: "create, update, ready, review, merge, status"
          option :parameters, desc: "JSON delivery parameters (otherwise assignment source delivery mapping)"
          option :title, desc: "PR title"
          option :body_file, desc: "PR description file"
          option :tests, desc: "JSON reference to coordinator-accepted test attempt and receipt digest"
          option :review, desc: "JSON reference to coordinator-accepted independent review attempt and receipt digest"
          option :service_request, desc: "Completed authorized qjx merge request ID (merge consumption only)"

          def call(**options)
            result = build_delivery.perform(assignment_id: options[:assignment], attempt_id: options[:attempt],
              operation: options[:operation], parameters: read_json(options[:parameters]),
              title: options[:title], body: options[:body_file] && File.read(options[:body_file]),
              tests: read_json(options[:tests]), review: read_json(options[:review]),
              service_request_id: options[:service_request])
            puts JSON.generate(json_value(result))
          rescue ArgumentError, Ace::Git::Error, Ace::Assign::Error, Errno::ENOENT => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def build_delivery
            Organisms::DeliveryCoordinator.new(repo_root: Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current)
          end

          def read_json(path)
            return nil unless path
            data = JSON.parse(File.read(path))
            raise ArgumentError, "Delivery input must be a JSON object" unless data.is_a?(Hash)
            data
          rescue JSON::ParserError
            raise ArgumentError, "Delivery input must be valid JSON"
          end

          def json_value(value)
            case value
            when Hash then value.transform_values { |item| json_value(item) }
            when Array then value.map { |item| json_value(item) }
            else value.respond_to?(:to_h) ? json_value(value.to_h) : value
            end
          end
        end
      end
    end
  end
end
