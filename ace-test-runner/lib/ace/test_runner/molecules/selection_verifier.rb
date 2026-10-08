# frozen_string_literal: true
require "digest"
require_relative "../atoms/line_number_resolver"

module Ace
  module TestRunner
    module Molecules
      module SelectionVerifier
        module_function

        def verify_sources!(plan)
          plan.source_digests.each do |file, digest|
            unless Digest::SHA256.file(file).hexdigest == digest
              raise Atoms::LineNumberResolver::SelectionError, "Selected test source changed: #{file}"
            end
          end
        end

        def verify_loaded!(plan, runnables: Minitest::Runnable.runnables)
          verify_sources!(plan)
          # Minitest's default randomized enumeration requires a seed even before run.
          Minitest.seed ||= Random.new_seed
          plan.identities.each do |identity|
            matches = runnables.select { |klass| klass.name == identity.fetch(:class_name) }
            klass = matches.first
            valid = matches.size == 1 && klass < Minitest::Test && klass.public_instance_methods.include?(identity.fetch(:name).to_sym)
            valid &&= klass.runnable_methods.count(identity.fetch(:name)) == 1
            if valid
              method = klass.instance_method(identity.fetch(:name))
              source = method.source_location
              valid = method.owner == klass && source &&
                File.expand_path(source.first) == identity.fetch(:file) && source.last == identity.fetch(:method_line)
            end
            unless valid
              raise Atoms::LineNumberResolver::SelectionError,
                "Selected test identity does not match loaded runnable: #{identity[:class_name]}##{identity[:name]}"
            end
          end
          names = plan.identities.map { |identity| Regexp.escape("#{identity[:class_name]}##{identity[:name]}") }
          "\\A(?:#{names.join('|')})\\z"
        end
      end
    end
  end
end
