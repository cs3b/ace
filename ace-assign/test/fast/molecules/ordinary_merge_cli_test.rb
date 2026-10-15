# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/ordinary_merge_fixture"
require "fileutils"
require "json"

module Ace
  module Assign
    module Molecules
      class OrdinaryMergeCliTest < AceAssignTestCase
        include OrdinaryMergeFixture

        def setup
          super
          with_temp_cache do |cache_dir|
            @cache_dir = cache_dir
            @argv_file = File.join(cache_dir, "argv.txt")
            @envelope_file = File.join(cache_dir, "envelope.json")
            @code_file = File.join(cache_dir, "exit-code")
            @binary = File.join(cache_dir, "fake-ace-lab")
            File.write(@binary, <<~SH)
              #!/bin/sh
              printf '%s\\n' "$@" > "#{@argv_file}"
              cat "#{@envelope_file}"
              code=0
              if [ -f "#{@code_file}" ]; then code=$(cat "#{@code_file}"); fi
              exit $code
            SH
            FileUtils.chmod(0o755, @binary)
            File.write(@envelope_file, "")
          end
          @cli = OrdinaryMergeCli.new(binary: @binary)
        end

        def captured_argv
          File.readlines(@argv_file, chomp: true)
        end

        def write_envelope(envelope)
          File.write(@envelope_file, JSON.generate(envelope))
        end

        def request_arguments
          {project: PROJECT, assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY,
           input_path: "/inputs/merge.json", authorization: AUTHORIZATION, request_id: REQUEST_ID}
        end

        def status_arguments
          {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, project: PROJECT,
           assignment: "a1", attempt: "t1", queue_entry: QUEUE_ENTRY, input_digest: HEX64}
        end

        def test_request_uses_only_the_published_closed_argv
          write_envelope({"status" => "ok", "data" => valid_ack(HEX64)})
          envelope = @cli.request(**request_arguments)
          assert_equal "ok", envelope.fetch("status")
          assert_equal ["service", "request", "--mode", "ordinary-merge", "--project", PROJECT,
            "--assignment", "a1", "--attempt", "t1", "--queue-entry", QUEUE_ENTRY,
            "--operation", "merge", "--input", "/inputs/merge.json",
            "--authorization", AUTHORIZATION, "--request-id", REQUEST_ID], captured_argv
        end

        def test_status_uses_only_the_published_closed_argv
          write_envelope({"status" => "ok", "data" => {"schema" => "s", "state" => "pending"}})
          envelope = @cli.status(**status_arguments)
          assert_equal "ok", envelope.fetch("status")
          assert_equal ["service", "status", "--mode", "ordinary-merge", "--reference", REQUEST_REFERENCE,
            "--request", REQUEST_ID, "--project", PROJECT, "--assignment", "a1", "--attempt", "t1",
            "--queue-entry", QUEUE_ENTRY, "--input-digest", HEX64, "--format", "json"], captured_argv
        end

        def test_refusal_envelope_is_returned_even_on_nonzero_exit
          write_envelope({"status" => "error", "error" => valid_refusal("ordinary_merge_provenance_mismatch")})
          File.write(@code_file, "1")
          envelope = @cli.request(**request_arguments)
          assert_equal "error", envelope.fetch("status")
          assert_equal "ordinary_merge_provenance_mismatch", envelope.dig("error", "code")
        end

        def test_unparseable_output_is_a_caller_side_blocker
          File.write(@envelope_file, "<html>gateway error</html>")
          assert_raises(OrdinaryMergeCli::UnavailableError) { @cli.request(**request_arguments) }
          assert_raises(OrdinaryMergeCli::UnavailableError) { @cli.status(**status_arguments) }
        end

        def test_missing_binary_is_a_caller_side_blocker
          cli = OrdinaryMergeCli.new(binary: File.join(@cache_dir, "absent-ace-lab"))
          assert_raises(OrdinaryMergeCli::UnavailableError) { cli.request(**request_arguments) }
        end

        def test_non_envelope_output_is_a_caller_side_blocker
          write_envelope({"result" => "not the maintained envelope"})
          assert_raises(OrdinaryMergeCli::UnavailableError) { @cli.status(**status_arguments) }
        end

        def test_oversized_output_is_a_caller_side_blocker
          write_envelope({"status" => "ok", "data" => {"padding" => "x" * (OrdinaryMergeCli::MAX_OUTPUT_BYTES + 1)}})
          assert_raises(OrdinaryMergeCli::UnavailableError) { @cli.status(**status_arguments) }
        end
      end
    end
  end
end
