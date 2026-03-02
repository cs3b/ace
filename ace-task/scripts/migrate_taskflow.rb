#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time migration: .ace-taskflow → .ace-tasks (B36TS IDs)
#
# Migrates:
#   - v0.9.0 active tasks (non-archive) → .ace-tasks/
#   - v0.9.0 archived tasks             → .ace-tasks/_archive/
#   - _backlog tasks                     → .ace-tasks/_maybe/
#
# Usage:
#   ruby ace-task/scripts/migrate_taskflow.rb --dry-run   # Preview mapping
#   ruby ace-task/scripts/migrate_taskflow.rb              # Execute migration

require "bundler/setup"
require "ace/b36ts"
require "ace/task"
require "ace/support/items"
require "fileutils"

module MigrateTaskflow
  PROJECT_ROOT = File.expand_path("../..", __dir__)
  TASKFLOW_ROOT = File.join(PROJECT_ROOT, ".ace-taskflow")
  TASKS_ROOT = File.join(PROJECT_ROOT, ".ace-tasks")

  ACTIVE_DIR = File.join(TASKFLOW_ROOT, "v.0.9.0", "tasks")
  ARCHIVE_DIR = File.join(TASKFLOW_ROOT, "v.0.9.0", "tasks", "_archive")
  BACKLOG_DIR = File.join(TASKFLOW_ROOT, "_backlog", "tasks")

  # Anchor time for synthetic B36TS IDs
  ANCHOR_TIME = Time.utc(2025, 1, 1)

  # Subtask character alphabet: a-z then 0-9 (36 chars max)
  SUBTASK_CHARS = (("a".."z").to_a + ("0".."9").to_a).freeze

  # Extra asset directories to copy into new task folders (keyed by old_id)
  EXTRA_ASSETS = [
    { old_id: "backlog+task.214",
      src: File.join(BACKLOG_DIR, "214-skills-refactor", "codemods"),
      dirname: "codemods" },
    { old_id: "v.0.9.0+task.256",
      src: File.join(BACKLOG_DIR, "269-task-local-scheduler", "jobs"),
      dirname: "jobs" }
  ].freeze

  # Frontmatter fields explicitly carried over from old format
  EXTRA_FIELDS = %w[type deferred deferred_reason supersedes blocked_by note needs_review].freeze

  # Status normalization map for non-standard archive statuses
  STATUS_MAP = {
    "pass" => "done",
    "fail" => "cancelled",
    "active" => "in-progress"
  }.freeze

  # Shortcuts for library utilities
  FP = Ace::Support::Items::Atoms::FrontmatterParser
  FS = Ace::Support::Items::Atoms::FrontmatterSerializer
  TIF = Ace::Task::Atoms::TaskIdFormatter
  SS = Ace::Support::Items::Atoms::SlugSanitizer
  DPP = Ace::Support::Items::Atoms::DatePartitionPath

  # Parsed source task record
  ParsedTask = Struct.new(
    :source_path, :old_id,
    :frontmatter, :body, :title,
    :subtask_num,       # nil for parents, Integer for subtasks
    :parent_old_id,     # full old_id of parent (from frontmatter or inferred)
    :destination,       # :active, :archive, or :backlog
    :promoted,          # true if orphaned subtask promoted to standalone
    keyword_init: true
  ) do
    def parent?
      subtask_num.nil? || promoted
    end
  end

  class Migrator
    attr_reader :dry_run, :tasks, :parent_tasks, :subtask_tasks,
                :id_map, :promoted_tasks, :overflow_tasks

    def initialize(dry_run: false)
      @dry_run = dry_run
      @tasks = []
      @id_map = {}           # old_id => new b36ts id
      @promoted_tasks = []   # orphaned subtasks promoted to parent
      @overflow_tasks = []   # subtasks exceeding 36-char limit
    end

    def run
      puts "=== ace-taskflow → ace-task Migration ==="
      puts dry_run ? "Mode: DRY RUN (no files written)" : "Mode: EXECUTE"
      puts

      scan_sources
      detect_orphans_and_overflow
      classify_tasks
      generate_id_map
      print_summary
      print_mapping_table unless dry_run # too large for dry-run, show counts only

      unless dry_run
        check_conflicts
        write_tasks
        copy_extra_assets
        verify
      end

      puts "\nDone! Migrated #{id_map.size} tasks."
    end

    private

    # ── Step 1: Scan all source files ──────────────────────────────────────

    def scan_sources
      puts "Step 1: Scanning source files..."

      # Active (non-archive) v0.9.0 tasks
      Dir.glob(File.join(ACTIVE_DIR, "**", "*.s.md")).each do |path|
        next if path.include?("/_archive/")
        parse_source(path, :active)
      end

      # Archived v0.9.0 tasks
      Dir.glob(File.join(ARCHIVE_DIR, "**", "*.s.md")).each do |path|
        parse_source(path, :archive)
      end

      # Backlog tasks
      Dir.glob(File.join(BACKLOG_DIR, "**", "*.s.md")).each do |path|
        parse_source(path, :backlog)
      end

      puts "  Found #{tasks.size} task spec files"
      puts "    Active: #{tasks.count { |t| t.destination == :active }}"
      puts "    Archive: #{tasks.count { |t| t.destination == :archive }}"
      puts "    Backlog: #{tasks.count { |t| t.destination == :backlog }}"
    end

    def parse_source(path, destination)
      content = File.read(path)
      fm, body = FP.parse(content)

      old_id = fm["id"].to_s
      return if old_id.empty? # skip files without an id

      title = extract_title(body)
      subtask_num = extract_subtask_num(old_id)
      parent_old_id = fm["parent"]&.to_s

      # Infer parent old_id from task id if not explicit in frontmatter
      if subtask_num && !parent_old_id
        parent_old_id = old_id.sub(/\.\d+$/, "")
      end

      # Handle .00 parent alias (e.g., v.0.9.0+task.211.00 → parent 211)
      if subtask_num&.zero?
        old_id = old_id.sub(/\.0+$/, "")
        subtask_num = nil
        parent_old_id = nil
      end

      tasks << ParsedTask.new(
        source_path: path,
        old_id: old_id,
        frontmatter: fm,
        body: body,
        title: title,
        subtask_num: subtask_num,
        parent_old_id: parent_old_id,
        destination: destination,
        promoted: false
      )
    end

    def extract_title(body)
      body.each_line do |line|
        return line.sub(/^#\s+/, "").strip if line.match?(/^#\s+/)
      end
      "untitled"
    end

    def extract_subtask_num(old_id)
      # Extract the numeric part after +task. (e.g., "286.01" from "v.0.9.0+task.286.01")
      numeric = old_id.sub(/^[^+]*\+task\./, "")
      # Match parent.subtask pattern (e.g., "286.01" → 1, but not "286" → nil)
      match = numeric.match(/^\d+\.(\d+)$/)
      return nil unless match
      match[1].to_i
    end

    # ── Step 2: Detect orphans and overflow ────────────────────────────────

    def detect_orphans_and_overflow
      puts "\nStep 2: Detecting orphans and subtask overflow..."

      # Build lookup of all parent old_ids
      parent_ids_by_dest = {}
      tasks.each do |t|
        next if t.subtask_num # skip subtasks
        parent_ids_by_dest[t.old_id] = t.destination
      end

      tasks.each do |t|
        next unless t.subtask_num # only check subtasks

        parent_dest = parent_ids_by_dest[t.parent_old_id]

        # Orphan: parent missing entirely or parent in archive but subtask in backlog
        if parent_dest.nil? || (t.destination == :backlog && parent_dest == :archive)
          t.promoted = true
          t.subtask_num = nil
          t.parent_old_id = nil
          @promoted_tasks << t
        end

        # Overflow: subtask number exceeds 36-char alphabet
        if t.subtask_num && t.subtask_num > SUBTASK_CHARS.size
          t.promoted = true
          t.subtask_num = nil
          t.parent_old_id = nil
          @overflow_tasks << t
        end
      end

      puts "  Promoted orphans: #{promoted_tasks.size}" if promoted_tasks.any?
      puts "  Promoted overflow: #{overflow_tasks.size}" if overflow_tasks.any?
    end

    # ── Step 3: Classify and sort ──────────────────────────────────────────

    def classify_tasks
      @parent_tasks = tasks.select(&:parent?)
        .sort_by { |t| sort_key(t.old_id) }

      @subtask_tasks = tasks.reject(&:parent?)
        .sort_by { |t| [sort_key(t.parent_old_id || ""), t.subtask_num || 0] }
    end

    def sort_key(old_id)
      # Extract numeric part for sorting: "v.0.9.0+task.286.01" → [286, 1]
      numeric = old_id.sub(/^[^+]*\+task\./, "")
      numeric.split(".").map(&:to_i)
    end

    # ── Step 4: Generate B36TS ID map ──────────────────────────────────────

    def generate_id_map
      puts "\nStep 3: Generating B36TS ID map..."

      base_raw = Ace::B36ts.encode(ANCHOR_TIME, format: :"2sec")
      base_int = base_raw.to_i(36)

      # Assign parent IDs by incrementing from anchor
      parent_tasks.each_with_index do |task, i|
        raw = (base_int + i).to_s(36).rjust(6, "0")
        item_id = TIF.format(raw)
        id_map[task.old_id] = item_id.formatted_id
      end

      # Derive subtask IDs: parent_id + .{char}
      subtask_tasks.each do |task|
        parent_new_id = id_map[task.parent_old_id]
        next unless parent_new_id

        char_idx = task.subtask_num - 1
        next if char_idx >= SUBTASK_CHARS.size # shouldn't happen after overflow detection

        id_map[task.old_id] = "#{parent_new_id}.#{SUBTASK_CHARS[char_idx]}"
      end

      puts "  Generated #{id_map.size} new IDs (#{parent_tasks.size} parents, #{subtask_tasks.size} subtasks)"
    end

    # ── Step 5: Transform frontmatter ──────────────────────────────────────

    def transform_frontmatter(task)
      old_fm = task.frontmatter
      new_id = id_map[task.old_id]

      new_fm = {}
      new_fm["id"] = new_id
      new_fm["title"] = task.title
      new_fm["status"] = normalize_status(old_fm["status"])
      new_fm["priority"] = normalize_priority(old_fm["priority"])
      new_fm["created_at"] = decode_created_at(new_id)

      est = old_fm["estimate"]
      new_fm["estimate"] = (est == "TBD") ? nil : est

      new_fm["dependencies"] = translate_deps(old_fm["dependencies"])
      new_fm["tags"] = Array(old_fm["tags"]) + ["migrated"]

      # Parent reference for non-promoted subtasks
      if !task.parent? && task.parent_old_id && id_map[task.parent_old_id]
        new_fm["parent"] = id_map[task.parent_old_id]
      end

      # Carry over extra fields as-is
      EXTRA_FIELDS.each do |field|
        new_fm[field] = old_fm[field] if old_fm.key?(field)
      end

      new_fm
    end

    def normalize_status(status)
      return "pending" if status.nil? || status.strip.empty?

      cleaned = status.strip.split(/\s+#/).first.strip # strip YAML-style comments
      cleaned = cleaned.tr("_", "-")

      # Map non-standard statuses
      STATUS_MAP.fetch(cleaned, cleaned).then do |s|
        # Validate against known statuses, default to "done" for unrecognized
        valid = %w[pending in-progress done blocked draft skipped cancelled]
        valid.include?(s) ? s : "done"
      end
    end

    def normalize_priority(priority)
      return "medium" if priority.nil?
      valid = %w[critical high medium low]
      valid.include?(priority.to_s) ? priority.to_s : "medium"
    end

    def decode_time_from_id(new_id)
      base_id = new_id.split(".")[0..2].join(".")
      raw = TIF.reconstruct(base_id)
      Ace::B36ts.decode(raw, format: :"2sec")
    end

    def decode_created_at(new_id)
      decode_time_from_id(new_id).strftime("%Y-%m-%d %H:%M:%S")
    end

    def translate_deps(deps)
      return [] unless deps.is_a?(Array)

      deps.filter_map do |dep|
        dep_str = dep.to_s.strip
        id_map[dep_str] # nil (dropped) if out-of-scope
      end
    end

    # ── Step 6: Write new structure ────────────────────────────────────────

    def write_tasks
      puts "\nStep 4: Writing new task structure..."

      written = 0
      parent_tasks.each do |t|
        write_parent_task(t)
        written += 1
      end
      subtask_tasks.each do |t|
        next unless id_map[t.old_id]
        write_subtask(t)
        written += 1
      end
      puts "  Wrote #{written} task files"
    end

    def write_parent_task(task)
      new_id = id_map[task.old_id]
      new_fm = transform_frontmatter(task)

      slug = build_slug(task.title)
      folder = TIF.folder_name(new_id, slug)
      filename = TIF.spec_filename(new_id, slug)

      dest_base = destination_root(task)
      dest_dir = File.join(dest_base, folder)
      dest_file = File.join(dest_dir, filename)

      body = task.body.sub(/\A\n+/, "")
      content = FS.rebuild(new_fm, body)

      FileUtils.mkdir_p(dest_dir)
      File.write(dest_file, content)
    end

    def write_subtask(task)
      new_id = id_map[task.old_id]
      return unless new_id

      parent_new_id = id_map[task.parent_old_id]
      parent_task = tasks.find { |t| t.old_id == task.parent_old_id && t.parent? }
      return unless parent_task

      new_fm = transform_frontmatter(task)

      parent_slug = build_slug(parent_task.title)
      parent_folder = TIF.folder_name(parent_new_id, parent_slug)

      subtask_slug = build_slug(task.title)
      subtask_folder = "#{new_id}-#{subtask_slug}"
      subtask_filename = "#{subtask_folder}.s.md"

      dest_base = destination_root(task)
      subtask_dir = File.join(dest_base, parent_folder, subtask_folder)
      subtask_file = File.join(subtask_dir, subtask_filename)

      body = task.body.sub(/\A\n+/, "")
      content = FS.rebuild(new_fm, body)

      FileUtils.mkdir_p(subtask_dir)
      File.write(subtask_file, content)
    end

    def build_slug(title)
      SS.sanitize(title)[0..39]
    end

    def destination_root(task)
      case task.destination
      when :active  then TASKS_ROOT
      when :archive
        time = decode_time_from_id(id_map[task.old_id])
        partition = DPP.compute(time)
        File.join(TASKS_ROOT, "_archive", partition)
      when :backlog then File.join(TASKS_ROOT, "_maybe")
      end
    end

    # ── Step 7: Copy extra assets ──────────────────────────────────────────

    def copy_extra_assets
      puts "\nStep 5: Copying extra assets..."

      EXTRA_ASSETS.each do |info|
        new_id = id_map[info[:old_id]]
        next unless new_id

        parent_task = parent_tasks.find { |t| t.old_id == info[:old_id] }
        next unless parent_task

        slug = build_slug(parent_task.title)
        folder = TIF.folder_name(new_id, slug)
        dest_base = destination_root(parent_task)
        dest = File.join(dest_base, folder, info[:dirname])

        if Dir.exist?(info[:src])
          FileUtils.cp_r(info[:src], dest)
          puts "  Copied #{info[:dirname]}/ → #{folder}/"
        else
          puts "  WARN: Source not found: #{info[:src]}"
        end
      end
    end

    # ── Pre-flight checks ──────────────────────────────────────────────────

    def check_conflicts
      return unless Dir.exist?(TASKS_ROOT)

      existing = Dir.glob(File.join(TASKS_ROOT, "???.t.???-*"))
      return if existing.empty?

      abort "ERROR: .ace-tasks/ already contains #{existing.size} task folders. " \
            "Refusing to overwrite. Remove .ace-tasks/ first if re-running."
    end

    # ── Verification ───────────────────────────────────────────────────────

    def verify
      puts "\nStep 6: Verification..."

      %w[. _archive _maybe].each do |subfolder|
        root = subfolder == "." ? TASKS_ROOT : File.join(TASKS_ROOT, subfolder)
        next unless Dir.exist?(root)

        label = subfolder == "." ? "root" : subfolder
        scanner = Ace::Task::Molecules::TaskScanner.new(root)
        next unless scanner.root_exists?

        primaries = scanner.scan
        loader = Ace::Task::Molecules::TaskLoader.new
        errors = []
        primaries.each do |result|
          begin
            sf = subfolder == "." ? result.special_folder : subfolder.delete_prefix("_")
            loader.load(result.dir_path, id: result.id, special_folder: sf)
          rescue => e
            errors << "#{result.id}: #{e.message}"
          end
        end

        puts "  #{label}: #{primaries.size} primary tasks, #{errors.size} errors"
        errors.first(5).each { |e| puts "    #{e}" } if errors.any?
      end

      # Total file count
      total = Dir.glob(File.join(TASKS_ROOT, "**", "*.s.md")).size
      puts "  Total spec files written: #{total}"
    end

    # ── Summary ────────────────────────────────────────────────────────────

    def print_summary
      puts
      puts "=" * 60
      puts "Migration Summary"
      puts "=" * 60
      puts "  Parent tasks:  #{parent_tasks.size}"
      puts "  Subtasks:      #{subtask_tasks.size}"
      puts "  Total mapped:  #{id_map.size}"
      puts
      puts "  By destination:"
      %i[active archive backlog].each do |dest|
        label = { active: "active (.ace-tasks/)", archive: "_archive", backlog: "_maybe" }[dest]
        parents = parent_tasks.count { |t| t.destination == dest }
        subs = subtask_tasks.count { |t| t.destination == dest }
        puts "    #{label}: #{parents} parents + #{subs} subtasks = #{parents + subs}"
      end

      if promoted_tasks.any?
        puts
        puts "  Promoted orphans (subtask → standalone):"
        promoted_tasks.each { |t| puts "    #{t.old_id} → parent in #{destination_root(t)}" }
      end
      if overflow_tasks.any?
        puts
        puts "  Promoted overflow (>36 subtasks):"
        overflow_tasks.each { |t| puts "    #{t.old_id}" }
      end
      puts "=" * 60
    end

    def print_mapping_table
      all_sorted = (parent_tasks + subtask_tasks)
        .sort_by { |t| sort_key(t.old_id) }

      puts
      puts format("%-28s %-16s %-10s %-10s %s", "Old ID", "New ID", "Dest", "Status", "Title")
      puts "-" * 100

      all_sorted.each do |task|
        new_id = id_map[task.old_id] || "(unmapped)"
        dest = { active: "active", archive: "_archive", backlog: "_maybe" }[task.destination]
        status = task.frontmatter["status"]&.to_s&.split(/\s+#/)&.first&.strip || "?"
        title_short = task.title[0..25]
        puts format("%-28s %-16s %-10s %-10s %s", task.old_id, new_id, dest, status, title_short)
      end

      puts "-" * 100
    end
  end
end

# ── Entry point ──────────────────────────────────────────────────────────

dry_run = ARGV.include?("--dry-run")
MigrateTaskflow::Migrator.new(dry_run: dry_run).run
