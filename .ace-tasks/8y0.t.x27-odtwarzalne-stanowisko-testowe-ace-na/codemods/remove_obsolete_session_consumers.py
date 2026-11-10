"""One-time removal of superseded system-session consumers; ordinary owners stay."""
from pathlib import Path
import re

def methods(path, names):
    p=Path(path); text=p.read_text()
    for name in names:
        text=re.sub(r'(?m)^([ ]*)def '+name+r'\b[^\n]*\n.*?^\1end\n', '', text, flags=re.S|re.M)
    p.write_text(text)

p=Path('ace-overseer/lib/ace/overseer/molecules/project_sessions.rb')
s=p.read_text().replace('require_relative "isolated_runtime"\n','')
a=s.index('          if IsolatedRuntime.enabled?'); b=s.index('          tabs = @control.list_tabs', a)
s=s[:a]+s[b:];p.write_text(s)
methods(p,['isolated_row'])
for path,names in {
 'ace-herdr/test/fast/organisms/control_surface_test.rb':['test_isolated_\\w+'],
 'ace-herdr/test/fast/molecules/installed_pi_extensions_test.rb':['test_isolated_\\w+'],
 'ace-herdr/test/fast/molecules/herdr_executor_test.rb':['test_isolated_\\w+'],
 'ace-overseer/test/fast/molecules/project_sessions_test.rb':['isolated_observer','test_isolated_\\w+'],
 'ace-overseer/test/fast/organisms/report_processor_test.rb':['test_isolated_\\w+'],
}.items(): methods(path,names)
p=Path('ace-overseer/lib/ace/overseer/organisms/report_processor.rb');s=p.read_text()
s=s.replace('            if ENV["ACE_LAB_SESSION"] == "1"\n              return isolated_continuation(manager, next_step)\n            end\n','')
p.write_text(s);methods(p,['isolated_continuation'])
