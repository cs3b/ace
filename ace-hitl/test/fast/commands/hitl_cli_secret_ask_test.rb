# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Secret asks (task 8xs.t.pu0.9): the secret flag is explicit at
        # creation, persisted on the case, and propagated to the armed
        # wake request — no title heuristics anywhere.
        class HitlCliSecretAskTest < AceHitlTestCase
          def setup
            Adapters.reset_registry!
            @dir = Dir.mktmpdir
            @root = File.join(@dir, "hitl")
            @config = {"hitl" => {"root_dir" => @root, "machine" => "lab",
              "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}},
              "adapters" => {"routes" => [{"route" => "captain", "adapter" => "fixture",
                                           "recipients" => ["captain"]}]}}}
            Adapters.register(:fixture, ->(_route) do
              adapter = Object.new
              adapter.define_singleton_method(:deliver) do |event:, **|
                Adapters::RouteResult.new(route: "captain", adapter: "fixture",
                  status: :delivered, detail: "fixture")
              end
              adapter
            end)
          end

          def teardown
            Adapters.reset_registry!
            FileUtils.remove_entry(@dir) if @dir
          end

          def test_secret_ask_marks_the_case_and_the_wake_request
            out, = capture_io do
              with_cli_root(@root, config: @config) do
                Ask.new.call(title: "OTP for gem push", to: "captain", kind: "approval",
                  secret: true, quiet: true)
              end
            end
            case_id = out.lines.last.to_s.strip

            case_file = Dir.glob(File.join(@root, "**", "#{case_id}*.md")).first
            content = File.read(case_file)
            assert_match(/^secret: true/, content,
              "the secret flag is explicit at creation, persisted on the case")

            request = JSON.parse(File.read(File.join(@root, "wake-requests", "#{case_id}.json")))
            assert_equal true, request["secret"],
              "the armed wake request carries the secret flag for the bridge"

          end

          def test_normal_ask_carries_no_secret_marking
            out, = capture_io do
              with_cli_root(@root, config: @config) do
                Ask.new.call(title: "Proceed?", to: "captain", quiet: true)
              end
            end
            case_id = out.lines.last.to_s.strip

            case_file = Dir.glob(File.join(@root, "**", "#{case_id}*.md")).first
            refute_match(/^secret: true/, File.read(case_file))

            request = JSON.parse(File.read(File.join(@root, "wake-requests", "#{case_id}.json")))
            refute request["secret"], "a normal ask never marks the request secret"
          end
        end
      end
    end
  end
end
