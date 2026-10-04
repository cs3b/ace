# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/native_runtime_fixture"
require "shellwords"

# Native infrastructure helpers are reused, but the product commands below
# run only from a built-gem installation, in a disposable Git repository.
class InstalledHerdrWorkflowsTest < AceAssignTestCase
  include NativeRuntimeFixture

  def test_installed_callback_work_on_and_preserving_prune
    @installed = ENV["ACE_INSTALLED_HOME"]
    skip "requires explicit ACE_INSTALLED_HOME fixture override" unless @installed
    @scratch = Dir.mktmpdir("ace-installed-native", "/tmp")
    keys = %w[HERDR_CONFIG_PATH HERDR_SOCKET_PATH HERDR_SESSION HERDR_PANE HERDR_WORKSPACE_ID
      XDG_CONFIG_HOME TMUX ACE_TMUX_SESSION GEM_HOME GEM_PATH RUBYOPT RUBYLIB BUNDLE_GEMFILE
      BUNDLE_BIN_PATH PROJECT_ROOT_PATH PATH ACE_RUNTIME]
    keys += ENV.keys.grep(/\ABUNDLE/)
    @fixture_env = keys.uniq.to_h { |key| [key, ENV[key]] }
    ENV.keys.grep(/\ABUNDLE/).each { |key| ENV.delete(key) }
    %w[TMUX ACE_TMUX_SESSION RUBYOPT RUBYLIB BUNDLE_GEMFILE BUNDLE_BIN_PATH PROJECT_ROOT_PATH].each { |key| ENV.delete(key) }
    ENV["GEM_HOME"] = ENV["GEM_PATH"] = @installed
    ENV["ACE_RUNTIME"] = "herdr"
    bin = File.join(@scratch, "bin")
    FileUtils.mkdir_p(bin)
    ENV["PATH"] = "#{bin}:#{@installed}/bin:#{ENV.fetch('PATH')}"
    @callback = File.join(@scratch, "callback")
    File.write(File.join(bin, "codex"), <<~SH)
      #!/bin/bash
      if [[ "$1" == "--version" ]]; then echo 'codex fixture'; exit 0; fi
      ace-runtime send --pane "$ACE_ASSIGN_CALLBACK_PANE" --cmd #{Shellwords.escape("printf 'callback\\n' >> #{@callback}")}
    SH
    File.chmod(0o755, File.join(bin, "codex"))
    start_herdr
    @repo = File.join(@scratch, "repo")
    FileUtils.mkdir_p(@repo)
    native("git", "-C", @repo, "init", "-q", "-b", "main")
    native("git", "-C", @repo, "config", "user.email", "native-test@example.com")
    native("git", "-C", @repo, "config", "user.name", "Native acceptance")
    native("git", "-C", @repo, "config", "commit.gpgsign", "false")
    write(".gitignore", ".ace-local/\n.ace-wt/\n_current\n")
    write(".ace/git/worktree.yml", <<~YAML)
      git:
        worktree:
          terminal: true
          task:
            auto_push_task: false
            auto_setup_upstream: false
            auto_commit_task: false
            auto_mark_in_progress: false
          hooks:
            after_create: []
    YAML
    write(".ace/overseer/config.yml", "runtime: herdr\ndefault_assign_preset: native-proof\nwindow_presets: {}\n")
    write(".ace/assign/presets/native-proof.yml", <<~YAML)
      name: native-proof
      parameters:
        taskrefs:
          required: true
          type: array
      steps:
        - name: verify
          instructions: Verify native fixture.
    YAML
    @task = ".ace-tasks/8zz.t.aaa-native-proof/8zz.t.aaa-native-proof.s.md"
    write(@task, "---\nid: 8zz.t.aaa\nstatus: pending\npriority: medium\ntitle: Native proof\n---\n\n# Native proof\n")
    write("fork.yml", "session:\n  name: callback-proof\nsteps:\n  - name: delegated\n    context: fork\n    instructions: Verify callback.\n    sub_steps:\n      - name: child\n        instructions: Verify child.\n")
    commit("fixture")
    created = installed("ace-assign", "create", "--yaml", "fork.yml", cwd: @repo)
    assignment = created[/\(([a-z0-9]+)\)/, 1]
    refute_nil assignment, created
    installed("ace-assign", "fork-run", "--assignment", "#{assignment}@010", "--launch-mode", "herdr",
      "--provider", "codex:gpt", "--callback", cwd: @repo)
    begin
      wait_until { File.file?(@callback) }
    rescue Timeout::Error
      panes = JSON.parse(native("herdr", "pane", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID")))
      ids = panes.fetch("result").fetch("panes").map { |pane| pane.fetch("pane_id") }
      buffers = ids.map { |id| native("herdr", "pane", "read", id, "--lines", "20") }
      flunk "installed callback did not arrive: #{buffers.join('\n')}"
    end
    sleep 0.2
    assert_equal "callback\n", File.read(@callback), "callback must submit exactly once to the actual caller shell"
    work_on = installed("ace-overseer", "work-on", "--task", "8zz.t.aaa", cwd: @repo)
    wt = work_on[/Worktree (?:created at|exists at) (.+)$/, 1]
    assert wt && File.directory?(wt), "work-on did not create the native worktree: #{work_on}"
    tabs = JSON.parse(native("herdr", "tab", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID"))).fetch("result")
    label = Ace::Runtime.sanitize_name(File.basename(wt))
    tab = tabs.fetch("tabs").find { |entry| entry["label"] == label }
    refute_nil tab, "work-on did not open a native task tab: #{tabs}"
    panes = JSON.parse(native("herdr", "pane", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID"))).fetch("result").fetch("panes")
    pane = panes.find { |entry| entry["tab_id"] == tab.fetch("tab_id") }
    refute_nil pane
    assert_equal File.realpath(wt), File.realpath(pane.fetch("cwd")), "native task pane has wrong root"
    installed("ace-assign", "start", cwd: wt)
    installed("ace-assign", "finish", "--message", "native fixture complete", cwd: wt)
    write(@task, File.read(File.join(@repo, @task)).sub("status: pending", "status: done"))
    commit("task complete")
    # Unpreserved branch must survive public pruning with its native tab.
    File.write(File.join(wt, "feature.txt"), "preserve me\n")
    native("git", "-C", wt, "add", "feature.txt")
    native("git", "-C", wt, "commit", "-q", "-m", "unmerged work")
    branch = native("git", "-C", wt, "branch", "--show-current").strip
    blocked, status = installed_result("ace-overseer", "prune", File.basename(wt), "--yes", cwd: @repo)
    refute status.success?, blocked
    assert File.directory?(wt), "unsafe prune removed unpreserved work"
    assert_includes blocked, "preservation"
    native("git", "-C", @repo, "merge", "--no-ff", "--no-edit", "-q", branch)
    installed("ace-overseer", "prune", File.basename(wt), "--yes", cwd: @repo)
    refute File.exist?(wt), "accepted prune retained worktree"
    remaining = native("herdr", "tab", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID"))
    refute_includes remaining, tab.fetch("tab_id"), "accepted prune retained native task tab"
    assert_includes File.read(File.join(@repo, "feature.txt")), "preserve me"
    verify_installed_pointer_reuse
    verify_native_materialization_failure
    verify_installed_demo_directives
    verify_installed_worktree_terminal
  ensure
    Process.kill("TERM", -@pid) rescue nil if @pid
    Process.wait(@pid) rescue nil if @pid
    @log&.close
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
    @fixture_env&.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    Ace::Runtime.reset_registry!
  end

  def write(path, contents)
    target = File.join(@repo, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, contents)
  end

  def commit(message)
    native("git", "-C", @repo, "add", "-A")
    native("git", "-C", @repo, "commit", "-q", "-m", message)
  end

  def installed_result(executable, *args, cwd:)
    Open3.capture2e(File.join(@installed, "bin", executable), *args, chdir: cwd)
  end

  def installed(executable, *args, cwd:)
    output, status = installed_result(executable, *args, cwd: cwd)
    assert status.success?, "installed #{executable} #{args.join(' ')} failed: #{output}"
    output
  end

  def installed_ruby(script, home: @installed)
    output, status = Open3.capture2e({"GEM_HOME" => home, "GEM_PATH" => home}, Gem.ruby, "-e", script, chdir: @repo)
    assert status.success?, "installed Ruby runtime check failed: #{output}"
    output.strip
  end

  def verify_installed_pointer_reuse
    created = JSON.parse(native("herdr", "tab", "create", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID"),
      "--label", "installed-foreign", "--cwd", @repo))
    tab = created.fetch("result").fetch("tab").fetch("tab_id")
    prepare = <<~RUBY
      require "ace/runtime"
      adapter = Ace::Runtime.resolve("herdr")
      puts adapter.prepare_pane(window: #{tab.inspect})
    RUBY
    old = installed_ruby(prepare)
    digest = Digest::SHA256.hexdigest("#{ENV.fetch('HERDR_WORKSPACE_ID')}\0installed-foreign")
    path = File.join(Dir.home, ".ace/local/herdr/runtime-tabs", "#{digest}.json")
    assert_equal %w[id prepared_pane], JSON.parse(File.read(path)).keys.sort
    native("herdr", "pane", "close", old)
    replacement = installed_ruby(prepare)
    refute_equal old, replacement
    assert_equal %w[id prepared_pane], JSON.parse(File.read(path)).keys.sort
    assert_equal replacement, installed_ruby(prepare), "installed fresh process did not reuse pointer"
    adopted = installed_ruby(<<~RUBY)
      require "ace/runtime"
      adapter = Ace::Runtime.resolve("herdr")
      raise "wrong native tab" unless adapter.ensure_window(name: "installed-foreign", root: #{@repo.inspect}) == #{tab.inspect}
      begin
        adapter.ensure_window(name: "installed-foreign", root: #{@scratch.inspect})
        raise "conflicting root accepted"
      rescue Ace::Runtime::Error
      end
      puts adapter.prepare_pane(window: #{tab.inspect})
    RUBY
    assert_equal replacement, adopted
  end

  def verify_native_materialization_failure
    write(".ace/herdr/tabs/invalid-agent.yml", "label: invalid-agent\npanes:\n  - label: shell\n    agent:\n      kind: invalid-native-fixture\n      name: invalid\n")
    before = JSON.parse(native("herdr", "tab", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID")))
      .fetch("result").fetch("tabs").map { |tab| tab.fetch("tab_id") }
    stdout, stderr, status = Open3.capture3(File.join(@installed, "bin/ace-herdr"), "tab", "invalid-agent",
      "--workspace", ENV.fetch("HERDR_WORKSPACE_ID"), "--cwd", @repo, chdir: @repo)
    refute status.success?, "invalid agent materialization reported success"
    assert_empty stdout.strip
    assert_includes stderr, "invalid-native-fixture"
    refute_includes stderr, ".rb:", "ordinary installed CLI error printed a backtrace"
    after = JSON.parse(native("herdr", "tab", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID")))
      .fetch("result").fetch("tabs").map { |tab| tab.fetch("tab_id") }
    assert_equal 1, (after - before).length, "CLI must retain the actual newly created failed tab"
    assert_empty before - after, "failed materialization closed an existing native tab"
  end

  def verify_installed_demo_directives
    marker = File.join(@scratch, "demo-send")
    installed_ruby(<<~RUBY, home: File.join(File.dirname(@installed), "ace-demo"))
      require "ace/demo"
      executor = Ace::Demo::Molecules::RuntimeDirectiveExecutor.new(runtime: "herdr")
      executor.execute("tmux" => {"action" => "wait", "for" => "pane-exists", "pane" => #{ENV.fetch('HERDR_PANE').inspect}, "timeout" => 2})
      executor.execute("tmux" => {"action" => "send", "pane" => #{ENV.fetch('HERDR_PANE').inspect}, "command" => #{"printf demo > #{marker}".inspect}})
    RUBY
    wait_until { File.file?(marker) }
    assert_equal "demo", File.read(marker)
  end

  def verify_installed_worktree_terminal
    path = File.join(@repo, ".ace-wt/native-extra")
    installed("ace-git-worktree", "create", "native-extra", "--path", path, cwd: @repo)
    assert File.directory?(path)
    tabs = JSON.parse(native("herdr", "tab", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID")))
      .fetch("result").fetch("tabs")
    tab = tabs.find { |entry| entry["label"] == "native-extra" }
    refute_nil tab, "installed worktree creation did not open its native terminal"
    panes = JSON.parse(native("herdr", "pane", "list", "--workspace", ENV.fetch("HERDR_WORKSPACE_ID")))
      .fetch("result").fetch("panes")
    pane = panes.find { |entry| entry["tab_id"] == tab.fetch("tab_id") }
    refute_nil pane
    assert_equal File.realpath(path), File.realpath(pane.fetch("cwd"))
  end
end
