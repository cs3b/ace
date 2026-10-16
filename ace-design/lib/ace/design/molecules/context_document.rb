# frozen_string_literal: true
require "yaml"
require "digest"
module Ace
  module Design
    module Molecules
      module ContextDocument
        module_function
        def sha(text)
          Digest::SHA256.hexdigest(text)
        end
        def encode(metadata, body)
          YAML.dump(metadata.merge("body_sha256" => sha(body))) + "---\n" + body
        end
        def decode(text, label)
          match = text.match(/\A---\r?\n(.*?)\r?\n---\r?\n(.*)\z/m)
          raise Error, "Invalid generated context #{label}; run adjust" unless match
          metadata = YAML.safe_load(match[1])
          unless metadata.is_a?(Hash) && metadata["body_sha256"] == sha(match[2])
            raise Error, "Manually changed #{label}; move intended edits to user.md and restore design.md before adjust"
          end
          [metadata, match[2]]
        rescue Psych::Exception => error
          raise Error, "Invalid context metadata #{label}: #{error.message}"
        end
        def effective(id:, defaults:, user:, parent:, body:, decisions:)
          authority = decisions.reject { |_, text| text.strip.empty? }.map do |scope, text|
            "### #{scope.empty? ? 'project' : scope}\n\n#{text}"
          end.join("\n\n")
          body = body.rstrip + "\n"
          unless authority.empty?
            body += "\n## Authoritative user decisions\n\n" +
              "These decisions override stylistic defaults and synthesis. Later explicit decisions supersede earlier ones; " \
              "local decisions refine inherited ones. Execution and shared-data contracts remain in force.\n\n" + authority + "\n"
          end
          encode({"context" => id, "defaults_sha256" => sha(defaults), "user_sha256" => sha(user),
            "parent_sha256" => parent && sha(parent)}, body)
        end
      end
    end
  end
end
