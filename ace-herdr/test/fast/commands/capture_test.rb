# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class CaptureTest < Minitest::Test
          def setup
            @executor = HerdrTestHelper::FakeExecutor.new
          end

          def test_prints_raw_pane_text_verbatim
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              pane_read: Molecules::ExecutionResult.new(
                stdout: "\n  build succeeded\nexit 0\n\n", stderr: "", success: true, exit_code: 0
              )
            })
            cmd = Capture.new(executor: @executor)

            out, = capture_io do
              cmd.call(pane: "p5", lines: nil, source: nil)
            end

            assert_equal "\n  build succeeded\nexit 0\n\n", out
          end

          def test_defaults_to_recent_source_and_40_lines
            cmd = Capture.new(executor: @executor)

            capture_io { cmd.call(pane: "p5", lines: nil, source: nil) }

            call = @executor.calls_of(:pane_read).first
            assert_equal({pane: "p5", source: "recent", lines: 40}, call[:args])
          end

          def test_passes_visible_source_and_lines
            cmd = Capture.new(executor: @executor)

            capture_io { cmd.call(pane: "p5", lines: 12, source: "visible") }

            call = @executor.calls_of(:pane_read).first
            assert_equal({pane: "p5", source: "visible", lines: 12}, call[:args])
          end

          def test_rejects_unknown_source
            cmd = Capture.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", lines: nil, source: "all")
            end

            assert_match(/visible or recent/, error.message)
          end

          def test_requires_pane
            cmd = Capture.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: nil, lines: nil, source: nil)
            end

            assert_match(/--pane is required/, error.message)
          end

          def test_unknown_pane_surfaces_native_code
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              pane_read: Ace::Herdr::PaneNotFoundError.new("pane_not_found: gone")
            })
            cmd = Capture.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "gone", lines: nil, source: nil)
            end

            assert_match(/pane_not_found/, error.message)
          end
        end
      end
    end
  end
end
