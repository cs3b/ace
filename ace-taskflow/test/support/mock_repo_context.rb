# frozen_string_literal: true

# Mock RepoContext that mirrors the real Ace::Git::Models::RepoContext interface
# Used in tests to avoid dependency on ace-git internals
class MockRepoContext
  attr_reader :branch, :tracking, :ahead, :behind, :task_pattern,
              :pr_metadata, :repository_type, :repository_state

  def initialize(branch:, tracking: nil, ahead: 0, behind: 0,
                 task_pattern: nil, has_pr: false, pr_metadata: nil,
                 repository_type: :normal, repository_state: :clean)
    @branch = branch
    @tracking = tracking
    @ahead = ahead
    @behind = behind
    @task_pattern = task_pattern
    @has_pr = has_pr
    @pr_metadata = pr_metadata
    @repository_type = repository_type
    @repository_state = repository_state
  end

  def has_task_pattern?
    !@task_pattern.nil? && !@task_pattern.empty?
  end

  def has_pr?
    @has_pr
  end

  def detached?
    @branch == "HEAD" || @repository_type == :detached
  end

  def clean?
    @repository_state == :clean
  end

  def tracking_status
    return "no tracking branch" unless @tracking

    if @ahead == 0 && @behind == 0
      "up to date"
    elsif @ahead > 0 && @behind > 0
      "#{@ahead} ahead, #{@behind} behind"
    elsif @ahead > 0
      "#{@ahead} ahead"
    else
      "#{@behind} behind"
    end
  end
end
