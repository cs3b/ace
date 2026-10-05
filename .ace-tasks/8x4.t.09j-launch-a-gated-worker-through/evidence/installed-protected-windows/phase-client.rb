# Fixture orchestrates actual installed public client/native operations, no policy overrides.
require 'json'
require 'digest'
require 'ace/assign'
require 'ace/assign/authority/client'
require 'ace/herdr/molecules/protected_native_control'
mode=ARGV.fetch(0)
kernel=Ace::Runtime::Molecules::ProtectedLinux.new
deployment=Ace::Assign::Authority::Deployment.load
map=deployment.mapping('mapping')
client=Ace::Assign::Authority::Client.new(mapping_id:'mapping',deployment:deployment,kernel:kernel)
native=Ace::Herdr::Molecules::ProtectedNativeControl.new(mapping:map,kernel:kernel)
id="fixture-#{mode}"
definition=JSON.parse(File.read('/etc/ace/definition.json')).merge('session_id'=>id)
bytes=JSON.generate(definition)
registered=client.call('register_assignment',{'assignment_id'=>id,'definition_bytes'=>bytes,'definition_digest'=>Digest::SHA256.hexdigest(bytes),'expected_generation'=>0},mutation_id:"#{mode}-register").data
params={'assignment_id'=>id,'scope'=>'010','worker_uid'=>13001,'runtime'=>'herdr','base_head'=>ARGV.fetch(1),'launcher_process_binding'=>kernel.capture(Process.pid),'expected_generation'=>registered.fetch('definition_generation')}
drop=->(operation,input,suffix) do
  socket=UNIXSocket.new(deployment.authority('authority').fetch('socket_path'))
  socket.write(JSON.generate({'version'=>1,'operation'=>operation,'mutation_id'=>"#{mode}-#{suffix}",'project_id'=>'project','params'=>input.merge('mapping_id'=>'mapping')})+"\n")
  socket.close
  sleep 0.3
end
if mode=='lostreserve'
  drop.call('reserve_attempt',params,'reserve')
end
reserved=client.call('reserve_attempt',params,mutation_id:"#{mode}-reserve")
if mode=='lostreserve'
  raise 'lost reserve falsely fresh' unless reserved.replayed
  puts "ACE_CASE #{JSON.generate({mode:mode,state:reserved.data,replayed:true})}"
  STDOUT.flush
  exit
end
state=reserved.data
if mode=='lostcreation'
  command=[map.fetch('bootstrap'),'mapping',state.fetch('launch_ticket')]
  socket=UNIXSocket.new(map.fetch('native').fetch('socket_path'))
  socket.write(JSON.generate({'id'=>'lostcreation','method'=>'layout.apply','params'=>{'workspace_id'=>map.fetch('native').fetch('workspace_id'),'focus'=>false,'root'=>{'type'=>'pane','cwd'=>map.fetch('worker_cwd'),'command'=>command}}})+"\n")
  socket.close
  sleep 0.3
  replay=client.call('reserve_attempt',params,mutation_id:"#{mode}-reserve")
  raise 'reservation replay falsely fresh' unless replay.replayed && replay.data==reserved.data
  puts "ACE_CASE #{JSON.generate({mode:mode,state:state,replayed:replay.replayed})}"
  STDOUT.flush
  sleep 1
  exit
end
if mode=='prespawn'
  puts "ACE_CASE #{JSON.generate({mode:mode,state:state})}";STDOUT.flush;sleep 60;exit
end
binding=native.create(mapping_id:'mapping',ticket:state.fetch('launch_ticket'))
life=->(value){value.slice('assignment_id','attempt_id','launch_ticket').merge('process_binding'=>binding,'expected_generation'=>value.fetch('generation'))}
if mode=='spawncrash'
  puts "ACE_CASE #{JSON.generate({mode:mode,state:state,binding:binding})}";STDOUT.flush;sleep 60;exit
end
if %w[lostrecord recordreplycrash].include?(mode)
  drop.call('record_launch',life.call(state),'record')
end
recorded=client.call('record_launch',life.call(state),mutation_id:"#{mode}-record").data
if %w[lostrecord recordreplycrash].include?(mode)
  replay=client.call('record_launch',life.call(state),mutation_id:"#{mode}-record")
  raise 'record replay changed' unless replay.replayed && replay.data==recorded
end
if %w[recordcrash recordreplycrash].include?(mode)
  puts "ACE_CASE #{JSON.generate({mode:mode,state:recorded,binding:binding})}";STDOUT.flush;sleep 60;exit
end
if %w[lostbind bindreplycrash].include?(mode)
  drop.call('bind_process',life.call(recorded),'bind')
end
bound=client.call('bind_process',life.call(recorded),mutation_id:"#{mode}-bind").data
puts "ACE_CASE #{JSON.generate({mode:mode,state:bound,binding:binding})}"
STDOUT.flush
if %w[lostbind bindreplycrash].include?(mode)
  replay=client.call('bind_process',life.call(recorded),mutation_id:"#{mode}-bind")
  raise 'bind replay changed' unless replay.replayed && replay.data==bound
end
if %w[launcherloss authorityloss bindreplycrash].include?(mode)
  sleep 60
elsif %w[lostrecord lostbind].include?(mode)
  released=client.call('release_launch',life.call(bound),mutation_id:"#{mode}-release")
  raise 'release not issued' unless released.data['phase']=='issued'
elsif mode=='lostrelease' 
  request={'version'=>1,'operation'=>'release_launch','mutation_id'=>"#{mode}-release",'project_id'=>'project','params'=>life.call(bound).merge('mapping_id'=>'mapping')}
  socket=UNIXSocket.new(deployment.authority('authority').fetch('socket_path'))
  socket.write(JSON.generate(request)+"\n")
  socket.close # Deliberate reply loss; never infer no execution.
  sleep 0.5
  replay=client.call('release_launch',life.call(bound),mutation_id:"#{mode}-release")
  raise 'release replay not canonical issued' unless replay.replayed && replay.data['phase']=='issued'
  puts "ACE_CASE #{JSON.generate({mode:mode,state:replay.data,replayed:true})}"
  STDOUT.flush
end
