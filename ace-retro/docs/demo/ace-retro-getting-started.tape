# Description: Showcase ace-retro create, show, list, and archive workflow
# Tags: ace-retro,docs,getting-started

Output docs/demo/ace-retro-getting-started.gif

Set FontSize 16
Set Width 960
Set Height 540

# Scene 1: Prepare isolated demo workspace
Type "rm -rf /tmp/ace-retro-demo && mkdir -p /tmp/ace-retro-demo && cd /tmp/ace-retro-demo"
Enter
Sleep 2s

# Scene 2: Seed one known retro for show/update demo
Type "mkdir -p .ace-retros/8ppq7w-sprint-review"
Enter
Sleep 1s
Type "printf '%s\n' '---' 'id: 8ppq7w' 'title: Sprint Review' 'type: standard' 'tags: [sprint, team]' 'status: active' 'created_at: 2026-03-01 12:00:00' '---' '' '# Sprint Review' '' '## What Went Well' '' 'Great collaboration.' > .ace-retros/8ppq7w-sprint-review/8ppq7w-sprint-review.retro.md"
Enter
Sleep 2s

# Scene 3: Create a new retro
Type "mise exec -- ace-retro create 'Release Retro Demo' --type standard --tags release,demo"
Enter
Sleep 3s

# Scene 4: Show and list retros
Type "mise exec -- ace-retro show q7w"
Enter
Sleep 3s
Type "mise exec -- ace-retro list --in all"
Enter
Sleep 3s

# Scene 5: Archive the known retro
Type "mise exec -- ace-retro update q7w --set status=done --move-to archive"
Enter
Sleep 3s
Type "mise exec -- ace-retro list --in archive"
Enter
Sleep 3s
