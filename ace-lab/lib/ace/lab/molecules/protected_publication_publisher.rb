# frozen_string_literal: true
require "json"
require "digest"
require "net/http"
require "timeout"
require "rubygems/package"
require "etc"
require "ace/herdr/molecules/bounded_process"
require "ace/assign/authority/private_directory"

module Ace
  module Lab
    module Molecules
      # The admitted receiver owns permission. This boundary only invokes the
      # existing single-artifact publisher and independently checks registry bytes.
      class ProtectedPublicationPublisher
        def initialize(process: Ace::Herdr::Molecules::BoundedProcess, http: Net::HTTP)
          @process, @http = process, http
        end

        def verify!(publication:, artifact_digest:, platform:, deadline:)
          remaining = remaining!(deadline)
          path = "/api/v2/rubygems/#{publication.fetch('gem_name')}/versions/#{publication.fetch('version')}.json?platform=#{URI.encode_www_form_component(platform)}"
          connection = @http.new("rubygems.org", 443, nil)
          connection.use_ssl = true
          connection.open_timeout = remaining
          connection.read_timeout = remaining
          connection.write_timeout = remaining
          connection.max_retries = 0
          response = nil
          body = +""
          Timeout.timeout(remaining, IOError) do
            connection.start do |session|
              connection.read_timeout = remaining!(deadline)
            session.request(Net::HTTP::Get.new(path)) do |received|
              response = received
              received.read_body do |chunk|
                remaining!(deadline)
                raise IOError, "registry response exceeds bound" if body.bytesize + chunk.bytesize > 65_536
                body << chunk
                connection.read_timeout = remaining!(deadline)
              end
            end
          end
          end
          remaining!(deadline)
          return result("absent", "registry_version_absent") if response.is_a?(Net::HTTPNotFound)
          return result("uncertain", "registry_verification_unavailable") unless response.is_a?(Net::HTTPSuccess)
          value = JSON.parse(body, object_class: UniqueObject, max_nesting: 16)
          unless value.is_a?(Hash) && value["name"] == publication.fetch("gem_name") &&
              value["version"] == publication.fetch("version") && value["platform"] == platform &&
              value["sha"].is_a?(String) && value["sha"].match?(/\A[0-9a-f]{64}\z/) && value["yanked"] == false
            return result("uncertain", "registry_verification_invalid")
          end
          value["sha"] == artifact_digest ? result("succeeded", "registry_exact_artifact") : result("failed", "registry_artifact_conflict")
        rescue StandardError
          result("uncertain", "registry_verification_unavailable")
        end

        def push!(operation:, publication:, artifact:, artifact_digest:, otp:, deadline:)
          unless Process.uid == operation.fetch("executor_uid") && Process.euid == Process.uid &&
              operation.fetch("argv").last == "--scoped-publication" &&
              (otp.nil? || otp.is_a?(String) && otp.match?(/\A[0-9]{6}\z/))
            raise SecurityError, "fixed publication executor differs"
          end
          environment = {"PATH" => "/usr/bin:/bin", "LANG" => "C.UTF-8", "HOME" => Etc.getpwuid(Process.uid).dir}
          environment["GEM_HOST_OTP_CODE"] = otp if otp
          input = {"artifact" => artifact, "artifact_digest" => artifact_digest,
            "gem_name" => publication.fetch("gem_name"), "version" => publication.fetch("version")}
          process = @process.call(operation.fetch("argv"), stdin_data: JSON.generate(input),
            timeout_s: [remaining!(deadline), 30].min, output_limit: 1024, stderr_limit: 1024,
            cleanup_group: true, environment: environment, chdir: File.dirname(artifact))
          remaining!(deadline)
          return result("uncertain", "publisher_reply_unavailable") if process.oversized || !process.status.success?
          value = JSON.parse(process.stdout, object_class: UniqueObject, max_nesting: 4)
          allowed = {"otp-required" => "provider_rejected_before_acceptance", "otp-rejected" => "provider_rejected_before_acceptance",
            "otp-expired" => "provider_rejected_before_acceptance", "failed" => %w[provider_rejected_non_otp executor_credentials_unavailable invalid_artifact_selection artifact_identity_mismatch artifact_metadata_mismatch invalid_scoped_input],
            "uncertain" => %w[registry_verification_required provider_result_ambiguous unclassified_push_result publisher_interrupted artifact_changed_during_push]}
          unless value.is_a?(Hash) && value.keys.sort == %w[classification code] && Array(allowed[value["classification"]]).include?(value["code"])
            return result("uncertain", "publisher_reply_invalid")
          end
          value.freeze
        rescue StandardError
          result("uncertain", "publisher_reply_unavailable")
        ensure
          environment&.delete("GEM_HOST_OTP_CODE")
        end

        private

        class UniqueObject < Hash
          def []=(key, value)
            raise JSON::ParserError, "duplicate registry field" if key?(key)
            super
          end
        end

        def remaining!(deadline)
          value = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise IOError, "publication deadline expired" unless value.positive?
          value
        end

        def result(classification, code)
          {"classification" => classification, "code" => code}.freeze
        end
      end
    end
  end
end
