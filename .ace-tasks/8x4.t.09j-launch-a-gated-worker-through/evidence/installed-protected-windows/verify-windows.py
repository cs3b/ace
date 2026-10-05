import pathlib,json,sys
log=pathlib.Path(sys.argv[1]).read_text(errors='replace')
rows=[json.loads(line[len('ACE_INSTALLED_PROOF '):]) for line in log.splitlines() if line.startswith('ACE_INSTALLED_PROOF ')]
assert len(rows)==1, 'exactly one complete proof required'
p=rows[0]
assert 'failure' not in p and p['verdict']=='expanded_installed_cases_passed'
assert p['source_head']=='e2d3dad3e3c93247e0d741ddaef3cf07cddaa46f'
assert p['kernel']=='6.1.0-53-arm64' and p['boot_id']!=p['outer_kernel']['boot_id']
for name in ('hostile_worker','gated_child_memory_write'):
 for api in ('process_vm_readv','process_vm_writev'):
  assert p[name][api]=={'result':-1,'errno':1}, (name,api)
 assert p[name]['process_mem_write'] in (1,13)
windows=p['additional_windows']
assert set(windows)=={'lostreserve','prespawn','spawncrash','recordcrash','recordreplycrash','bindreplycrash','lostrecord','lostbind'}
for name in ('lostreserve','prespawn','spawncrash'):
 row=windows[name];assert row['before']==row['final'] and row['final']['phase']=='reserved'
 assert 'process_binding' not in row['final'] and row['payload_count']==2
for name in ('recordcrash','recordreplycrash','bindreplycrash'):
 row=windows[name];assert row['final']['phase']=='failed' and row['payload_count']==2
 assert row['final']['abort_observation']['release']=='not_issued'
for count,name in ((3,'lostrecord'),(4,'lostbind')):
 row=windows[name];assert row['final']['phase']=='issued' and row['payload_count']==count
restart=p['native_server_restart']
assert restart['old_server']['started_at']!=restart['new_server']['started_at']
assert restart['old_socket']!=restart['new_socket']
assert restart['stale_mapping']==restart['missing_launcher_acl']==restart['unrelated_uid']=='refused'
assert restart['mapped_launcher']=='public launch issued'
assert len(restart['fresh_child'])==1
binding=restart['canonical']['process_binding']
assert binding['process_identity']['pid']==restart['fresh_child'][0]['pid']
assert binding['process_identity']['parent_pid']==restart['new_server']['pid']
assert binding['native_origin']['server_identity']==restart['new_server']
assert binding['native_origin']['socket_identity']==restart['new_socket']
assert binding['native_origin']['workspace']==restart['installed_workspace']
pathlib.Path(sys.argv[2]).write_text(json.dumps(p,indent=2)+'\n')
print('PASS remaining-window/native-restart proof; startup interval remains explicitly observationally unmeasured')
