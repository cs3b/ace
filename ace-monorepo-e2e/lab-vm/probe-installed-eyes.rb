# frozen_string_literal: true

# Run in a disposable Linux VM as the session account with GEM_HOME and
# GEM_PATH selecting the installed candidate and its installed dependencies.
# The Herdr response and Pi transcript are synthetic; the Node process and
# its birth identity are real. This does not control a Herdr session.
require "json"
require "tmpdir"

abort "usage: ruby probe-installed-eyes.rb NODE HERDR COWORKER LAB WAKE OVERSEER" unless ARGV.length == 6
node, *versions = ARGV
abort "node must be an absolute executable" unless node.start_with?("/") && File.executable?(node)
%w[ace-herdr ace-coworker ace-lab ace-wake ace-overseer].zip(versions).each do |name, version|
  gem name, "= #{version}"
end
require "ace/overseer/molecules/eyes_session_evidence"
require "ace/wake"

Result = Struct.new(:parsed_json)
class ProbeExecutor
  def initialize(path, pid)
    @path, @pid = path, pid
  end

  def pane_get(_pane)
    Result.new({"result" => {"pane" => {"pane_id" => "w1:p1", "terminal_id" => "term", "agent" => "pi",
      "agent_session" => {"agent" => "pi", "kind" => "path", "value" => @path}}}})
  end

  def pane_process_info(_pane)
    Result.new({"result" => {"process_info" => {"foreground_processes" => [{"pid" => @pid}]}}})
  end
end

module_url = "file://" + File.join(Ace::Wake.extension_root, "wake/eyes-runtime.js")
script = <<~JS
  import fs from "node:fs";
  import {eyesProcessIdentity} from #{JSON.generate(module_url)};
  const [dir,path,id] = process.argv.slice(1), identity = eyesProcessIdentity();
  const now=Date.now(), promptAt=new Date(now-1000).toISOString();
  const rows=[
    {type:"session",version:3,id,cwd:dir},
    {type:"custom",id:"binding",parentId:null,customType:"ace-wake-eyes-binding",data:{ownerCwd:dir,process:identity}},
    {type:"message",id:"prompt",parentId:"binding",timestamp:promptAt,message:{role:"user",content:"first"}},
    {type:"message",id:"response",parentId:"prompt",message:{role:"assistant",stopReason:"stop"}},
    {type:"custom",id:"eyes",parentId:"response",customType:"ace-wake-eyes",data:{ownerCwd:dir,enabled:true,retired:false,breaker:null,errors:0,config:{intervalSeconds:30,timeoutMs:60000},observerEvidence:{process:identity,observedAt:now,sources:{tasks:"ok"}}}}
  ];
  fs.writeFileSync(path,rows.map(row=>JSON.stringify(row)).join("\\n")+"\\n",{mode:0o600});
  console.log(JSON.stringify(identity));
  setInterval(()=>{},1000);
JS

Dir.mktmpdir("ace-eyes-probe-") do |dir|
  id = "01234567-89ab-cdef-0123-456789abcdef"
  path = File.join(dir, "2026-01-01_#{id}.jsonl")
  io = IO.popen([node, "--input-type=module", "-e", script, dir, path, id], "r")
  begin
    abort "node identity probe timed out" unless IO.select([io], nil, nil, 10)
    identity = JSON.parse(io.gets)
    abort "node reported a different process" unless identity.fetch("pid") == io.pid
    reader = Ace::Overseer::Molecules::EyesSessionEvidence.new(executor: ProbeExecutor.new(path, identity.fetch("pid")))
    args = {pane: "w1:p1", root: dir, prompt: "first", required_sources: ["tasks"]}
    abort "live evidence was not accepted" unless reader.ready?(**args)
    Process.kill("TERM", io.pid)
    io.close
    abort "dead process was accepted" if reader.ready?(**args)
    puts "installed live-process session proof accepted; dead process refused (synthetic Herdr binding)"
  ensure
    unless io.closed?
      Process.kill("TERM", io.pid) rescue nil
      io.close
    end
  end
end
