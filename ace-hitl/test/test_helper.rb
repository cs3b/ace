# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/hitl"
require "fileutils"
require "stringio"

class AceHitlTestCase < AceTestCase
  class StaticScopeResolver
    def initialize(default_scope:, current_worktree_root:, roots_by_scope:)
      @default_scope = default_scope
      @current_worktree_root = current_worktree_root
      @roots_by_scope = roots_by_scope
    end

    def default_scope
      @default_scope
    end

    def effective_scope(requested_scope)
      requested_scope || default_scope
    end

    def current_worktree_root
      @current_worktree_root
    end

    def worktree_roots(scope:)
      @roots_by_scope.fetch(scope, [])
    end
  end

  def run_cli(args)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    exit_code = 0

    begin
      Ace::Hitl::HitlCLI.start(args)
    rescue Ace::Support::Cli::Error => e
      warn e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    {stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code}
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  def with_cli_root(root_dir, config: nil, scope_resolver: nil)
    config ||= {"hitl" => {"root_dir" => root_dir}}
    original_new = Ace::Hitl::Organisms::HitlManager.method(:new)
    Ace::Hitl::Organisms::HitlManager.define_singleton_method(:new) do |**opts|
      original_new.call(
        **opts.merge(root_dir: root_dir, config: config, scope_resolver: scope_resolver).compact
      )
    end
    yield
  ensure
    Ace::Hitl::Organisms::HitlManager.singleton_class.remove_method(:new)
  end

  def with_env(env)
    saved = {}
    env.each { |key, value| saved[key] = ENV[key]; env[key].nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def with_hitl_dir
    Dir.mktmpdir("ace-hitl-test") do |tmpdir|
      yield tmpdir
    end
  end

  def create_hitl_fixture(root_dir, id:, slug:, status: "pending", kind: "clarification",
    tags: [], questions: [], answer: nil, special_folder: nil, extra_frontmatter: {})
    parent = special_folder ? File.join(root_dir, special_folder) : root_dir
    FileUtils.mkdir_p(parent)

    folder_name = "#{id}-#{slug}"
    item_dir = File.join(parent, folder_name)
    FileUtils.mkdir_p(item_dir)

    question_lines = questions.empty? ? "- Need clarification" : questions.map { |q| "- #{q}" }.join("\n")
    answer_text = answer.to_s

    frontmatter_lines = {
      "id" => id,
      "title" => slug.tr("-", " ").capitalize,
      "kind" => kind,
      "status" => status,
      "tags" => "[#{tags.join(", ")}]",
      "questions" => "[#{questions.join(", ")}]",
      "created_at" => "2026-04-01 12:00:00",
      "answered" => !answer.nil? && !answer.empty?
    }.merge(extra_frontmatter).map { |key, value| "#{key}: #{value}" }.join("\n")

    content = <<~CONTENT
      ---
      #{frontmatter_lines}
      ---

      # #{slug.tr("-", " ").capitalize}

      ## Questions

      #{question_lines}

      ## Answer

      #{answer_text}
    CONTENT

    spec_file = File.join(item_dir, "#{folder_name}.hitl.s.md")
    File.write(spec_file, content)
    item_dir
  end

  def with_multi_worktree_roots
    Dir.mktmpdir("ace-hitl-worktrees") do |tmp|
      main_worktree = File.join(tmp, "main")
      task_worktree = File.join(tmp, "task-123")
      FileUtils.mkdir_p([main_worktree, task_worktree])
      yield(main_worktree, task_worktree)
    end
  end
end
