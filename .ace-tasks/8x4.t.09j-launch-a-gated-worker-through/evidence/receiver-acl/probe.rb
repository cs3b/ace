require 'json'
module Ace; module Runtime; class RuntimeUnavailableError < StandardError; end; end; end
require_relative 'posix_acl'
acl=Ace::Assign::Authority::PosixAcl.new
rows=[]
def actual(uid,group,path)
  system('setpriv','--reuid='+uid.to_s,'--regid='+group.to_s,'--groups='+group.to_s,'/usr/bin/test','-x',path)
end
[['authority_group_only',nil,false],['named_executor','u:13005:--x',true],['masked_executor','u:13005:--x,m::r--',false],['named_deny_over_other','u:13005:---,m::r-x,o::--x',false]].each do |name,entry,expected|
  system('setfacl','-b','/fixture/ancestor',exception:true)
  File.chmod(0750,'/fixture/ancestor')
  system('setfacl','-m',entry,'/fixture/ancestor',exception:true) if entry
  observed=acl.searchable?('/fixture/ancestor',stat:File.lstat('/fixture/ancestor'),uid:13005,groups:[13005])
  kernel=actual(13005,13005,'/fixture/ancestor')
  raise [name,observed,kernel].inspect unless observed==expected && kernel==expected
  rows << {case:name,acl_evaluation:observed,actual_executor_kernel_search:kernel,acl:acl.entries('/fixture/ancestor')}
end
puts JSON.generate({verdict:'actual_linux_acl_matched',kernel:`uname -r`.strip,cases:rows})
