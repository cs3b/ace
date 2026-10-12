# frozen_string_literal: true

require "json"
require "socket"
require "openssl"
require "securerandom"
require "time"
require "ace/hitl/lifecycle"

module Ace
  module Hitl
    module Hermes
      module Boundary
        # The nh0-A source scenario (spec 8xa.t.nh0): the acceptance
        # harness the reviewed `bin/lab-hitl-boundary-fixture` fixture
        # invokes against the REAL disposable Incus proxies. The host
        # lab-config owner provisions the identities, endpoints and
        # credential trees (gad.8/gad.b); this harness only drives the
        # declared scenario and reports a closed-schema receipt.
        #
        # It is NEVER a substitute for the invocation-bound
        # `nh0_real_incus_acceptance` receipt: loopback-only or mocked
        # runs of this harness cannot clear nh0-A.
        class Scenario
          SCHEMA = "ace.hitl.boundary.scenario/v1"
          SCENARIO_NAME = "nh0-a-v1"
          RECEIPT_TYPE = "nh0_a_source_scenario"
          MANIFEST_FIELDS = %w[schema invocation_id scenario authorities credentials request].freeze
          AUTHORITY_FIELDS = %w[endpoint project].freeze
          CREDENTIAL_FIELDS = %w[tls_client_credential service_user service_group].freeze
          REQUEST_FIELDS = %w[assignment attempt_prefix harness question answer].freeze
          REQUIRED_CREDENTIALS = %w[client_a client_b client_a_forged client_a_expired
            client_a_wrong_san].freeze
          PHASES = %w[baseline uncertainty recovery].freeze

          class Error < StandardError; end

          class CaseResult
            attr_reader :id, :kind, :name, :passed, :observation

            def initialize(id:, kind:, name:, passed:, observation: nil)
              @id = id
              @kind = kind
              @name = name
              @passed = passed
              @observation = observation
            end

            def to_h
              {"id" => @id, "kind" => @kind, "name" => @name, "passed" => @passed}
            end

            def detail
              to_h.merge("observation" => @observation)
            end
          end

          # The closed manifest: fixture-declared endpoints, credential
          # references and the request template. Credential references
          # only — never secret bytes — and every referenced tree must
          # follow the exact provisioning layout.
          class Manifest
            attr_reader :invocation_id, :authorities, :credentials, :request

            def self.load_file(path)
              stat = File.lstat(path)
              unless stat.uid.zero? && (stat.mode & 0o022).zero?
                raise Error,
                  "the boundary scenario manifest must be root-owned and not group/world-writable: #{path}"
              end

              new(JSON.parse(File.read(path)))
            rescue JSON::ParserError, SystemCallError, IOError
              raise Error, "the boundary scenario manifest is unavailable or malformed: #{path}"
            end

            def initialize(value)
              unless value.is_a?(Hash) && (value.keys - MANIFEST_FIELDS).empty? &&
                  MANIFEST_FIELDS.all? { |field| !value[field].nil? }
                raise Error, "#{SCHEMA} rejects unknown fields and nulls"
              end
              unless value.fetch("schema") == SCHEMA && value.fetch("scenario") == SCENARIO_NAME
                raise Error, "the boundary scenario requires #{SCHEMA} scenario #{SCENARIO_NAME}"
              end
              @invocation_id = value.fetch("invocation_id").to_s
              if @invocation_id.empty? || @invocation_id.length > 128 ||
                  !@invocation_id.match?(/\A[A-Za-z0-9][A-Za-z0-9._:-]*\z/)
                raise Error, "the manifest invocation_id is not a bounded token"
              end

              @authorities = parse_authorities(value.fetch("authorities"))
              @credentials = parse_credentials(value.fetch("credentials"))
              @request = parse_request(value.fetch("request"))
              freeze
            end

            def endpoint(key)
              @authorities.fetch(key).fetch("endpoint")
            end

            def project(key)
              @authorities.fetch(key).fetch("project")
            end

            # The exact provisioning layout of every referenced
            # credential tree, verified before any connection (the
            # negative-case material follows the same rules as the
            # positive identities).
            def verify_credential_paths!
              @credentials.each do |name, entry|
                policy = Ace::Hitl::Lifecycle::CredentialPathPolicy.new(
                  service_user: entry.fetch("service_user"),
                  service_group: entry.fetch("service_group"))
                policy.verify_credential_tree!(entry.fetch("tls_client_credential"))
              rescue Ace::Hitl::Lifecycle::Error => e
                raise Error, "manifest credential #{name}: #{e.message}"
              end
              self
            end

            private

            def parse_authorities(value)
              unless value.is_a?(Hash) && value.keys.sort == %w[A B]
                raise Error, "the manifest declares exactly authorities A and B (got #{value.keys.sort.inspect})"
              end

              value.to_h do |key, authority|
                unless authority.is_a?(Hash) && (authority.keys - AUTHORITY_FIELDS).empty? &&
                    AUTHORITY_FIELDS.all? { |field| authority[field].is_a?(String) && !authority[field].empty? }
                  raise Error, "manifest authority #{key} is malformed"
                end
                Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(authority.fetch("endpoint"))
                [key, authority.freeze]
              end
            end

            def parse_credentials(value)
              unless value.is_a?(Hash) && (REQUIRED_CREDENTIALS - value.keys).empty?
                raise Error, "the manifest requires credentials: #{REQUIRED_CREDENTIALS.join(", ")}"
              end

              value.to_h do |name, entry|
                unless entry.is_a?(Hash) && (entry.keys - CREDENTIAL_FIELDS).empty? &&
                    entry["service_user"].is_a?(String) && entry["service_group"].is_a?(String) &&
                    !entry["service_user"].empty? && !entry["service_group"].empty?
                  raise Error, "manifest credential #{name} is malformed"
                end
                credential = Ace::Hitl::Lifecycle::TlsCredentials.parse_client(
                  entry.fetch("tls_client_credential"))
                expected_project = project(name == "client_b" ? "B" : "A")
                pinned = Ace::Hitl::Lifecycle::TlsCredentials.uri_san_project(
                  credential.fetch("expected_server_uri_san"))
                unless pinned == expected_project
                  raise Error,
                    "manifest credential #{name} pins project #{pinned.inspect}, not #{expected_project.inspect}"
                end

                [name, entry.merge("tls_client_credential" => credential).freeze]
              end
            end

            def parse_request(value)
              unless value.is_a?(Hash) && (value.keys - REQUEST_FIELDS).empty? &&
                  REQUEST_FIELDS.all? { |field| value[field].is_a?(String) && !value[field].empty? } &&
                  value.values.all? { |item| item.bytesize <= 256 }
                raise Error, "manifest request template is malformed"
              end

              value.freeze
            end
          end

          # The production client seam: the verified Hermes TLS client.
          class ProductionClientFactory
            def call(endpoint:, credential:)
              Transport::TlsClient.new(endpoint: endpoint, credential: credential)
            end
          end

          # The raw-socket probes of the credential negative cases.
          class ProductionProbe
            def initialize(endpoint:)
              @dns, @port = Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(endpoint)
            end

            # A TLS attempt WITHOUT a client certificate must be refused
            # by the authority before any lifecycle byte.
            def handshake_without_certificate(ca_file)
              ssl = probe_handshake(ca_file)
              ssl&.close
              :accepted
            rescue SystemCallError, IOError, OpenSSL::SSL::SSLError, Ace::Hitl::Lifecycle::TransportError
              :refused
            end

            # A cleartext client must never observe lifecycle bytes and
            # must never be served: the authority closes the connection.
            def cleartext_roundtrip
              socket = TCPSocket.new(@dns, @port)
              socket.write("GET / HTTP/1.0\r\n\r\n")
              socket.wait_readable(5)
              echoed = socket.read_nonblock(4096, exception: false)
              socket.close
              echoed.is_a?(String) && !echoed.empty? ? :echoed : :refused
            rescue SystemCallError, IOError, EOFError
              :refused
            end

            private

            def probe_handshake(ca_file)
              context = OpenSSL::SSL::SSLContext.new
              context.set_params
              context.min_version = OpenSSL::SSL::TLS1_3_VERSION
              context.max_version = OpenSSL::SSL::TLS1_3_VERSION
              context.ca_file = ca_file
              context.verify_mode = OpenSSL::SSL::VERIFY_PEER
              tcp = TCPSocket.new(@dns, @port)
              ssl = OpenSSL::SSL::SSLSocket.new(tcp, context)
              ssl.sync_close = true
              ssl.hostname = @dns
              deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10.0
              loop do
                result = ssl.connect_nonblock(exception: false)
                return ssl if result.is_a?(OpenSSL::SSL::SSLSocket)

                remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
                raise Ace::Hitl::Lifecycle::TransportError, "probe handshake deadline" if remaining <= 0
                IO.select([ssl], [ssl], nil, remaining) or
                  raise Ace::Hitl::Lifecycle::TransportError, "probe handshake deadline"
              end
            rescue SystemCallError, IOError, OpenSSL::SSL::SSLError, Ace::Hitl::Lifecycle::TransportError
              ssl.close rescue nil
              raise
            end
          end

          attr_reader :manifest

          def initialize(manifest:, client_factory:, probe_factory:, clock: -> { Time.now.utc },
            id_generator: -> { SecureRandom.hex(12) })
            @manifest = manifest
            @client_factory = client_factory
            @probe_factory = probe_factory
            @clock = clock
            @id_generator = id_generator
          end

          # @return [Hash] the closed receipt printed as ONE stdout JSON line
          def run(phase, report: nil)
            raise Error, "unknown scenario phase #{phase.inspect}" unless PHASES.include?(phase)

            cases = send("run_#{phase}_phase")
            receipt = {
              "type" => RECEIPT_TYPE,
              "version" => 1,
              "invocation_id" => @manifest.invocation_id,
              "scenario" => SCENARIO_NAME,
              "phase" => phase,
              "receipt_id" => @id_generator.call,
              "passed" => cases.all? { |result| result.passed },
              "positive_cases" => cases.count { |result| result.kind == "positive" },
              "negative_cases" => cases.count { |result| result.kind == "negative" },
              "cases" => cases.map(&:to_h),
              "completed_at" => @clock.call.utc.iso8601
            }
            write_report(report, cases, receipt) if report
            receipt
          end

          private

          def client(name)
            entry = @manifest.credentials.fetch(name)
            @client_factory.call(endpoint: @manifest.endpoint("A"),
              credential: entry.fetch("tls_client_credential"))
          end

          def cross_client(name, authority_key)
            entry = @manifest.credentials.fetch(name)
            @client_factory.call(endpoint: @manifest.endpoint(authority_key),
              credential: entry.fetch("tls_client_credential"))
          end

          def request_id(authority_key, suffix)
            "#{@manifest.request.fetch('attempt_prefix')}-#{authority_key.downcase}#{suffix}"
          end

          # ---- baseline: credentials + isolation + bidirectional flows ----

          def run_baseline_phase
            results = []
            client_a = client("client_a")
            client_b = cross_client("client_b", "B")
            id_a = request_id("A", "1")
            id_b = request_id("B", "1")
            create_asks(results, client_a, client_b, id_a, id_b)
            before = facts_of(client_a, id_a)
            run_credential_negatives(results)
            run_isolation_negatives(results, client_a, client_b, id_b)
            results << negative("N09", "ask facts unchanged across every credential refusal") do
              facts_of(client_a, id_a) == before
            end
            run_positive_flows(results, client_a, client_b, id_a, id_b)
            results
          end

          def create_asks(results, client_a, client_b, id_a, id_b)
            template = @manifest.request
            ask = lambda do |instance, id, key, ordinal|
              instance.create(
                "id" => id, "assignment" => template.fetch("assignment"),
                "attempt" => "#{template.fetch('attempt_prefix')}-#{key.downcase}#{ordinal}",
                "harness" => template.fetch("harness"), "question" => template.fetch("question"),
                "plan" => template.fetch("question"), "ace_hitl_id" => "nh0a-boundary-scenario",
                "project" => @manifest.project(key), "kind" => "text")
            end
            results << positive("P0", "asks are created through each crossing") do
              ask.call(client_a, id_a, "A", "1").fetch("id") == id_a &&
                ask.call(client_b, id_b, "B", "1").fetch("id") == id_b
            end
          end

          # Every credential negative must refuse BEFORE store access:
          # no frame is served, no identity is borrowed, no fallback
          # transport is attempted.
          def run_credential_negatives(results)
            credentials = @manifest.credentials
            results << negative("N01", "missing client certificate") do
              probe = @probe_factory.call(endpoint: @manifest.endpoint("A"))
              probe.handshake_without_certificate(
                credentials.fetch("client_a").fetch("tls_client_credential").fetch("ca_file")) == :refused
            end
            [["N02", "forged issuing CA", "client_a_forged"],
             ["N03", "expired client certificate", "client_a_expired"],
             ["N04", "wrong client URI SAN", "client_a_wrong_san"]].each do |id, name, credential_name|
              results << negative(id, name) { refused? { client(credential_name) } }
            end
            results << negative("N05", "wrong configured server fingerprint pin") do
              entry = credentials.fetch("client_a")
              mutated = entry.fetch("tls_client_credential").merge(
                "expected_server_certificate_sha256" => "0" * 64)
              refused? do
                @client_factory.call(endpoint: @manifest.endpoint("A"), credential: mutated)
              end
            end
            results << negative("N06", "project B client certificate against authority A") do
              refused? { cross_client("client_b", "A") }
            end
            results << negative("N07", "authority A identity against authority B endpoint") do
              refused? { cross_client("client_a", "B") }
            end
            results << negative("N08", "cleartext client receives no lifecycle bytes") do
              probe = @probe_factory.call(endpoint: @manifest.endpoint("A"))
              probe.cleartext_roundtrip == :refused
            end
          end

          def run_isolation_negatives(results, client_a, client_b, id_b)
            results << negative("N10", "cross-authority correlation is refused in both directions") do
              a_reads_b = refused_read?(client_a, id_b)
              a_answers_b = begin
                client_a.deliver(id_b, "forged-answer")
                false
              rescue Ace::Hitl::Lifecycle::Error
                true
              end
              b_reads_a = refused_read?(client_b, request_id("A", "1"))
              a_reads_b && a_answers_b && b_reads_a
            end
            results << negative("N11", "the isolated ask is unchanged after cross-authority attempts") do
              facts = client_b.read(id_b)
              facts.fetch("state") == "created"
            end
          end

          def run_positive_flows(results, client_a, client_b, id_a, id_b)
            template = @manifest.request
            [["P1", client_a, id_a, "A"], ["P2", client_b, id_b, "B"]].each do |id, instance, request, key|
              results << positive(id, "bidirectional ask/reply/pending flow through authority #{key}") do
                pending_ids = instance.pending(project: @manifest.project(key)).map { |facts| facts.fetch("id") }
                delivered = instance.deliver(request, template.fetch("answer"))
                consumed = instance.consume(request, timeout: 5)
                pending_ids.include?(request) && delivered["delivered"] == true &&
                  consumed.fetch("answer") == template.fetch("answer") &&
                  instance.read(request).fetch("state") != "created"
              end
            end
            results << positive("P3", "instruction (proposal) surface crosses the boundary") do
              history = client_a.proposal_history(project: @manifest.project("A"))
              due = client_a.proposal_due(project: @manifest.project("A"))
              history.is_a?(Hash) && history["items"].is_a?(Array) &&
                due.is_a?(Hash) && due["items"].is_a?(Array)
            end
          end

          # ---- uncertainty: abrupt disconnect mid-flight, client restart ----

          def run_uncertainty_phase
            results = []
            template = @manifest.request
            id = request_id("A", "u1")
            results << positive("U1", "ask is durable before the in-flight answer") do
              client("client_a").create(
                "id" => id, "assignment" => template.fetch("assignment"),
                "attempt" => "#{template.fetch('attempt_prefix')}-au1",
                "harness" => template.fetch("harness"), "question" => template.fetch("question"),
                "plan" => template.fetch("question"), "ace_hitl_id" => "nh0a-boundary-scenario",
                "project" => @manifest.project("A"), "kind" => "text").fetch("id") == id
            end
            results << positive("U2", "an answer cut off mid-flight reconciles without replay") do
              abandon_mid_flight(id, template.fetch("answer"))
              # Client restart: a fresh client observes the canonical state.
              restarted = client("client_a")
              if restarted.read(id).fetch("state") == "created"
                restarted.deliver(id, template.fetch("answer"))
              end
              restarted.consume(id, timeout: 5).fetch("answer") == template.fetch("answer")
            end
            results
          end

          # Sends the deliver frame and closes the TLS connection before
          # the response: the outcome is uncertain at the client by
          # construction, never silently replayed.
          def abandon_mid_flight(id, answer)
            frame = Ace::Hitl::Lifecycle::Protocol.encode_request("deliver",
              {"id" => id, "answer" => answer})
            transport = client("client_a")
            ssl = transport.send(:connect!)
            begin
              deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
              transport.send(:write_frame!, ssl, frame, deadline)
            ensure
              ssl.close rescue nil
            end
          rescue StandardError
            # The abrupt close is the point; any transport-level noise is
            # the expected outcome, never a scenario failure.
            nil
          end

          # ---- recovery: after fixture service/proxy restarts ----

          def run_recovery_phase
            results = []
            template = @manifest.request
            id = request_id("A", "u1")
            results << positive("R1", "canonical receipts reconcile after independent restarts") do
              instance = client("client_a")
              instance.deliver(id, template.fetch("answer")) if instance.read(id).fetch("state") == "created"
              instance.consume(id, timeout: 5).fetch("answer") == template.fetch("answer")
            end
            results << positive("R2", "pending surface is healthy after restarts") do
              client("client_a").pending(project: @manifest.project("A")).is_a?(Array)
            end
            results
          end

          # ---- helpers ----

          def refused?
            yield.ping
            false
          rescue Ace::Hitl::Lifecycle::TransportError
            true
          end

          def refused_read?(instance, id)
            instance.read(id)
            false
          rescue Ace::Hitl::Lifecycle::Error
            true
          end

          def facts_of(client, id)
            client.read(id)
          rescue Ace::Hitl::Lifecycle::Error
            nil
          end

          def positive(id, name)
            outcome = yield
            CaseResult.new(id: id, kind: "positive", name: name, passed: outcome == true,
              observation: outcome == true ? nil : "expected outcome not observed")
          rescue StandardError => e
            CaseResult.new(id: id, kind: "positive", name: name, passed: false,
              observation: "#{e.class}")
          end

          def negative(id, name)
            outcome = yield
            CaseResult.new(id: id, kind: "negative", name: name, passed: outcome == true,
              observation: outcome == true ? nil : "refusal not observed")
          rescue StandardError => e
            CaseResult.new(id: id, kind: "negative", name: name, passed: false,
              observation: e.class.to_s)
          end

          # The report keeps bounded, sanitized per-case observations
          # (classes and fixed strings only — never keys, tokens or
          # message bodies).
          def write_report(path, cases, receipt)
            File.open(path, "a") do |file|
              file.flock(File::LOCK_EX)
              cases.each do |result|
                file.puts(JSON.generate({"receipt_id" => receipt.fetch("receipt_id"),
                  "case" => result.detail, "completed_at" => receipt.fetch("completed_at")}))
              end
              file.fsync
            end
          end
        end
      end
    end
  end
end
