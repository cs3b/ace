history | grep task-manager > .ace/taskflow/current/v.0.5.0-insights/researches/task-manager-usage.md
search "bin/gc" --hidden
search --hidden "model: claude"cd
search --hidden "model: claude"
search --hidden "model: cloude"
search --hidden "model: sonnet"
search --hidden "model: sonet"
search --hidden "model: opus"
search --hidden "model: {opus|sonnet}"
search --hidden -r "model:\s{opus|sonnet}"
search --hidden "model:\s{opus|sonnet}"
search "model: sonnet"
search "model: s"
search "model: o"
search "model: "
search "model: " --search-root .claude
search "model: opus" --search-root .claude
search --help
search "model: opus"
search "bin/gc"
search "bin/tn"
search "bin/tnid"
search "bin/tnid" --search-root /Users/michalczyz/Projects/CodingAgent/handbook-meta
search "bin/tnid" --search-root
search "bin/tnid" --search-root ../../
search "bin/tn" --exclude ".ace/taskflow/done/**/*,.ace/taskflow/current/*/tasks/*"
search "bin/tn" -t auto
search "bin/tn" --file --content
search "bin/tn" --hybrid
search "bin/tn" --file
search "bin/tn" --fole
search "bin/tn" --content
capture-it "agent - that will perform research about features we should implement"
git-commit .ace/taskflow/backlog/ideas/20250803-1342-research-best-practices-repository.md .ace/taskflow/backlog/ideas/20250803-1419-backlog-audio-assistant.md
capture-it "in context of capture-it draft-task plan-task review-task - how to make them more enganging, talk on the better layer of abstraction - also improve cascade (or even reverse review) on anything new, decisions and research, to keeep the whole task in sync. Also important tho think thourougly the default propositions"
capture-it "in context of draft-task.wf plan-task.wf review.task.wf - we should improve the way we research the repository, and research the best practice (including our own guides)"
capture-it "in context of capture-it cmd - we stil lhave in filestystem: ideas_manager - we need to make deep search for filenames and content and upated it all to capture-it or capture_it" --debug
capture-it "in context of capture-it cmd - we stil lhave in filestystem: ideas_manager - we need to make deep search for filenames and content and upated it all to capture-it or capture_it" --commit
capture-it "in context of capture-it cmd - we stil lhave in filestystem: ideas_manager - we need to make deep search for filenames and content and upated it all to capture-it or capture_it"
git-commit .ace/taskflow/backlog/ideas/monorepo-for-all-the-vue-apps-research.md
cp /Users/michalczyz/Projects/CodingAgent/handbook-meta/.ace/taskflow/current/v.0.3.0-workflows/researches/gem-architecture-integration.md ./
brew search openjdk
gcam current/v.0.1.0-foundation/researches/pwa-cache.md
exe/llm-query lmstudio "What are the strategies to compress rules, prompts for llm" --output docs-project/backlog/researches/compressiong-prompt.md
exe/llm-query gflash "What are the strategies to compress rules, prompts for llm" --output docs-project/backlog/researches/compressiong-prompt.md
rm research_summary.txt test_prompt.txt
git commit -m 'docs: research prompt and fish script'
git restore --staged backlog/research/20250619-ai.updates/**/*
gcam backlog/research -i 'doc - research prompt and fish script'
gcam backlog/research -m 'doc - research prompt and fish script'
git rm -r backlog/research/20250619-ai.updates/*
git rm backlog/research/20250619-ai.updates/*
git add backlog/research
gcam backlog/research -m 'doc - research youtube'
gcam backlog/research -i 'doc - research youtube'
cd backlog/research/
~/Projects/coding-agent-tools/exe/llm-geminiVjjVjk-query backlog/research/20250619-ai.updates/input/001.anthropic-claude-code.wav.txt --file \
 --system $system_prompt > backlog/research/20250619-ai.updates/summaries/001.anthropic-claude-code.md
~/Projects/coding-agent-tools/exe/llm-gemini-query backlog/research/20250619-ai.updates/input/001.anthropic-claude-code.wav.txt --file \
 --system $system_prompt > backlog/research/20250619-ai.updates/summaries/001.anthropic-claude-code.2.5-pro.md
~/Projects/coding-agent-tools/exe/llm-gemini-query backlog/research/20250619-ai.updates/input/001.anthropic-claude-code.wav.txt --file \
 --system $system_prompt > backlog/research/20250619-ai.updates/summaries/001.anthropic-claude-code.2.5-flash.md
~/Projects/coding-agent-tools/exe/llm-gemini-query backlog/research/20250619-ai.updates/input/001.anthropic-claude-code.wav.txt --file \--system $system_prompt > backlog/research/20250619-ai.updates/summaries/001.anthropic-claude-code.wav.md
~/Projects/coding-agent-tools/exe/llm-gemini-query backlog/research/20250619-ai.updates/input/001.anthropic-claude-code.wav.txt --file --system $system_prompt > backlog/research/20250619-ai.updates/summaries/001.anthropic-claude-code.wav.md
set system_prompt (cat backlog/research/prompt/summarize.prompt.md)
set system_prompt cat backlog/research/prompt/summarize.prompt.md
cp -R ~/Projects/whisper-transcript-ruby/transcribe/ backlog/research/
cp ~/Projects/whisper-transcript-ruby/transcribe/ backlog/research/
bin/gc -i "Review ANSI Color StringIO task: clarify scope, refine helper design, add behavior matrix testing approach based on research notes"
git diff e34064a > docs-project/current/v.0.2.0-synapse/researches/task.1-changes-implemented-for-feedback.diff
gcama -i 'docs - researches - move into right release'
gcam docs-project/backlog/research/ -i 'doc - add research atom architecture'
mkdir Researches
git add     docs-project/current/v.0.1.0-initial-implementation/researches/wasm-file-handling-fix.md
gcm docs-project/current/v.0.1.0-initial-implementation/researches/
git commit docs(guides): Integrate research insights into guides and workflows
Incorporate principles from research documents (general rules, how-to-write, prompting future) into development guides and workflow instructions to enhance clarity and effectiveness, particularly regarding AI collaboration.
Addresses Task: docs-project/current/v-0.2.2-feedback-to-process/tasks/03-update-guides-with-research.md
{"jsonrpc": "2.0", "id": 3, "method": "prompts/get", "params": {"name": "SummarizeTranscriptPrompt", "arguments": {"transcript": "OpenAI's Autonomous AI Research Benchmark - YouTube\nhttps://www.youtube.com/watch?v=SeQU2LNQ5ig\n\nTranscript:\n(00:00) so OpenAI just published this paper bench evaluating AI's ability to replicate AI research OpenAI has been publishing more research and opensourcing a lot more projects recently And this one's very interesting for a number of reasons As they've tweeted from their account they're saying that they're releasing Paperbench a benchmark evaluating the ability of AI agents to replicate state-of-the-art AI research as part of our preparedness framework And a lot of the Frontier AI labs they have their own version of the\n(00:30) preparedness framework Basically it's how we track the potential AI risk As these AI models get better and better we want to kind of see the escalating threats that they potentially could pose And we're sort of tracking it on this at least with OpenAI we're tracking on this scale of low medium high and critical OpenAI tracks the AI risk across these four categories cyber security CBRN which is chemical biological nuclear and radiological threats persuasion and model autonomy right and sort of like the highest thing any model scores\n(01:03) across these categories that sort of is taken as the risk score So if it's a low in cyber security but critical in persuasion for example we'll still call that a critical model risk Now specifically today we're talking about the model autonomy Of course model autonomy is kind of the promise of AI agents how well they're able to execute long horizon tasks And of course that will provide a great many benefits but also we have to be a little bit careful about how we kind of put that out there in the world because there could be a\n(01:34) number of bad unintended consequences ...\n(19:58) about it let me know in the comments If you made it this far thank you so much for watching My name is West Roth and I'll see you next time", "meta": {"source": "YouTube: SeQU2LNQ5ig"}}}}
uv run pytest -vv tests/test_server.py::test_search_in_files
brew search mono
brew search wally
brew search zoom
capture-it --commit "in context of claude code agents - general agent for commands - verify / run / find why do we have error"
rm (find . -name "*.wav*")
find . -name "*.wav*"
find . -name "*.wav*" | rm
find . -name "*wav" | rm
find . -name "*wav"
find . -name "wav"
find . --name "wav"
tldr find
find "*.wav"
find ".wav"
find "*wav"
find ".*wav"
find ".*wav.*"
find "wav"
for file in (find . -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
find "'lets-prepare-tasks" .
find "'lets-prepare-tasks"
find . | grep "release"
find .  -iname '*release*'
find . -type f  -iname '*release*'
find . -type f  -iname '*.mp3'
find . -f  -iname '*.mp3'
find -f  -iname '*.mp3'
find  -iname '*.mp3'
find -o -iname '*.mp3'
find $d -type f -exec wc -w {} + | tail -n1
find . -type f -exec wc -w {} + | tail -n1
for file in (find docs-dev -depth)
find /opt/homebrew -name "asdf.sh" 2>/dev/null
history | grep find >> .ace/taskflow/current/v.0.5.0-insights/researches/search-and-others-usage.md
history | grep search > .ace/taskflow/current/v.0.5.0-insights/researches/search-and-others-usage.md
history | grep task-manager > .ace/taskflow/current/v.0.5.0-insights/researches/task-manager-usage.md
git -C .ace/tools  ls-files | grep lib/
tree .ace/tools/**/* | grep ideas
grep -r 'status:' .ace/taskflow/current/v.0.4.0-replanning/tasks/**/*.md
git status | grep current | rm
git status | grep current
rspec --help | grep fast
grep -C 5 "Error: undefined"  ../tmp/test.output.txt
bin/test --format documentation | grep -C 7 "Error: undefined method"
bin/test --format documentation | grep -C "Error: undefined method"
bin/test | grep atoms
cat .ace/taskflow/current/v.0.3.0-workflows/code_review/code-.ace/handbook---20250724-173954/prompt.md | grep "document path='"
cat .ace/taskflow/current/v.0.3.0-workflows/code_review/code-.ace/handbook---20250724-173954/input.xml | grep "document path='"
ps aux | grep firebase
ps aux | grep 9323
history | grep worktree
echo $PATH | grep exe
echo $PATH | grep .ace/tools
echo $PATH | grep tools-meta
bin/tal | grep pending | sort
bin/tal | grep pending
ps aux | grep claude
ps aux | grep gemini
ps aux | grep google
ps aux | grep commit
ps aux | grep fish
ps aux | grep gcama
ps aux | grep node
ps aux grep node
rspec --help | grep seed
bin/test spec/coding_agent_tools  --format documentation  | grep -A 20 -B 20 "Error:"
bin/test spec/coding_agent_tools  --format documentation  | grep -A 5 -B 20 "Error:"
bin/test spec/coding_agent_tools  --format documentation  | grep -A 5 -B 20 "Error"
bin/test | grep "expected that"
ps aux | grep
ps aux | grep ngrok
cat coverage/index.html | grep coverage
cat coverage/index.html | grep total
bin/test | grep failures
ps aux | grep ruby
grep -nrE --include=\*.md '^- \[ \]'  docs-dev/guides/
grep -nrE --include=\*.md '^- \[ \]'  docs-dev/workflow-instructions/
grep -nrE --include=\*.md '^- \[x\]' docs-dev/guides/ docs-dev/workflow-instructions/
grep -nrE --include=\*.md '^- \[ \]' docs-dev/guides/ docs-dev/workflow-instructions/
bin/lint | grep MD013
find . | grep "release"
yt-dlp --help | grep cover
shellspec --help | grep focus
ffmpeg --help |grep silent
grep -r 'implementing-task-cycle' docs-*/
grep -r 'implementing-task-cycle.md' docs-*/
  grep -v '^./docs-project/backlog' | \
  grep -v '^./docs-project/done' | \
  grep -v '^./tmp' | \
  grep -v '^./docs-project/sessions' | pbcopy
  grep -v '^./docs-project/backlog' | \
  grep -v '^./docs-project/done' | \
  grep -v '^./tmp' | \
  grep -v '^./docs-project/sessions'
  grep -v '^./docs-project/backlog' | \
  grep -v '^./docs-project/done' | \
  grep -v '^./tmp' | \
  grep -v '^./sessions'
tree -fi | grep -v '^./docs-project/backlog'tree -fi | \
  grep -v '^./docs-project/backlog' | \
  grep -v '^./docs-project/done' | \
  grep -v '^./tmp' | \
  grep -v '^./sessions'
tree -fi | grep -v '^./docs-project/backlog'
grep -rl "if @debug" --include="./lib/**/*.rb" | uniq
grep -rl "puts " --include="./lib/**/*.rb" | uniq
grep -rl "puts " --include="./lib/**/*.rb"
grep -r "puts " --include="./lib/**/*.rb"
grep -r "puts " --include="/lib/**/*.rb"
grep -r "puts " --include="*_spec.rb"
bundle list | grep websocket
git log --grep="cost" -i
git log --grep="cost"
ls ~/.asdf/shims | grep claude
ls ~/.asdf/shims | grep claude-code
node --help | grep shim
brew install ripgrep
history | grep python
grep -v "torch==" requirements.txt > requirements_temp.txt
./build/bin/whisper-cli --help | grep output
cat ~/.config/fish/config.fish | grep deno
asdf list nodejs | grep 21.
asdf list nodejs all | grep 21.
ps aux | grep steam
ps aux | grep python
ls | grep -vE '\d{8}\s'
ls | grep -vE '\d{8}\s.*png'
ls | grep -vE '\d{8}\s.*\.png'
ls | grep -vE '\d{8}\s.*'
ls | grep --only-matching -E '\d{8}\s.*'
ls | grep --only-matching '\d{8}\s.*'
ls | grep --only-matching "/\d{8}\s.*/"
ls | grep --only-matching "\d{8}\s.*"
ls | grep --only-matching "\d{8}\s"
ls | grep --only-matching "d{8}\s.*"
ls | grep --only-matching "d{+8}\s.*"
ls | grep --invert-match "d{+8}\s.*"
tldr grep
ls | grep -v 'd{+8}\s.*'
launchctl list | grep homerow
launchctl list | grep figma | awk '{print $3}' | echo "launchctl dissable $0"
launchctl list | grep figma | awk '{print $3}'
launchctl list | grep figma | awk '{print $3}' | launchctl disable
launchctl list | grep figma
launchctl list | grep com.google
launchctl list | grep google
grep -Ev '^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}' I\ Tested\ 12\ Habit\ Tracker\ Apps\ So\ You\ Don’t\ Have\ To\ \(2023\).vtt > new_file.txt
grep psychmem
history | grep tee
bind -s | grep "\\e\\cf"
bind -s | grep "\e\cf"
bind -s | grep \e\cf
bind -s | grep fzf
bind -X | grep fzf
fd --help
export FIREBASE_TOKEN="1//03Xe62r6_7_gVCgYIARAAGAMSNwF-L9Ir2JBWdh0RMKdLJt5GnPB7yJaI9lA0cafdd7JFp9akOMADuIruwxuoTZExAdEfe8wF6PM"
git show 6d582a48fcc67ff46dfcf2d2def3efd68ac23f2d
nav-path task-new --title "waadafdsdf"
git clean -fdx
git rebase -i fd406e6
git rebase -i 27387b477813457b262ee46e0bb00fc66fd32067
fd406e6 chore: Remove docs-project directory and its contents
        -c:a libfdk_aac -vbr 4 \
git clean -fd
fd
brew install fd bat
