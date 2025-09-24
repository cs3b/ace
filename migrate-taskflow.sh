#!/usr/bin/env bash
#
# migrate-taskflow.sh - Migrate dev-taskflow to .ace-taskflow with improved structure
#
# This script performs a three-phase migration:
# 1. Move entire directory with git mv
# 2. Reorganize internal structure
# 3. Update file names for clarity
#
# Usage: ./migrate-taskflow.sh [--dry-run] [--rollback]
#
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
SOURCE_DIR="dev-taskflow"
TARGET_DIR=".ace-taskflow"
CURRENT_RELEASE="v.0.9.0-mono-repo-multiple-gems"
RELEASE_VERSION="v.0.9.0"
DRY_RUN=false
ROLLBACK=false
BACKUP_BRANCH="backup-before-taskflow-migration"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --rollback)
      ROLLBACK=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--dry-run] [--rollback]"
      exit 1
      ;;
  esac
done

# Functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

execute_cmd() {
  local cmd="$1"
  local desc="${2:-}"

  if [[ -n "$desc" ]]; then
    log_info "$desc"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BOLD}[DRY-RUN]${NC} $cmd"
  else
    eval "$cmd"
  fi
}

check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check if in git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository"
    exit 1
  fi

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    log_error "Uncommitted changes detected. Please commit or stash them first."
    exit 1
  fi

  # Check if source directory exists
  if [[ ! -d "$SOURCE_DIR" ]]; then
    log_error "Source directory $SOURCE_DIR does not exist"
    exit 1
  fi

  # Check if target already exists (for rollback check)
  if [[ "$ROLLBACK" == false && -d "$TARGET_DIR" ]]; then
    log_error "Target directory $TARGET_DIR already exists. Remove it first or use --rollback"
    exit 1
  fi

  log_success "Prerequisites check passed"
}

create_backup_branch() {
  if [[ "$DRY_RUN" == false && "$ROLLBACK" == false ]]; then
    log_info "Creating backup branch: $BACKUP_BRANCH"
    git checkout -b "$BACKUP_BRANCH" 2>/dev/null || {
      log_warning "Backup branch already exists, updating it"
      git branch -f "$BACKUP_BRANCH"
    }
    git checkout -
  fi
}

rollback_migration() {
  log_info "Starting rollback..."

  # Check if target directory exists
  if [[ ! -d "$TARGET_DIR" ]]; then
    log_error "Nothing to rollback - $TARGET_DIR does not exist"
    exit 1
  fi

  # Check if source directory already exists
  if [[ -d "$SOURCE_DIR" ]]; then
    log_error "Cannot rollback - $SOURCE_DIR already exists"
    exit 1
  fi

  # Reverse phase 4: Move qa folders back and rename retro to reflections
  local release_dir="$TARGET_DIR/$RELEASE_VERSION"
  if [[ -d "$release_dir/retro" ]]; then
    execute_cmd "git mv '$release_dir/retro' '$release_dir/reflections'" "Restoring reflections name"
  fi

  if [[ -d "$release_dir/qa" ]]; then
    if [[ -d "$release_dir/qa/code-review" ]]; then
      if [[ -n "$(ls -A '$release_dir/qa/code-review' 2>/dev/null)" ]]; then
        execute_cmd "git mv '$release_dir/qa/code-review' '$release_dir/code-review'" "Moving code-review out of qa"
      else
        mv "$release_dir/qa/code-review" "$release_dir/"
      fi
    fi

    if [[ -d "$release_dir/qa/test-cases" ]]; then
      if [[ -n "$(ls -A '$release_dir/qa/test-cases' 2>/dev/null)" ]]; then
        execute_cmd "git mv '$release_dir/qa/test-cases' '$release_dir/test-cases'" "Moving test-cases out of qa"
      else
        mv "$release_dir/qa/test-cases" "$release_dir/"
      fi
    fi

    rmdir "$release_dir/qa" 2>/dev/null || true
  fi

  # Move back to original location
  execute_cmd "git mv '$TARGET_DIR' '$SOURCE_DIR'" "Moving $TARGET_DIR back to $SOURCE_DIR"

  # Restore original structure (reverse of reorganization)
  execute_cmd "git mv '$SOURCE_DIR/$RELEASE_VERSION' '$SOURCE_DIR/current/$CURRENT_RELEASE'" "Restoring release structure"

  # Restore task file names
  local task_dir="$SOURCE_DIR/current/$CURRENT_RELEASE/tasks"
  if [[ -d "$task_dir" ]]; then
    for task_folder in "$task_dir"/v.*.md; do
      if [[ -f "$task_folder" ]]; then
        local basename=$(basename "$task_folder" .md)
        execute_cmd "git mv '$task_folder' '$task_dir/${basename}.md'" "Restoring task file name"
      fi
    done
  fi

  log_success "Rollback completed successfully"
  exit 0
}

phase1_move_directory() {
  log_info "Phase 1: Moving entire directory from $SOURCE_DIR to $TARGET_DIR"

  execute_cmd "git mv '$SOURCE_DIR' '$TARGET_DIR'" "Moving directory with git mv"

  if [[ "$DRY_RUN" == false ]]; then
    log_success "Phase 1 completed: Directory moved"
  fi
}

phase2_reorganize_releases() {
  log_info "Phase 2: Reorganizing release structure"

  # Move current release to root level with version only
  local current_path="$TARGET_DIR/current/$CURRENT_RELEASE"
  local new_path="$TARGET_DIR/$RELEASE_VERSION"

  if [[ -d "$current_path" || "$DRY_RUN" == true ]]; then
    execute_cmd "git mv '$current_path' '$new_path'" "Moving current release to root level"

    # Rename release file to be more descriptive
    local release_file="$new_path/release.md"
    local new_release_file="$new_path/mono-repo-multiple-gems.md"
    if [[ -f "$release_file" || "$DRY_RUN" == true ]]; then
      execute_cmd "git mv '$release_file' '$new_release_file'" "Renaming release.md to descriptive name"
    fi
  fi

  # Remove now-empty current directory
  if [[ "$DRY_RUN" == false && -d "$TARGET_DIR/current" ]]; then
    if [[ -z "$(ls -A '$TARGET_DIR/current')" ]]; then
      rmdir "$TARGET_DIR/current"
      log_info "Removed empty current directory"
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    log_success "Phase 2 completed: Releases reorganized"
  fi
}

phase3_restructure_tasks() {
  log_info "Phase 3: Restructuring tasks with descriptive names"

  local tasks_dir="$TARGET_DIR/$RELEASE_VERSION/tasks"
  local target_tasks_dir="$TARGET_DIR/$RELEASE_VERSION/t"

  # Create t/ directory
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$target_tasks_dir"
  else
    log_info "Would create directory: $target_tasks_dir"
  fi

  # Process each task file
  if [[ -d "$tasks_dir" || "$DRY_RUN" == true ]]; then
    # In dry-run mode, simulate with sample tasks
    if [[ "$DRY_RUN" == true ]]; then
      log_info "Would process task files in $tasks_dir"
      # Simulate a few tasks for dry-run
      for i in 001 019 022; do
        local task_file="$tasks_dir/v.0.9.0+task.${i}-sample-task.md"
        local task_num=$(printf "%03d" $((10#$i)))
        local task_name="sample-task"
        local task_folder="$target_tasks_dir/$task_num"

        log_info "Would create folder: $task_folder"
        log_info "Would move: $task_file -> $task_folder/${task_name}.md"
      done
    else
      # Process actual task files
      for task_file in "$tasks_dir"/v.*.md; do
        if [[ -f "$task_file" ]]; then
          local basename=$(basename "$task_file" .md)
          # Extract task number and name
          # Pattern: v.0.9.0+task.NNN-descriptive-name
          if [[ "$basename" =~ v\.[0-9]+\.[0-9]+\.[0-9]+\+task\.([0-9]+)-(.+) ]]; then
            local task_num=$(printf "%03d" $((10#${BASH_REMATCH[1]})))
            local task_name="${BASH_REMATCH[2]}"
            local task_folder="$target_tasks_dir/$task_num"

            # Create task folder
            mkdir -p "$task_folder"

            # Move task file with descriptive name
            execute_cmd "git mv '$task_file' '$task_folder/${task_name}.md'" "Moving task $task_num"

            # Check for task-specific subdirectories (like ux.md for task 019)
            local task_subdir="${task_file%.md}"
            if [[ -d "$task_subdir" ]]; then
              log_info "Found task subdirectory for task $task_num"
              # Move subdirectory contents to task folder
              for subfile in "$task_subdir"/*; do
                if [[ -e "$subfile" ]]; then
                  local subname=$(basename "$subfile")
                  execute_cmd "git mv '$subfile' '$task_folder/$subname'" "Moving $subname for task $task_num"
                fi
              done
              # Remove empty subdirectory
              rmdir "$task_subdir" 2>/dev/null || true
            fi
          else
            log_warning "Could not parse task file name: $basename"
          fi
        fi
      done

      # Remove now-empty tasks directory
      if [[ -d "$tasks_dir" && -z "$(ls -A '$tasks_dir')" ]]; then
        rmdir "$tasks_dir"
        log_info "Removed empty tasks directory"
      fi
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    log_success "Phase 3 completed: Tasks restructured"
  fi
}

phase4_organize_qa_and_retro() {
  log_info "Phase 4: Organizing QA folders and renaming reflections to retro"

  local release_dir="$TARGET_DIR/$RELEASE_VERSION"
  local qa_dir="$release_dir/qa"

  # Create qa directory
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$qa_dir"
  else
    log_info "Would create directory: $qa_dir"
  fi

  # Move code-review and test-cases into qa folder
  if [[ -d "$release_dir/code-review" || "$DRY_RUN" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log_info "Would move: $release_dir/code-review -> $qa_dir/code-review"
    else
      if [[ -d "$release_dir/code-review" ]]; then
        # Check if directory has files
        if [[ -n "$(ls -A '$release_dir/code-review' 2>/dev/null)" ]]; then
          execute_cmd "git mv '$release_dir/code-review' '$qa_dir/code-review'" "Moving code-review to qa folder"
        else
          # Empty directory, use regular mv
          mv "$release_dir/code-review" "$qa_dir/"
          log_info "Moved empty code-review directory to qa"
        fi
      fi
    fi
  fi

  if [[ -d "$release_dir/test-cases" || "$DRY_RUN" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log_info "Would move: $release_dir/test-cases -> $qa_dir/test-cases"
    else
      if [[ -d "$release_dir/test-cases" ]]; then
        # Check if directory has files
        if [[ -n "$(ls -A '$release_dir/test-cases' 2>/dev/null)" ]]; then
          execute_cmd "git mv '$release_dir/test-cases' '$qa_dir/test-cases'" "Moving test-cases to qa folder"
        else
          # Empty directory, use regular mv
          mv "$release_dir/test-cases" "$qa_dir/"
          log_info "Moved empty test-cases directory to qa"
        fi
      fi
    fi
  fi

  # Rename reflections to retro
  if [[ -d "$release_dir/reflections" || "$DRY_RUN" == true ]]; then
    execute_cmd "git mv '$release_dir/reflections' '$release_dir/retro'" "Renaming reflections to retro"
  fi

  if [[ "$DRY_RUN" == false ]]; then
    log_success "Phase 4 completed: QA organized and reflections renamed"
  fi
}

verify_migration() {
  log_info "Verifying migration..."

  if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry-run mode - skipping verification"
    return
  fi

  # Check target directory exists
  if [[ ! -d "$TARGET_DIR" ]]; then
    log_error "Target directory does not exist"
    return 1
  fi

  # Count migrated files
  local file_count=$(find "$TARGET_DIR" -name "*.md" -type f | wc -l)
  log_info "Found $file_count markdown files in migrated structure"

  # Check key directories exist
  if [[ -d "$TARGET_DIR/$RELEASE_VERSION" ]]; then
    log_success "Release directory exists: $TARGET_DIR/$RELEASE_VERSION"
  else
    log_error "Release directory missing: $TARGET_DIR/$RELEASE_VERSION"
    return 1
  fi

  if [[ -d "$TARGET_DIR/$RELEASE_VERSION/t" ]]; then
    local task_count=$(find "$TARGET_DIR/$RELEASE_VERSION/t" -mindepth 1 -maxdepth 1 -type d | wc -l)
    log_success "Tasks directory exists with $task_count task folders"
  else
    log_warning "Tasks directory missing: $TARGET_DIR/$RELEASE_VERSION/t"
  fi

  # Verify git history preserved
  log_info "Checking git history preservation..."
  local sample_file=$(find "$TARGET_DIR" -name "*.md" -type f | head -1)
  if [[ -n "$sample_file" ]]; then
    if git log --follow --oneline "$sample_file" > /dev/null 2>&1; then
      log_success "Git history preserved for migrated files"
    else
      log_warning "Could not verify git history"
    fi
  fi

  log_success "Migration verification completed"
}

# Main execution
main() {
  echo -e "${BOLD}=== Taskflow Migration Script ===${NC}"
  echo

  if [[ "$DRY_RUN" == true ]]; then
    log_warning "Running in DRY-RUN mode - no changes will be made"
  fi

  if [[ "$ROLLBACK" == true ]]; then
    check_prerequisites
    rollback_migration
    exit 0
  fi

  check_prerequisites
  create_backup_branch

  # Execute migration phases
  phase1_move_directory

  if [[ "$DRY_RUN" == false ]]; then
    # Commit after phase 1 for safety
    git add -A
    git commit -m "chore: migrate dev-taskflow to .ace-taskflow (phase 1: move directory)" || true
  fi

  phase2_reorganize_releases

  if [[ "$DRY_RUN" == false ]]; then
    # Commit after phase 2
    git add -A
    git commit -m "chore: reorganize .ace-taskflow release structure (phase 2)" || true
  fi

  phase3_restructure_tasks

  if [[ "$DRY_RUN" == false ]]; then
    # Commit after phase 3
    git add -A
    git commit -m "chore: restructure .ace-taskflow tasks with descriptive names (phase 3)" || true
  fi

  phase4_organize_qa_and_retro

  if [[ "$DRY_RUN" == false ]]; then
    # Commit after phase 4
    git add -A
    git commit -m "chore: organize qa folders and rename reflections to retro (phase 4)" || true
  fi

  verify_migration

  echo
  if [[ "$DRY_RUN" == true ]]; then
    log_success "Dry-run completed successfully!"
    echo -e "${YELLOW}To perform the actual migration, run without --dry-run flag${NC}"
  else
    log_success "Migration completed successfully!"
    echo -e "${GREEN}The dev-taskflow directory has been migrated to .ace-taskflow${NC}"
    echo -e "${BLUE}Backup branch created: $BACKUP_BRANCH${NC}"
    echo -e "${YELLOW}To rollback if needed, run: $0 --rollback${NC}"
  fi
}

# Run main function
main