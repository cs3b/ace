# Description: Capture one idea and list it in an isolated demo workspace
# Tags: docs,idea

Output ace-idea/docs/demo/ace-idea-getting-started.gif

Set FontSize 16
Set Width 1200
Set Height 560

Type "cd $PWD"
Enter
Sleep 1s

Type "rm -rf /tmp/ace-idea-demo-home && mkdir -p /tmp/ace-idea-demo-home/.ace/idea && printf 'idea:\n  root_dir: /tmp/ace-idea-demo-home/ideas\n' >/tmp/ace-idea-demo-home/.ace/idea/config.yml"
Enter
Sleep 2s

Type "HOME=/tmp/ace-idea-demo-home mise exec -- ace-idea create 'Dark mode for night coding' --title 'Dark mode'"
Enter
Sleep 2s

Type "HOME=/tmp/ace-idea-demo-home mise exec -- ace-idea list"
Enter
Sleep 2s
