# frozen_string_literal: true

require "test_helper"
require "json"
require "ace/handbook/cli"

class Ace::Handbook::CLI::Commands::StatusTest < Minitest::Test
  def test_table_output_uses_collector_renderer
    collector = stub_collector
    command = Ace::Handbook::CLI::Commands::Status.new(collector: collector)

    stdout, = capture_io do
      command.call(provider: "pi", format: "table")
    end

    assert_equal "TABLE OUTPUT\n", stdout
  end

  def test_json_output_includes_canonical_and_provider_sections
    collector = stub_collector
    command = Ace::Handbook::CLI::Commands::Status.new(collector: collector)

    stdout, = capture_io do
      command.call(provider: "pi", format: "json")
    end

    payload = JSON.parse(stdout)
    assert_equal 2, payload.fetch("canonical").fetch("total")
    assert_equal "pi", payload.fetch("providers").first.fetch("provider")
  end

  private

  def stub_collector
    Object.new.tap do |collector|
      collector.define_singleton_method(:collect) do |provider: nil|
        {
          "canonical" => {
            "total" => 2,
            "by_source" => [{ "source" => "ace-task", "count" => 2 }]
          },
          "providers" => [
            {
              "provider" => provider || "pi",
              "enabled" => true,
              "path_type" => "directory",
              "expected" => 2,
              "installed" => 2,
              "in_sync" => 2,
              "outdated" => 0,
              "missing" => 0,
              "extra" => 0,
              "relative_output_dir" => ".pi/skills"
            }
          ]
        }
      end

      collector.define_singleton_method(:to_table) { |_snapshot| "TABLE OUTPUT" }
    end
  end
end
