# frozen_string_literal: true

require "delegate"
require "json"
require "socket"
require "openssl"
require "securerandom"
require "time"
require "etc"
require "ace/hitl/lifecycle"

module Ace
  module Hitl
    module Hermes
      module Boundary
        # The nh0-A source scenario (spec 8xa.t.nh0): the acceptance
        # harness the host lab-config gad.8/gad.b fixture contract
        # executes against the REAL disposable Incus proxies.
        #
        # Identity and binding are never fabricated here:
        # - asks are created ONLY through the supported mechanism — a
        #   local worker actor creating via the authority's Unix
        #   boundary, where the serve-path binding
        #   (Providers::Lab::AssignmentBinding →
        #   AttemptCoordinator#with_verified_attempt) verifies the
        #   assignment/attempt against the REAL Assign state under the
        #   kernel requester identity. The TLS crossing never creates
        #   asks and never supplies requester identity.
        # - the certificate identity (`urn:ace:hitl:<project>:
        #   hermes-client`) maps ONLY to the Hermes transport role
        #   (pending/deliver observation); the requester of record is
        #   the local worker actor, mapped through kernel peer
        #   credentials exactly as production maps it.
        # - the invocation-bound `nh0_real_incus_acceptance` receipt is
        #   produced by the host fixture and VERIFIED in-slice by
        #   AcceptanceReceipt; a loopback-only or mocked run can never
        #   substitute for it.
        class Scenario
          SCHEMA = "ace.hitl.boundary.scenario/v1"
          SCENARIO_NAME = "nh0-a-v1"
          RECEIPT_TYPE = "nh0_a_source_scenario"
          MANIFEST_FIELDS = %w[schema invocation_id scenario authorities credentials asks payload].freeze
          AUTHORITY_FIELDS = %w[endpoint project].freeze
          CREDENTIAL_FIELDS = %w[tls_client_credential service_user service_group].freeze
          ASK_FIELDS = %w[socket service_uid worker_user assignment attempt].freeze
          PAYLOAD_FIELDS = %w[question harness answer].freeze
          REQUIRED_CREDENTIALS = %w[client_a client_b client_a_forged client_a_expired
            client_a_wrong_san].freeze
          PHASES = %w[baseline uncertainty recovery].freeze
          AUTHORITIES = %w[A B].freeze

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
          # references, and the GENUINE ask bindings the fixture
          # provisioned from real Assign state (assignment/attempt ids
          # the serve-path binding verifies at ask time — invented ids
          # fail the ask, never pass the scenario). Credential
          # references only — never secret bytes.
          class Manifest
            attr_reader :invocation_id, :authorities, :credentials, :asks, :payload

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
              @asks = parse_asks(value.fetch("asks"))
              @payload = parse_payload(value.fetch("payload"))
              freeze
            end

            def endpoint(key)
              @authorities.fetch(key).fetch("endpoint")
            end

            def project(key)
              @authorities.fetch(key).fetch("project")
            end

            def ask(key)
              @asks.fetch(key)
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
              unless value.is_a?(Hash) && value.keys.sort == AUTHORITIES
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

            # One GENUINE ask binding per authority: the assignment and
            # attempt are fixture-declared ids from real Assign state;
            # the ask phase proves them through the serve-path binding.
            def parse_asks(value)
              unless value.is_a?(Hash) && value.keys.sort == AUTHORITIES
                raise Error, "the manifest declares asks exactly for authorities A and B"
              end

              value.to_h do |key, ask|
                unless ask.is_a?(Hash) && (ask.keys - ASK_FIELDS).empty? &&
                    ASK_FIELDS.all? { |field| !ask[field].nil? && !ask[field].to_s.empty? } &&
                    ask["socket"].is_a?(String) && File.absolute_path?(ask["socket"]) &&
                    ask["service_uid"].is_a?(Integer) && ask["service_uid"] >= 0 &&
                    ask["worker_user"].is_a?(String) &&
                    ask["worker_user"].match?(/\A[a-z_][a-z0-9_-]{0,31}\z/) &&
                    ask["assignment"].is_a?(String) && ask["assignment"].match?(/\A[A-Za-z0-9_-]{1,128}\z/) &&
                    ask["attempt"].is_a?(String) && ask["attempt"].match?(/\A[A-Za-z0-9_-]{1,128}\z/)
                  raise Error, "manifest ask #{key} is malformed"
                end

                [key, ask.freeze]
              end
            end

            def parse_payload(value)
              unless value.is_a?(Hash) && (value.keys - PAYLOAD_FIELDS).empty? &&
                  PAYLOAD_FIELDS.all? { |field| value[field].is_a?(String) && !value[field].empty? } &&
                  value.values.all? { |item| item.bytesize <= 256 }
                raise Error, "manifest ask payload is malformed"
              end

              value.freeze
            end
          end

          # The durable handoff between the local worker ask steps and
          # the host TLS phases: REAL created request ids only, written
          # by the ask step after a binding-verified create.
          class State
            SCHEMA = "ace.hitl.boundary.state/v1"
            FIELDS = %w[schema asks uncertainty settle].freeze

            attr_reader :path

            def self.load(path)
              value = JSON.parse(File.read(path))
              unless value.is_a?(Hash) && (value.keys - FIELDS).empty? &&
                  value.fetch("schema") == SCHEMA && value["asks"].is_a?(Hash)
                raise Error, "the boundary state file is malformed: #{path}"
              end
              value["asks"].each do |key, entry|
                unless entry.is_a?(Hash) && entry["request_id"].is_a?(String) &&
                    entry["request_id"].match?(/\A[A-Za-z0-9_-]{6,64}\z/)
                  raise Error, "the boundary state ask #{key} has no genuine request id"
                end
              end
              new(path, value)
            rescue JSON::ParserError, SystemCallError, IOError
              raise Error, "the boundary state file is unavailable: #{path}"
            end

            def self.empty(path)
              state = new(path, {"schema" => SCHEMA, "asks" => {}, "uncertainty" => {}, "settle" => {}})
              state.write_update
              state
            end

            def initialize(path, value)
              @path = path
              @value = value
            end

            def request_id(key)
              @value.dig("asks", key.to_s, "request_id")
            end

            def uncertainty_request_id
              @value.dig("uncertainty", "request_id")
            end

            def write_update
              temporary = "#{@path}.#{Process.pid}.tmp"
              File.write(temporary, JSON.generate(@value))
              File.rename(temporary, @path)
              self
            end

            def record_request(key, request_id)
              (@value["asks"][key.to_s] ||= {})["request_id"] = request_id
              write_update
            end

            def record_uncertainty(request_id)
              @value["uncertainty"] = {"request_id" => request_id}
              write_update
            end

            def record_settle(key, consumed:, answer_matches:)
              (@value["settle"][key.to_s] ||= {}).merge!(
                "consumed" => consumed, "answer_matches" => answer_matches)
              write_update
            end
          end

          # The invocation-bound acceptance receipt of the host fixture
          # (spec 8xa.t.nh0): the closed schema the gad.8/gad.b fixture
          # produces on stdout and the nh0 source task verifies before
          # accepting the handoff. All objects reject unknown fields and
          # nulls; counts carry the spec minimums; timestamps are
          # RFC 3339.
          class AcceptanceReceipt
            TYPE = "nh0_real_incus_acceptance"
            VERSION = 1
            TOP_FIELDS = %w[type version invocation_id scenario ace_head lab_config_head
              provision test teardown evidence_sha256].freeze
            PROVISION_FIELDS = %w[instance_id project_ids proxy_configuration_sha256
              credential_layout_sha256 server_certificate_sha256s client_certificate_sha256s
              completed_at].freeze
            TEST_FIELDS = %w[command receipt_ids passed positive_cases negative_cases
              completed_at].freeze
            TEARDOWN_FIELDS = %w[services_stopped proxy_devices_removed firewall_removed
              instance_destroyed credential_files_removed completed_at].freeze
            FINGERPRINT = /\A[0-9a-f]{64}\z/
            HEAD = /\A[0-9a-f]{40}\z/
            RFC3339 = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/

            attr_reader :value

            def self.parse(value)
              new(value)
            end

            def self.load_file(path)
              new(JSON.parse(File.read(path)))
            rescue JSON::ParserError, SystemCallError, IOError
              raise Error, "the acceptance receipt is unavailable or malformed: #{path}"
            end

            def initialize(value)
              unless value.is_a?(Hash) && (value.keys - TOP_FIELDS).empty? &&
                  TOP_FIELDS.all? { |field| !value[field].nil? }
                raise Error, "#{TYPE} rejects unknown fields and nulls"
              end
              unless value.fetch("type") == TYPE && value.fetch("version") == VERSION
                raise Error, "the acceptance receipt requires #{TYPE} version #{VERSION}"
              end
              @value = value
              validate_scalar!("invocation_id", bounded_token: true)
              validate_scenario!
              validate_scalar!("ace_head", pattern: HEAD)
              validate_scalar!("lab_config_head", pattern: HEAD)
              validate_scalar!("evidence_sha256", pattern: FINGERPRINT)
              validate_object!("provision", PROVISION_FIELDS)
              validate_object!("test", TEST_FIELDS)
              validate_object!("teardown", TEARDOWN_FIELDS)
              validate_provision!
              validate_test!
              validate_teardown!
              freeze
            end

            # The source-side acceptance: the receipt counts only for
            # THIS exact reviewed head and scenario.
            def verify!(ace_head:, scenario: SCENARIO_NAME)
              unless @value.fetch("ace_head") == ace_head
                raise Error,
                  "the acceptance receipt names head #{@value.fetch('ace_head')}, not #{ace_head}"
              end
              unless @value.fetch("scenario") == scenario
                raise Error, "the acceptance receipt names scenario #{@value.fetch('scenario')}"
              end
              unless @value.dig("test", "passed") == true
                raise Error, "the acceptance receipt test phase did not pass"
              end
              teardown = @value.fetch("teardown")
              incomplete = TEARDOWN_FIELDS.grep(/_removed|_stopped|_destroyed/)
                .select { |field| teardown.fetch(field) != true }
              unless incomplete.empty?
                raise Error, "the acceptance receipt teardown is incomplete: #{incomplete.join(", ")}"
              end

              self
            end

            private

            def validate_scalar!(field, pattern: nil, bounded_token: false)
              scalar = @value.fetch(field)
              ok = if bounded_token
                scalar.is_a?(String) && !scalar.empty? && scalar.length <= 128 &&
                  scalar.match?(/\A[A-Za-z0-9][A-Za-z0-9._:-]*\z/)
              else
                scalar.is_a?(String) && scalar.match?(pattern)
              end
              return if ok

              raise Error, "the acceptance receipt field #{field} is malformed"
            end

            def validate_scenario!
              return if @value.fetch("scenario") == SCENARIO_NAME

              raise Error, "the acceptance receipt requires scenario #{SCENARIO_NAME}"
            end

            def validate_object!(field, fields)
              object = @value.fetch(field)
              unless object.is_a?(Hash) && (object.keys - fields).empty? &&
                  fields.all? { |name| !object[name].nil? }
                raise Error, "the acceptance receipt #{field} object rejects unknown fields and nulls"
              end
            end

            def validate_provision!
              provision = @value.fetch("provision")
              unless provision["instance_id"].is_a?(String) && !provision["instance_id"].empty?
                raise Error, "the acceptance receipt provision.instance_id is malformed"
              end
              project_ids = provision["project_ids"]
              unless project_ids.is_a?(Array) && project_ids.size == 2 &&
                  project_ids.uniq.size == 2 && project_ids.all? { |entry| entry.is_a?(String) && !entry.empty? }
                raise Error, "the acceptance receipt provision.project_ids must be two distinct strings"
              end
              %w[server_certificate_sha256s client_certificate_sha256s].each do |field|
                list = provision[field]
                unless list.is_a?(Array) && list.size == 2 && list.uniq.size == 2 &&
                    list.all? { |entry| entry.is_a?(String) && entry.match?(FINGERPRINT) }
                  raise Error,
                    "the acceptance receipt provision.#{field} must be two distinct 64-hex strings"
                end
              end
              validate_time!(provision, "completed_at", "provision.completed_at")
            end

            def validate_test!
              test = @value.fetch("test")
              unless test["command"].is_a?(String) && !test["command"].empty?
                raise Error, "the acceptance receipt test.command is malformed"
              end
              receipts = test["receipt_ids"]
              unless receipts.is_a?(Array) && !receipts.empty? && receipts.uniq.size == receipts.size &&
                  receipts.all? { |entry| entry.is_a?(String) && !entry.empty? }
                raise Error, "the acceptance receipt test.receipt_ids must be distinct non-empty strings"
              end
              unless test["passed"] == true || test["passed"] == false
                raise Error, "the acceptance receipt test.passed must be a boolean"
              end
              unless test["positive_cases"].is_a?(Integer) && test["positive_cases"] >= 1 &&
                  test["negative_cases"].is_a?(Integer) && test["negative_cases"] >= 9
                raise Error,
                  "the acceptance receipt counts must be integers with positive_cases >= 1 and negative_cases >= 9"
              end
              validate_time!(test, "completed_at", "test.completed_at")
            end

            def validate_teardown!
              teardown = @value.fetch("teardown")
              TEARDOWN_FIELDS.grep(/_removed|_stopped|_destroyed/).each do |field|
                unless teardown[field] == true || teardown[field] == false
                  raise Error, "the acceptance receipt teardown.#{field} must be a boolean"
                end
              end
              validate_time!(teardown, "completed_at", "teardown.completed_at")
            end

            def validate_time!(object, field, label = field)
              return if object.fetch(field).is_a?(String) && object.fetch(field).match?(RFC3339)

              raise Error, "the acceptance receipt #{label} must be RFC 3339 date-time"
            end
          end

          # The production client seams: the verified Hermes TLS client
          # and the raw-socket boundary probes used by the credential
          # negative cases.
          class ProductionClientFactory
            def call(endpoint:, credential:)
              Transport::TlsClient.new(endpoint: endpoint, credential: credential)
            end
          end

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
          def run(phase, state:, report: nil)
            raise Error, "unknown scenario phase #{phase.inspect}" unless PHASES.include?(phase)
            raise Error, "the #{phase} phase requires the ask state file" if state.nil?

            cases = send("run_#{phase}_phase", state)
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

          # ---- baseline: real asks through the crossing + credentials + isolation ----

          def run_baseline_phase(state)
            results = []
            client_a = client("client_a")
            client_b = cross_client("client_b", "B")
            id_a = genuine_ask!(results, state, "A", client_a, "P0")
            id_b = genuine_ask!(results, state, "B", client_b, "P1")
            before_a = id_a ? facts_of(client_a, id_a) : nil
            run_credential_negatives(results)
            run_isolation_negatives(results, client_a, client_b, id_b, state)
            if id_a && before_a
              results << negative("N09", "ask facts unchanged across every credential refusal") do
                facts_of(client_a, id_a) == before_a
              end
            end
            run_positive_flows(results, client_a, client_b, id_a, id_b)
            results
          end

          # P0/P1: the fixture-provided, binding-verified ask of each
          # authority is visible through its crossing. A missing or
          # unprovisioned ask is a FAILED case, never a fabricated pass.
          def genuine_ask!(results, state, key, instance, case_id)
            request_id = state.request_id(key)
            project = @manifest.project(key)
            results << positive(case_id,
              "the genuine #{key} ask (binding-verified by the fixture ask step) is visible through the crossing") do
              raise Error, "the fixture ask state has no #{key} request (ask step did not run)" unless request_id

              pending_ids = instance.pending(project: project).map { |facts| facts.fetch("id") }
              pending_ids.include?(request_id) &&
                instance.read(request_id).fetch("project") == project
            end
            request_id
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

          def run_isolation_negatives(results, client_a, client_b, id_b, state)
            results << negative("N10", "the other authority's project is unreachable in both directions") do
              a_pends_b = begin
                client_a.pending(project: @manifest.project("B"))
                false
              rescue Ace::Hitl::Lifecycle::Error
                true
              end
              b_pends_a = begin
                client_b.pending(project: @manifest.project("A"))
                false
              rescue Ace::Hitl::Lifecycle::Error
                true
              end
              a_reads_b = id_b ? refused_read?(client_a, id_b) : true
              a_pends_b && b_pends_a && a_reads_b
            end
            results << negative("N11", "the isolated genuine ask is unchanged after cross-authority attempts") do
              request_id = state.request_id("B")
              raise Error, "no B ask in state" unless request_id

              client_b.read(request_id).fetch("state") == "created"
            end
          end

          def run_positive_flows(results, client_a, client_b, id_a, id_b)
            [["P2", client_a, id_a, "A"], ["P3", client_b, id_b, "B"]].each do |id, instance, request, key|
              results << positive(id,
                "the genuine #{key} ask is answered through the crossing (transport role)") do
                raise Error, "no #{key} ask in state" unless request

                delivered = instance.deliver(request, @manifest.payload.fetch("answer"))
                facts = instance.read(request)
                delivered["delivered"] == true && facts.fetch("state") == "answer-delivered"
              end
            end
            results << positive("P4", "instruction (proposal) surface crosses the boundary") do
              history = client_a.proposal_history(project: @manifest.project("A"))
              due = client_a.proposal_due(project: @manifest.project("A"))
              history.is_a?(Hash) && history["items"].is_a?(Array) &&
                due.is_a?(Hash) && due["items"].is_a?(Array)
            end
          end

          # ---- uncertainty: abrupt disconnect mid-flight, client restart ----

          def run_uncertainty_phase(state)
            results = []
            id = state.uncertainty_request_id
            results << positive("U1", "the genuine uncertainty ask is durable before the in-flight answer") do
              raise Error, "the fixture ask state has no uncertainty request (ask step did not run)" unless id

              client("client_a").read(id).fetch("state") == "created"
            end
            results << positive("U2", "an answer cut off mid-flight reconciles without replay") do
              raise Error, "no uncertainty ask in state" unless id

              abandon_mid_flight(id, @manifest.payload.fetch("answer"))
              # Client restart: a fresh client observes the canonical state.
              restarted = client("client_a")
              if restarted.read(id).fetch("state") == "created"
                restarted.deliver(id, @manifest.payload.fetch("answer"))
              end
              restarted.read(id).fetch("state") == "answer-delivered"
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

          def run_recovery_phase(state)
            results = []
            results << positive("R1", "canonical receipts reconcile after independent restarts") do
              instance = client("client_a")
              id = state.request_id("A")
              uncertainty_id = state.uncertainty_request_id
              raise Error, "no A ask in state" unless id && uncertainty_id

              [id, uncertainty_id].all? do |request_id|
                facts = instance.read(request_id)
                facts.fetch("state") == "answer-delivered"
              end
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
              observation: e.class.to_s)
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
