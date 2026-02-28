# frozen_string_literal: true
#
# Codemod: fix_archive_week_partitions.rb
#
# Context: The previous migration used the buggy encode_split which produced raw
# week digits (1-5) instead of proper base36 chars (v-z, values 31-35).
# This script renames week partition dirs in .ace-ideas/_archive/*/
#
# Mapping (raw digit → base36 char):
#   1 → v (31 in base36)
#   2 → w (32)
#   3 → x (33)
#   4 → y (34)
#   5 → z (35)
#
# Usage:
#   ruby fix_archive_week_partitions.rb --dry-run
#   ruby fix_archive_week_partitions.rb

require "fileutils"

DIGIT_TO_B36 = {
  "1" => "v",
  "2" => "w",
  "3" => "x",
  "4" => "y",
  "5" => "z"
}.freeze

dry_run = ARGV.include?("--dry-run")

repo_root = File.expand_path("../../../../../../..", __FILE__)
archive_root = File.join(repo_root, ".ace-ideas", "_archive")

unless Dir.exist?(archive_root)
  warn "Archive directory not found: #{archive_root}"
  exit 1
end

puts dry_run ? "[dry-run] Scanning #{archive_root}" : "Scanning #{archive_root}"

renamed = 0
skipped = 0

Dir.glob("#{archive_root}/*/").sort.each do |month_dir|
  Dir.glob("#{month_dir}*/").sort.each do |subdir|
    name = File.basename(subdir)
    next unless DIGIT_TO_B36.key?(name)

    new_name = DIGIT_TO_B36[name]
    new_path = File.join(File.dirname(subdir), new_name)

    if File.exist?(new_path)
      puts "  SKIP (target exists): #{subdir} → #{new_path}"
      skipped += 1
      next
    end

    if dry_run
      puts "  [dry-run] RENAME: #{subdir} → #{new_path}"
    else
      FileUtils.mv(subdir, new_path)
      puts "  RENAMED: #{subdir} → #{new_path}"
    end
    renamed += 1
  end
end

puts
puts dry_run ? "[dry-run] Would rename: #{renamed}, would skip: #{skipped}" : "Renamed: #{renamed}, skipped: #{skipped}"
