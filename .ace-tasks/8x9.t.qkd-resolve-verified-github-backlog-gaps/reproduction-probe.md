# Reproduction probe source

Baseline: aaf6dfec4c2d93c8f0b1c7cd53b6a07c68942659. Analysis-only script; no provider calls. Save into a temporary directory and invoke with BUNDLE_GEMFILE pointing at this checkout and its compatible Ruby.

```ruby
require 'bundler/setup'
require 'ace/llm/providers/cli'
require 'ace/review'
require 'ace/review/atoms/campaign_contract'
require 'ace/review/molecules/diff_scope'
require 'tmpdir'
require 'fileutils'

client = Ace::LLM::Providers::CLI::AgyClient.new(**{'max_prompt_length' => 400_000})
begin
  client.send(:build_agy_command, 'x' * 354_141, {})
  puts 'AGY: accepted'
rescue => e
  puts "AGY: #{e.class}: #{e.message}"
end

Dir.mktmpdir('ace-local-scope-probe') do |root|
  system('git', '-C', root, 'init', '-q', exception: true)
  %w[keep.rb excluded.rb].each { |name| File.write(File.join(root, name), "old\n") }
  system('git', '-C', root, 'add', '.', exception: true)
  system('git', '-C', root, '-c', 'user.name=Probe', '-c', 'user.email=probe@example.invalid', 'commit', '-qm', 'baseline', exception: true)
  %w[keep.rb excluded.rb].each { |name| File.write(File.join(root, name), "new\n") }
  preset_dir = File.join(root, '.ace/review/presets')
  FileUtils.mkdir_p(preset_dir)
  File.write(File.join(preset_dir, 'triage.yml'), <<~YAML)
    description: Local scope reproduction
    strategy: deliberately-unsupported-strategy
    file_patterns:
      exclude: [excluded.rb]
    models: [codex:gpt-6-sol]
    instructions:
      bundle:
        sections:
          instructions:
            content: Review for defects
  YAML
  Dir.chdir(root) do
    preset = Ace::Review::Molecules::PresetManager.new(project_root: root).resolve_preset('triage')
    puts "STRATEGY: resolved key present=#{preset.key?(:strategy)}"
    manager = Ace::Review::Organisms::ReviewManager.new(project_root: root)
    result = manager.execute_review(preset: 'triage', subject: 'diff:HEAD', auto_execute: false, no_feedback: true)
    puts "LOCAL: success=#{result[:success]} error=#{result[:error]}"
    prompts = Dir.glob(File.join(root, '.ace-local/review/**/*.prompt.md')).map { |path| File.read(path) }.join
    puts "LOCAL: prompt contains excluded diff=#{prompts.include?('diff --git a/excluded.rb b/excluded.rb')}"
  end
end

diff = "diff --git a/assets/photo.png b/assets/photo.png\nindex 1234567..7654321 100644\nBinary files a/assets/photo.png and b/assets/photo.png differ\n"
selection = Ace::Review::Molecules::DiffScope.select(diff)
head = 'a' * 40
base = 'b' * 40
manifest = selection.fetch(:manifest).merge(head_sha: head, base_branch_sha: base, pr_file_inventory_verified: true)
begin
  Ace::Review::Atoms::CampaignContract.full_pr_coverage!(manifest, head: head, base: base)
  puts "BINARY: full_pr_coverage! accepts binary-only manifest; binaries=#{manifest[:binary_files].inspect}"
rescue => e
  puts "BINARY: #{e.class}: #{e.message}"
end
```
