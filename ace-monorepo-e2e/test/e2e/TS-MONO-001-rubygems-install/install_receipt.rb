#!/usr/bin/env ruby
# frozen_string_literal: true

# Deterministic receipts and exact-version acceptance for TS-MONO-001.
#
# All commands are pure stdlib and must be invoked with the scenario's
# isolated case environment. The runner goals call `receipt`/`activated`/
# `consumer-gemfile`; `verify` produces the machine-readable exact-version
# acceptance artifact; `finalize` (host-side, after a completed pipeline)
# adds the wrapper/pipeline completion gate and a final verdict.

require "fileutils"
require "json"
require "yaml"
require "rubygems/version"

module InstallReceipt
  MANIFEST_SCHEMA_VERSION = 1
  DEFAULT_CONSUMERS = %w[ace-bundle ace-review ace-task].freeze
  ACE_PREFIX = /\Aace-/

  module_function

  # --- manifest -------------------------------------------------------------

  def load_manifest(path)
    data = JSON.parse(File.read(path))
    raise ArgumentError, "manifest must be a JSON object" unless data.is_a?(Hash)
    raise ArgumentError, "unsupported manifest schema_version: #{data["schema_version"].inspect}" unless data["schema_version"] == MANIFEST_SCHEMA_VERSION

    packages = data["packages"]
    raise ArgumentError, "manifest packages must be a nonempty array" unless packages.is_a?(Array) && !packages.empty?

    data
  end

  # --- receipts -------------------------------------------------------------

  # Parse a Bundler lockfile textually: section headers sit at column zero,
  # package entries at a four-space indent under `specs:`.
  def parse_lockfile(path)
    raise ArgumentError, "lockfile is missing: #{path}" unless File.file?(path)

    section = nil
    in_specs = false
    packages = {}
    sections_with_packages = Hash.new { |h, k| h[k] = [] }

    File.foreach(path) do |line|
      if line.match?(/\A[A-Z][A-Z ]*\s*\z/)
        section = line.strip
        in_specs = false
        next
      end
      if line.match?(/\A\s+specs:\s*\z/)
        in_specs = true
        next
      end
      match = line.match(/\A    ([^\s(]+) \(([^)]+)\)/)
      next unless match && in_specs && section

      packages[match[1]] = match[2]
      sections_with_packages[section] << match[1]
    end

    {
      "packages" => packages,
      "sections" => sections_with_packages,
      "path" => path
    }
  end

  # Activated-spec receipt: requires the caller to run this script with the
  # case environment under `bundle exec` (or -rbundler/setup) so
  # Bundler.load resolves against the case's isolated install.
  def activated_receipt
    raise "Bundler is not loaded; run under `bundle exec` or -rbundler/setup" unless defined?(Bundler)

    specs = Bundler.load.specs.select { |spec| spec.name.to_s.match?(ACE_PREFIX) }
    specs.to_h do |spec|
      [spec.name.to_s, {"version" => spec.version.to_s, "path" => spec.full_gem_path.to_s}]
    end
  end

  # Consumer-only Gemfile: pins exactly one consumer gem at its exact
  # manifest version, with no direct ace-git-github entry, so the provider
  # version in the resolved graph can only come from the consumer's
  # published dependency edge.
  def write_consumer_gemfile(manifest_path:, name:, out_path:)
    manifest = load_manifest(manifest_path)
    entry = manifest["packages"].find { |package| package["name"] == name }
    raise ArgumentError, "manifest has no package #{name}" unless entry

    FileUtils.mkdir_p(File.dirname(out_path))
    File.write(out_path, <<~GEMFILE)
      source 'https://rubygems.org'

      gem '#{entry["name"]}', '#{entry["artifact_version"]}'
    GEMFILE
    out_path
  end

  # --- acceptance -----------------------------------------------------------

  # @param mode_dirs [Hash] {"normal" => dir, "full_index" => dir}
  # @option exits [Hash] exit filename per mode, defaults install.exit /
  #   fullindex.exit
  def verify(manifest_path:, mode_dirs:, consumers: DEFAULT_CONSUMERS, exits: {})
    manifest = load_manifest(manifest_path)
    manifest_versions = manifest["packages"].to_h { |package| [package["name"], package] }

    modes = mode_dirs.to_h do |mode, dir|
      exit_file = File.join(dir, exits[mode] || (mode == "full_index" ? "fullindex.exit" : "install.exit"))
      [mode, verify_mode(
        manifest_versions,
        dir: dir,
        exit_file: exit_file
      )]
    end

    consumer_edges = mode_dirs.to_h do |mode, dir|
      [mode, consumers.to_h do |name|
        [name, verify_consumer_edge(
          manifest_versions,
          name: name,
          root: File.join(dir, "consumer", name)
        )]
      end]
    end

    findings = []
    modes.each do |mode, result|
      findings.concat(result["findings"].map { |finding| "#{mode}: #{finding}" })
    end
    consumer_edges.each do |mode, edges|
      edges.each do |name, result|
        findings.concat(result["findings"].map { |finding| "#{mode} consumer #{name}: #{finding}" })
      end
    end

    {
      "schema_version" => MANIFEST_SCHEMA_VERSION,
      "kind" => "exact-version-acceptance",
      "manifest" => {
        "path" => manifest_path,
        "source_sha" => manifest["source_sha"],
        "package_count" => manifest["packages"].size
      },
      "modes" => modes,
      "consumer_edges" => consumer_edges,
      "acceptance" => findings.empty? ? "pass" : "fail",
      "findings" => findings
    }
  end

  def finalize(manifest_path:, mode_dirs:, pipeline_report_dir:, consumers: DEFAULT_CONSUMERS, exits: {}, results_root: nil)
    verdict = verify(manifest_path: manifest_path, mode_dirs: mode_dirs, consumers: consumers, exits: exits)
    pipeline = pipeline_completion(pipeline_report_dir)
    verdict["kind"] = "installation-acceptance"
    verdict["pipeline_completion"] = pipeline
    verdict["findings"].concat(pipeline["findings"])

    reconciliation = reconcile_results(verdict, results_root, exits: exits)
    verdict["results_reconciliation"] = reconciliation
    verdict["findings"].concat(reconciliation["findings"])

    verdict["final"] = (verdict["acceptance"] == "pass" && pipeline["ok"] && reconciliation["ok"]) ? "pass" : "fail"
    verdict
  end

  # The final verdict must agree with the scenario's own artifacts: the
  # TC-004 classification and the runner-side exact-version acceptance.
  def reconcile_results(verdict, results_root, exits: {})
    findings = []
    if results_root.nil?
      return {"ok" => false, "findings" => ["results root is required to reconcile scenario artifacts"]}
    end

    classification_path = File.join(results_root, "results", "tc", "04", "classification.txt")
    recorded = File.file?(classification_path) ? File.read(classification_path).strip : nil
    expected = expected_classification(verdict, exits: exits)
    findings << "classification artifact is missing: #{classification_path}" if recorded.nil? || recorded.empty?
    findings << "recorded classification #{recorded.inspect} disagrees with recomputed #{expected.inspect} (from install exits)" if !recorded.nil? && !recorded.empty? && recorded != expected

    acceptance_path = File.join(results_root, "results", "tc", "04", "exact-version-acceptance.json")
    runner_acceptance = nil
    if File.file?(acceptance_path)
      parsed = JSON.parse(File.read(acceptance_path))
      runner_acceptance = parsed["acceptance"]
      runner_findings = Array(parsed["findings"])
      findings << "runner-side acceptance #{runner_acceptance.inspect} is not pass" unless runner_acceptance == "pass"
      unless runner_findings.empty?
        findings << "runner-side acceptance still carries findings: #{runner_findings.first(5).join('; ')}"
      end
    else
      findings << "exact-version acceptance artifact is missing: #{acceptance_path}"
    end

    {
      "ok" => findings.empty?,
      "recorded_classification" => recorded,
      "expected_classification" => expected,
      "runner_acceptance" => runner_acceptance,
      "findings" => findings
    }
  end

  def expected_classification(verdict, exits: {})
    normal = verdict.dig("modes", "normal", "exit")
    full_index = verdict.dig("modes", "full_index", "exit")
    if normal == 0
      "SAFE"
    elsif full_index == 0
      "LAG_DETECTED"
    else
      "METADATA_BROKEN"
    end
  end

  def pipeline_completion(report_dir)
    metadata_path = File.join(report_dir, "metadata.yml")
    unless File.file?(metadata_path)
      return {"ok" => false, "findings" => ["pipeline metadata.yml is missing: #{metadata_path}"]}
    end

    metadata = YAML.safe_load_file(metadata_path, permitted_classes: [Date])
    status = metadata["status"]
    uncertain = metadata["uncertain_execution"] == true
    findings = []
    findings << "pipeline status is #{status.inspect}, not pass" unless status == "pass"
    findings << "pipeline marked uncertain_execution; side effects must not be replayed" if uncertain
    {
      "ok" => findings.empty?,
      "status" => status,
      "uncertain_execution" => uncertain,
      "findings" => findings
    }
  end

  # --- per-mode checks --------------------------------------------------------

  def verify_mode(manifest_versions, dir:, exit_file:)
    findings = []
    lockfile_path = File.join(dir, "Gemfile.lock")
    receipt_path = File.join(dir, "install-receipt.json")

    exit_code = read_exit(exit_file)
    findings << "install exit evidence is missing or non-numeric: #{exit_file}" if exit_code.nil?
    findings << "install did not succeed (exit #{exit_code.inspect}); receipts may be stale" if exit_code && exit_code != 0

    lockfile = begin
      parse_lockfile(lockfile_path)
    rescue ArgumentError => e
      findings << e.message
      nil
    end

    receipt = begin
      read_receipt(receipt_path)
    rescue ArgumentError => e
      findings << e.message
      nil
    end

    isolation_dirs = [File.join(dir, ".gem"), File.join(dir, ".bundle")].map { |path| File.expand_path(path) }
    package_states = {}

    if lockfile
      lockfile["sections"].each do |section, _names|
        unless %w[GEM].include?(section)
          findings << "lockfile resolves #{section} sources; only registry sources are acceptable"
        end
      end

      lockfile["packages"].each do |name, version|
        next unless version.match?(/\A[0-9a-f]{40}\z/)

        findings << "lockfile entry #{name} looks like a source revision, not a released version"
      end
    end

    manifest_versions.each do |name, entry|
      state = {
        "manifest_version" => entry["artifact_version"],
        "lockfile_version" => lockfile && lockfile["packages"][name],
        "activated_version" => receipt && receipt.dig(name, "version"),
        "activated_path" => receipt && receipt.dig(name, "path"),
        "supersedes" => entry["supersedes"] || []
      }
      state["findings"] = mode_entry_findings(state, name, isolation_dirs)
      package_states[name] = state
      findings.concat(state["findings"])
    end

    {
      "dir" => dir,
      "exit" => exit_code,
      "packages" => package_states,
      "findings" => findings.uniq
    }
  end

  def mode_entry_findings(state, name, isolation_dirs)
    findings = []
    if state["lockfile_version"].nil?
      findings << "#{name} missing from lockfile"
    elsif state["lockfile_version"] != state["manifest_version"]
      findings << "#{name} lockfile resolved #{state["lockfile_version"]}, manifest requires #{state["manifest_version"]}"
    end

    if state["activated_version"].nil?
      findings << "#{name} missing from activated receipt"
    elsif state["activated_version"] != state["manifest_version"]
      findings << "#{name} activated #{state["activated_version"]}, manifest requires #{state["manifest_version"]}"
    end

    if state["activated_path"].nil? || state["activated_path"].to_s.empty?
      findings << "#{name} activated receipt records no gem path"
    elsif !under_any?(state["activated_path"], isolation_dirs)
      findings << "#{name} loaded from #{state["activated_path"]} outside the isolated gem directories"
    end

    state["supersedes"].each do |old_version|
      if [state["lockfile_version"], state["activated_version"]].include?(old_version)
        findings << "#{name} #{old_version} is superseded by #{state["manifest_version"]} but still present"
      end
    end

    findings
  end

  def verify_consumer_edge(manifest_versions, name:, root:)
    findings = []
    gemfile_path = File.join(root, "Gemfile")
    lockfile_path = File.join(root, "Gemfile.lock")
    receipt_path = File.join(root, "install-receipt.json")
    exit_file = File.join(root, "install.exit")

    provider_entry = manifest_versions["ace-git-github"]
    if provider_entry.nil?
      findings << "manifest has no ace-git-github entry"
      return {"root" => root, "ok" => false, "findings" => findings}
    end

    gemfile = File.file?(gemfile_path) ? File.read(gemfile_path) : nil
    if gemfile.nil?
      findings << "consumer Gemfile is missing: #{gemfile_path}"
    elsif gemfile.match?(/gem ['"]ace-git-github['"]/)
      findings << "consumer Gemfile must not reference ace-git-github directly"
    else
      gem_entries = gemfile.scan(/^\s*gem\s+['"]([^'"]+)['"]/).flatten
      unless gem_entries == [name]
        findings << "consumer Gemfile must name exactly the consumer #{name} as its only gem, got #{gem_entries.inspect}"
      end
    end

    exit_code = read_exit(exit_file)
    findings << "consumer install exit evidence is missing or non-numeric: #{exit_file}" if exit_code.nil?
    findings << "consumer install did not succeed (exit #{exit_code.inspect})" if exit_code && exit_code != 0

    lockfile = begin
      parse_lockfile(lockfile_path)
    rescue ArgumentError => e
      findings << e.message
      nil
    end

    receipt = begin
      read_receipt(receipt_path)
    rescue ArgumentError => e
      findings << e.message
      nil
    end

    isolation_dirs = [File.join(root, ".gem"), File.join(root, ".bundle")].map { |path| File.expand_path(path) }
    consumer_version = lockfile && lockfile["packages"][name]
    if consumer_version.nil?
      findings << "#{name} missing from consumer lockfile"
    elsif consumer_version != manifest_versions[name]&.dig("artifact_version")
      findings << "#{name} consumer resolved #{consumer_version}, manifest requires #{manifest_versions[name]&.dig("artifact_version")}"
    end

    consumer_activated = receipt && receipt.dig(name, "version")
    if consumer_activated.nil?
      findings << "#{name} missing from consumer activated receipt"
    elsif consumer_activated != manifest_versions[name]&.dig("artifact_version")
      findings << "#{name} consumer activated #{consumer_activated}, manifest requires #{manifest_versions[name]&.dig("artifact_version")}"
    end

    provider_version = lockfile && lockfile["packages"]["ace-git-github"]
    if provider_version.nil?
      findings << "ace-git-github not reached through #{name} dependency edge"
    elsif provider_version != provider_entry["artifact_version"]
      findings << "ace-git-github resolved #{provider_version} through #{name}, manifest requires #{provider_entry["artifact_version"]}"
    end

    # The provider must come from the consumer's own published dependency
    # declaration, not from an unrelated Gemfile entry: the consumer's
    # lockfile spec must declare ace-git-github as a dependency.
    if lockfile && provider_version && !lockfile_spec_declares_provider?(lockfile, name)
      findings << "#{name} lockfile spec does not declare ace-git-github as a dependency"
    end

    provider_activated = receipt && receipt.dig("ace-git-github", "version")
    if provider_activated.nil?
      findings << "ace-git-github missing from consumer activated receipt"
    elsif provider_activated != provider_entry["artifact_version"]
      findings << "ace-git-github activated #{provider_activated} through #{name}, manifest requires #{provider_entry["artifact_version"]}"
    end

    [name, "ace-git-github"].each do |gem_name|
      gem_path = receipt && receipt.dig(gem_name, "path")
      if gem_path.nil? || gem_path.to_s.empty?
        findings << "#{gem_name} consumer activated receipt records no gem path"
      elsif !under_any?(gem_path, isolation_dirs)
        findings << "#{gem_name} loaded from #{gem_path} outside the isolated consumer directories"
      end
    end

    {"root" => root, "ok" => findings.empty?, "findings" => findings.uniq}
  end

  # In a lockfile, a package's dependency declarations are the six-space
  # indented lines following its four-space `name (version)` entry.
  def lockfile_spec_declares_provider?(lockfile, name)
    content = File.read(lockfile["path"])
    spec_header = /^    #{Regexp.escape(name)} \([^\n]+\)\n/
    match = content.match(spec_header)
    return false unless match

    content[match.end(0)..].each_line do |line|
      break unless line.start_with?("      ")

      return true if line.match?(/\A\s+ace-git-github \(/)
    end
    false
  end

  def read_receipt(path)
    raise ArgumentError, "activated receipt is missing: #{path}" unless File.file?(path)

    receipt = JSON.parse(File.read(path))
    raise ArgumentError, "activated receipt must be a JSON object: #{path}" unless receipt.is_a?(Hash)

    packages = receipt["packages"]
    raise ArgumentError, "activated receipt has no packages object: #{path}" unless packages.is_a?(Hash)

    packages
  rescue JSON::ParserError => e
    raise ArgumentError, "activated receipt is not valid JSON: #{path} (#{e.message})"
  end

  def read_exit(path)
    return nil unless File.file?(path)

    Integer(File.read(path).strip, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def under_any?(path, dirs)
    expanded = real_path(path)
    dirs.any? do |dir|
      expanded.start_with?(real_path(dir) + File::SEPARATOR)
    end
  end

  # Symlink-resolving expansion: /tmp vs /private/tmp on macOS must not
  # split otherwise-identical isolation prefixes. Paths may point into
  # directories that do not exist (negative fixtures), so resolve the
  # closest existing ancestor and append the unmatched remainder.
  def real_path(path)
    candidate = File.expand_path(path)
    remainder = []
    loop do
      begin
        return normalize_real(File.join(File.realpath(candidate), remainder))
      rescue Errno::ENOENT
        remainder.unshift(File.basename(candidate))
        parent = File.dirname(candidate)
        return candidate if parent == candidate

        candidate = parent
      end
    end
  end

  def normalize_real(resolved)
    resolved.sub(%r{/+\z}, "")
  end
end

if $PROGRAM_NAME == __FILE__
  require "optparse"

  def build_parser
    OptionParser.new do |opts|
      opts.banner = "Usage: install_receipt.rb <command> [options]"
      opts.separator "Commands: receipt, activated, consumer-gemfile, verify, finalize"
    end
  end

  command = ARGV.shift
  options = {}

  case command
  when "receipt"
    OptionParser.new do |opts|
      opts.on("--lockfile PATH") { |value| options[:lockfile] = value }
      opts.on("--out PATH") { |value| options[:out] = value }
    end.parse!
    lockfile = InstallReceipt.parse_lockfile(options[:lockfile])
    File.write(options[:out], JSON.pretty_generate({
      "kind" => "lockfile-receipt",
      "path" => lockfile["path"],
      "packages" => lockfile["packages"].select { |name, _version| name.match?(InstallReceipt::ACE_PREFIX) }
    }))
  when "activated"
    OptionParser.new do |opts|
      opts.on("--out PATH") { |value| options[:out] = value }
    end.parse!
    File.write(options[:out], JSON.pretty_generate({
      "kind" => "activated-receipt",
      "packages" => InstallReceipt.activated_receipt
    }))
  when "consumer-gemfile"
    OptionParser.new do |opts|
      opts.on("--manifest PATH") { |value| options[:manifest] = value }
      opts.on("--name NAME") { |value| options[:name] = value }
      opts.on("--out PATH") { |value| options[:out] = value }
    end.parse!
    InstallReceipt.write_consumer_gemfile(manifest_path: options[:manifest], name: options[:name], out_path: options[:out])
  when "verify"
    OptionParser.new do |opts|
      opts.on("--manifest PATH") { |value| options[:manifest] = value }
      opts.on("--normal DIR") { |value| options[:normal] = value }
      opts.on("--full-index DIR") { |value| options[:full_index] = value }
      opts.on("--out PATH") { |value| options[:out] = value }
    end.parse!
    verdict = InstallReceipt.verify(
      manifest_path: options[:manifest],
      mode_dirs: {"normal" => options[:normal], "full_index" => options[:full_index]}
    )
    File.write(options[:out], JSON.pretty_generate(verdict))
  when "finalize"
    OptionParser.new do |opts|
      opts.on("--manifest PATH") { |value| options[:manifest] = value }
      opts.on("--normal DIR") { |value| options[:normal] = value }
      opts.on("--full-index DIR") { |value| options[:full_index] = value }
      opts.on("--pipeline-report DIR") { |value| options[:pipeline_report] = value }
      opts.on("--results-root DIR") { |value| options[:results_root] = value }
      opts.on("--out PATH") { |value| options[:out] = value }
    end.parse!
    verdict = InstallReceipt.finalize(
      manifest_path: options[:manifest],
      mode_dirs: {"normal" => options[:normal], "full_index" => options[:full_index]},
      pipeline_report_dir: options[:pipeline_report],
      results_root: options[:results_root]
    )
    File.write(options[:out], JSON.pretty_generate(verdict))
    exit(verdict["final"] == "pass" ? 0 : 1)
  else
    warn build_parser.to_s
    warn "Unknown command: #{command.inspect}"
    exit 2
  end
end
