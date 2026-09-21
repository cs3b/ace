# frozen_string_literal: true

require "test_helper"

# Provider-contract parity suite for the Forgejo provider.
# Shares identical assertions with ace-git-github via
# Ace::TestSupport::ProviderContract; fixtures are Forgejo (`fj`, minimal
# style) shaped.
class ForgejoProviderContractTest < AceGitForgejoTestCase
  include Ace::TestSupport::ProviderContract

  SERVER = Ace::Git::ResolvedServer.new(name: "forge-server", provider: :forgejo, url: "https://forgejo.example.com/owner/repo")

  def build_provider(runner)
    Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
  end

  def ok_runner
    @ok_runner ||= scripted_runner(
      "fj version" => {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0},
      "fj auth list" => {success: true, stdout: "forgejo.example.com\n", stderr: "", exit_code: 0},
      "fj --style minimal pr view 25" => {success: true, stdout: pr25_view, stderr: "", exit_code: 0},
      "fj --style minimal pr view 25 commits" => {
        success: true, stdout: "commit fc14c43d3660ac6c133959a6dec29603413f0e8a (+252, -8)\nAuthor: Lab Builder <lab-builder@lab.invalid>\n", stderr: "", exit_code: 0
      },
      "fj --style minimal pr search --state all" => {
        success: true, stdout: "2 pull requests\n#31: Wire status to providers (by lab-builder)\n#25: Ship the provider contract (by lab-builder)\n", stderr: "", exit_code: 0
      },
      "fj --style minimal pr view 31" => {success: true, stdout: pr31_view, stderr: "", exit_code: 0},
      "fj --style minimal pr view 31 commits" => {
        success: true, stdout: "commit a1b2c3d4e5f60718293a4b5c6d7e8f9012345678 (+12, -2)\nAuthor: Lab Builder <lab-builder@lab.invalid>\n", stderr: "", exit_code: 0
      },
      "fj pr view 25 diff" => {
        success: true, stdout: "diff --git a/lib/x.rb b/lib/x.rb\n+new line\n", stderr: "", exit_code: 0
      },
      "fj --style minimal issue view 9" => {success: true, stdout: issue9_view, stderr: "", exit_code: 0},
      "fj --style minimal actions tasks" => {
        success: true, stdout: "2 tasks\n#83 (fc14c43d3660ac6c133959a6dec29603413f0e8a) success test-suite 23s (push): subject\n", stderr: "", exit_code: 0
      },
      "fj --style minimal repo view" => {
        success: true, stdout: "owner/repo\n> Sample repository\nView online at https://forge.example.com/owner/repo\n", stderr: "", exit_code: 0
      }
    )
  end

  def version_fail_runner
    scripted_runner("fj version" => ["fj: command not found", 127])
  end

  def auth_fail_runner
    scripted_runner(
      "fj version" => {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0},
      "fj auth list" => {success: true, stdout: "other-host.example.com\n", stderr: "", exit_code: 0}
    )
  end

  def not_found_runner
    scripted_runner(
      "fj version" => {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0},
      "fj auth list" => {success: true, stdout: "forgejo.example.com\n", stderr: "", exit_code: 0},
      "fj --style minimal pr view 999" => ["error: pull request does not exist", 1]
    )
  end

  def malformed_runner
    scripted_runner(
      "fj version" => {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0},
      "fj auth list" => {success: true, stdout: "forgejo.example.com\n", stderr: "", exit_code: 0},
      "fj --style minimal pr view 25" => {success: true, stdout: "unexpected output shape", stderr: "", exit_code: 0}
    )
  end

  def unreachable_runner
    scripted_runner(
      "fj version" => {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0},
      "fj auth list" => {success: true, stdout: "forgejo.example.com\n", stderr: "", exit_code: 0},
      "fj --style minimal pr view 25" => ["fj: Forgejo request failed with HTTP 502", 1]
    )
  end

  private

  def pr25_view
    <<~TEXT
      Ship the provider contract #25
      By lab-builder - Merged - +252 -8
      From `owner/repo:lab/W675-ace` into `main`
    TEXT
  end

  def pr31_view
    <<~TEXT
      Wire status to providers #31
      By lab-builder - Open - +12 -2
      From `owner/repo:lab/W676-ace` into `main`
    TEXT
  end

  def issue9_view
    <<~TEXT
      Broken diff on detached HEAD #9
      By lab-admin - Open - +0 -0
    TEXT
  end
end
