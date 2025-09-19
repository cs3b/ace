Step-by-step playbook: tracking down “coverage drops when I run the whole suite”

Context: plain Ruby gem that uses Zeitwerk to autoload files and SimpleCov to measure coverage.
Symptom: a given file (e.g. lib/.../models.rb) shows ~ 87 % coverage when you run only its spec, but ~ 16 % (or 0 %) when you run the full test suite.

The root cause is always the same: the file gets require-d (or autoloaded) before SimpleCov.start executes in the “whole-suite” run, so its lines are executed with no probe attached.
Below is a systematic way to confirm that and fix it.

⸻

0 . Quick triage checklist

✅ check	how to test	keep if passes?
Is SimpleCov.start truly first?	Put puts "[SC] #{Time.now}" above the call and puts "[FILE] #{__FILE__}" as the first line of lib/.../models.rb. Compare timestamps.	if [FILE] prints before [SC], you’ve found the bug.
Is the file autoloaded by Zeitwerk early?	Run tests with ZEITWERK_LOG=1 or call loader.log! in your loader; watch console.	If the file name scrolls before SimpleCov starts → early autoload.
Any explicit require in helpers?	grep -R "require .*models" spec/ lib/	Remove or move it.
Using Spring / Bootsnap / Zeus?	echo $SPRING_ENABLED, look in bin/ wrappers.	Disable (DISABLE_SPRING=1) for coverage runs.
Multiple Ruby processes? (parallel-tests, RSpec --jobs)	Check CI config for PARALLEL / --jobs.	Make sure every subprocess loads SimpleCov via RUBYOPT (see step 3.b).

If one of those explains the drop, skip the rest; otherwise dig deeper.

⸻

1 . Reproduce & collect evidence
	1.	Run two commands and jot the numbers.

rm -rf coverage
bundle exec rspec spec/models/models_spec.rb   # single

rm -rf coverage
bundle exec rspec                              # whole


	2.	Open coverage/.resultset.json (it’s just JSON).
Compare the "coverage" entry for lib/.../models.rb between the two runs—this tells you exactly which lines SimpleCov thinks were executed.
	3.	Optional: use trace-require to log load order.

RUBYOPT='-rtrace_require' bundle exec rspec 2>&1 | grep models.rb

If models.rb appears before any “simplecov” lines, you know it loaded too soon.

⸻

2 . Probable causes and targeted fixes

cause (ordered by frequency)	fix	how to verify the fix
SimpleCov.start is not first (another helper required earlier)	Moverequire "simplecov"; SimpleCov.start to the very top of the first file that gets executed.💡 Safe pattern:spec/simplecov_boot.rb → then RUBYOPT="-r./spec/simplecov_boot"	‣ Re-run full suite; coverage for the file ≥ single-spec run.‣ puts "[DBG]" timestamps show SimpleCov first.
Early explicit require inside any helper/spec	Delete it or move it after SimpleCov.start.	grep shows no earlier require; log shows models.rb loads later.
Zeitwerk eager-load (loader.eager_load, or `Dir[…] {	f	require f }`)
Eager-load by test environment variable (ENV['CI'] etc.)	Gate the code, or set the var only where needed.	Suite passes with coverage restored.
Pre-loader (Spring/Zeus/bootsnap)	Disable for coverage run (DISABLE_SPRING=1, BUNDLE_DISABLE_SHARED_GEMS=1); or ensure pre-loader itself requires simplecov_boot.rb.	Run bundle exec spring status (should say “not running”) and re-run tests.
Parallel test processes	Load SimpleCov in every subprocess via RUBYOPT. Example:export RUBYOPT="-r./spec/simplecov_boot $RUBYOPT" before parallel_test.	Per-process HTML reports show similar numbers.
Old .resultset.json being merged	Add to spec/simplecov_boot.rb:SimpleCov.merge_timeout 0 or SimpleCov.at_exit { SimpleCov.result.format! } to regenerate fresh; or rm coverage/.resultset.json before each run.	Numbers stop flickering between runs.


⸻

3 . Bullet-proof configuration pattern (gem + Zeitwerk)

# spec/simplecov_boot.rb ---------------------------------
require "simplecov"
SimpleCov.start do
  # ALWAYS count every lib file – avoids denominator swings
  track_files "lib/**/*.rb"      #  [oai_citation:0‡RubyDoc](https://www.rubydoc.info/gems/simplecov/SimpleCov%2FConfiguration%3Atrack_files?utm_source=chatgpt.com)
end
# --------------------------------------------------------

# .rspec (or your test runner wrapper)
--require ./spec/simplecov_boot   # loads *before* anything else
--require ./spec/spec_helper      # loads after coverage is on

# lib/my_gem.rb  (Zeitwerk loader)
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.log! if ENV["ZEITWERK_LOG"]      # good for debugging   [oai_citation:1‡GitHub](https://github.com/fxn/zeitwerk?utm_source=chatgpt.com)
loader.setup

Now:

rm -rf coverage
bundle exec rspec                  # full suite
open coverage/index.html           # file shows high %


⸻

4 . Deep-debugging toolbox (when it’s still weird)
	•	TracePoint

TracePoint.trace(:require) { |tp| p tp.path if tp.path.end_with?("models.rb") }

Stops the run the moment the file loads.

	•	Coverage.peek_result
Call this in an after(:suite) hook and inspect the hash for the file key.
	•	Environment sanity
ruby -e 'puts RUBYOPT, $LOAD_PATH.to_a' inside your test command to ensure the boot file is there.
	•	loader.preload callbacks
Add loader.on_load { |c, p| puts "[LOAD] #{p}" } to see whether any constant triggers the file early.
	•	Minimal reproduction
Comment out spec folders until coverage stabilises; the last uncommented file is your offender.

⸻

5 . Verification matrix

action	what you should see	what it proves
ZEITWERK_LOG=1 bundle exec rspec	Log lines for models.rb after “SimpleCov started” message	loader no longer autoloads too early
bundle exec rspec spec/models/models_spec.rb vs. full suite	Same (or ±1-2 %) coverage % for the file	fix works
Delete coverage/, run CI	Stable numbers across local/CI	no environment-specific preloaders left


⸻

Key take-away

Start SimpleCov first; load everything else later.
That single ordering rule (documented in SimpleCov’s README)  ￼ removes ~90 % of “coverage drops” you’ll ever see. The playbook above walks you through confirming that fact, finding the line that breaks the rule, and rerunning until the file’s coverage no longer depends on how many specs you execute.
