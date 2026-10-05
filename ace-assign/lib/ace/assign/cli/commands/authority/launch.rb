# frozen_string_literal: true
require "json"
require_relative "../../../authority/launch_driver"
module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class Launch < Ace::Support::Cli::Command
            desc "Launch one mapped native worker through the protected gate"
            option :mapping, required: true, desc: "Installed launch mapping ID"
            option :assignment, desc: "Managed assignment ID"
            option :definition, desc: "Current managed assignment definition JSON file"
            option :step, desc: "Assignment subtree scope"
            option :base_head, desc: "Exact base commit SHA"
            option :mutation, desc: "Stable invocation ID for safe replay"
            option :dry_run, type: :boolean, default: false, desc: "Verify installed boundary without mutation or creation"
            def call(**options)
              driver = build_driver(options.fetch(:mapping))
              result = if options[:dry_run]
                driver.preflight
              else
                %i[assignment definition step base_head].each do |key|
                  raise ArgumentError, "Missing --#{key.to_s.tr('_', '-')}" unless options[key].is_a?(String) && !options[key].empty?
                end
                raise ArgumentError, "assignment definition is oversized" if File.size(options[:definition]) > 32_768
                args = {assignment_id: options[:assignment], definition_bytes: File.read(options[:definition]),
                  scope: options[:step], base_head: options[:base_head]}
                args[:mutation_id] = options[:mutation] if options[:mutation]
                driver.launch(**args)
              end
              puts JSON.generate(result)
            rescue ArgumentError, SystemCallError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            end
            private
            def build_driver(mapping)
              Ace::Assign::Authority::LaunchDriver.new(mapping_id: mapping)
            end
          end
        end
      end
    end
  end
end
