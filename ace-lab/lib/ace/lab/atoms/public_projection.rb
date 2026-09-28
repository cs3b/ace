# frozen_string_literal: true

require "uri"

module Ace
  module Lab
    module Atoms
      # Allowlist-based public projection of topology entries (spec 8wq.t.1w4).
      # Public output is constructed exclusively from the fields below, so raw
      # configuration values can never leak: no tokens, auth-file paths,
      # endpoint credentials, URL userinfo, path, query parameters, fragments,
      # pane/session identifiers, or instance identities.
      module PublicProjection
        class << self
          # @return [Hash] {id, label?}
          def project(entry)
            public_entry = {"id" => entry.id}
            public_entry["label"] = entry.label if entry.label
            public_entry
          end

          # @return [Hash] {id, project, label?, role, capabilities,
          #                 binding: {kind, state}}
          def agent(entry)
            public_entry = {
              "id" => entry.id,
              "project" => entry.project,
              "role" => entry.role,
              "capabilities" => entry.capabilities,
              "binding" => binding_summary(entry.binding)
            }
            public_entry["label"] = entry.label if entry.label
            public_entry
          end

          # @return [Hash] {id, project, label?, capabilities, default_for,
          #                 binding: {kind, state, endpoint: {kind, url?}}}
          def service(entry)
            public_entry = {
              "id" => entry.id,
              "project" => entry.project,
              "capabilities" => entry.capabilities,
              "default_for" => entry.default_for,
              "binding" => binding_summary(entry.binding).merge(endpoint_summary(entry))
            }
            public_entry["label"] = entry.label if entry.label
            public_entry
          end

          # Project an entry of any kind
          def entry(entry)
            case entry.kind
            when "project" then project(entry)
            when "agent" then agent(entry)
            else service(entry)
            end
          end

          private

          # Availability state derived from freshness; never exposes
          # instance identities or raw configured state
          def binding_summary(binding)
            {
              "kind" => binding&.kind,
              "state" => binding_freshness(binding)
            }
          end

          def binding_freshness(binding)
            fresh = Ace::Lab::Atoms::BindingFreshness.fresh?(binding)
            fresh ? "available" : "stale"
          end

          # Safe endpoint identity: scheme, host, and explicit port only.
          # Userinfo, path, query, and fragment are dropped by construction;
          # an unparseable URL projects no endpoint identity at all.
          def endpoint_summary(entry)
            endpoint = entry.endpoint
            return {} unless endpoint.is_a?(Hash)

            {"endpoint" => {"kind" => endpoint["kind"], "url" => sanitize_url(endpoint["url"])}}
          end

          def sanitize_url(url)
            uri = URI.parse(url)
            return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            return nil if uri.host.nil? || uri.host.empty?

            (uri.port == uri.default_port) ? "#{uri.scheme}://#{uri.host}" : "#{uri.scheme}://#{uri.host}:#{uri.port}"
          rescue URI::Error, ArgumentError
            nil
          end
        end
      end
    end
  end
end
