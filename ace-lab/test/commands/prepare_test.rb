# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class PrepareCommandTest < Minitest::Test
          FakeEntry = Struct.new(:name, :uid, :gid, :dir, keyword_init: true)

          def self_entry(name)
            FakeEntry.new(name: name, uid: Process.uid, gid: Process.gid, dir: "/home/#{name}")
          end

          MANIFEST = <<~YAML
            ---
            schema_version: 1
            machine: lab01
            accounts:
              - username: ace-worker
                role: worker
                create: false
                home: /tmp/prepare-cmd-home/ace-worker
            directories: []
            keys:
              - account: ace-worker
            roles:
              - id: worker
                account: ace-worker
                instructions: wfi://assign/work
          YAML

          def with_manifest(yaml = MANIFEST, lookup: ->(name) { self_entry(name) }, &block)
            home = Dir.mktmpdir("prepare-cmd-home")
            manifest = yaml.gsub("/tmp/prepare-cmd-home", home)
            Ace::Lab::Molecules::GrantResolver.stub :read_verified, manifest do
              organism = Organisms::Prepare.new(
                manifest_path: "/etc/lab/ace-lab/install.yml",
                account_lookup: lookup,
                platform: "linux"
              )
              block.call(Prepare.new(prepare: organism), home)
            end
          ensure
            FileUtils.remove_entry(home) if home
          end

          def test_json_output_matches_report_schema
            with_manifest do |cmd, _home|
              out, = capture_io { cmd.call(format: "json", dry_run: nil, quiet: nil) }

              parsed = JSON.parse(out)
              assert_equal true, parsed["ok"]
              assert_equal "lab01", parsed["machine"]
              assert_equal "exists", parsed["accounts"].first["status"]
              assert_equal "verified", parsed["roles"].first["status"]
              assert_equal %w[accounts directories keys roles],
                parsed.keys - %w[ok dry_run machine manifest]
            end
          end

          def test_table_output_renders_sections_and_items
            with_manifest do |cmd, _home|
              out, = capture_io { cmd.call(format: nil, dry_run: nil, quiet: nil) }

              assert_includes out, "Machine: lab01"
              assert_includes out, "manifest: /etc/lab/ace-lab/install.yml"
              assert_includes out, "Accounts:"
              assert_includes out, "ace-worker"
              assert_includes out, "exists"
              # key rows render a truncated fingerprint (F-5): "SHA256:"
              # plus 20 characters, never the full row-bloating value
              assert_match(/SHA256:[A-Za-z0-9+\/=]{20}…/, out)
              assert_includes out, "Directories:"
              assert_includes out, "(none declared)"
              assert_includes out, "Result: ok"
            end
          end

          def test_missing_manifest_is_a_cli_error_naming_the_path
            Ace::Lab::Molecules::GrantResolver.stub :read_verified, nil do
              cmd = Prepare.new(prepare: Organisms::Prepare.new(platform: "linux"))

              error = assert_raises(Ace::Support::Cli::Error) do
                capture_io { cmd.call(format: nil, dry_run: nil, quiet: nil) }
              end

              assert_match(%r{/etc/lab/ace-lab/install\.yml not found}, error.message)
            end
          end

          def test_failed_items_render_report_then_raise_with_item_list
            with_manifest(lookup: ->(_name) { nil }) do |cmd, _home|
              out, = capture_io do
                error = assert_raises(Ace::Support::Cli::Error) do
                  cmd.call(format: nil, dry_run: nil, quiet: nil)
                end
                assert_match(/prepare failed \(3 item\(s\)\)/, error.message)
                assert_match(%r{accounts/ace-worker: }, error.message)
                assert_match(/does not exist/, error.message)
              end

              # report renders before the failure is raised
              assert_includes out, "Result: FAILED"
            end
          end

          def test_dry_run_exits_zero_on_predicted_conflicts
            with_manifest(lookup: ->(_name) { nil }) do |cmd, _home|
              out, = capture_io { cmd.call(format: nil, dry_run: true, quiet: nil) }

              assert_includes out, "Result: FAILED"
              # no raise — dry-run conflicts are predictions, not execution failures
            end
          end

          def test_quiet_prints_nothing
            with_manifest do |cmd, _home|
              out, = capture_io { cmd.call(format: nil, dry_run: nil, quiet: true) }

              assert_equal "", out
            end
          end

          def test_invalid_format_is_a_usage_error
            with_manifest do |cmd, _home|
              error = assert_raises(Ace::Support::Cli::Error) do
                cmd.call(format: "yaml", dry_run: nil, quiet: nil)
              end

              assert_includes error.message, "table or json"
            end
          end

          def test_output_never_contains_private_key_material
            with_manifest do |cmd, home|
              out, = capture_io { cmd.call(format: "json", dry_run: nil, quiet: nil) }

              private_path = File.join(home, "ace-worker", ".ssh", "id_ed25519")
              assert File.exist?(private_path)
              File.readlines(private_path).each do |line|
                next if line.strip.empty? || line.start_with?("-----")

                refute_includes out, line.strip
              end
              refute_includes out, "OPENSSH PRIVATE KEY"
            end
          end
        end
      end
    end
  end
end
