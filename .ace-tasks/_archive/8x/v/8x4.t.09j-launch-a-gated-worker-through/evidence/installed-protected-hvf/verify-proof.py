import json,pathlib,sys
log=pathlib.Path(sys.argv[1]).read_text()
records=[json.loads(line[20:]) for line in log.splitlines() if line.startswith('ACE_INSTALLED_PROOF ')]
if len(records)!=1:raise SystemExit('expected exactly one completed fixture proof')
proof=records[0]
if 'failure' in proof or proof.get('verdict')!='expanded_installed_cases_passed':raise SystemExit(proof.get('failure','fixture did not pass'))
required=['launcherloss','lostrelease','lostcreation','issued_child_exit','authority_crash_recovery','worker_native_gate_mimic','native_endpoint_replacement','closed_installed_container','dac_override_bounding','capability_bounding','no_new_privs_missing','post_exec_suid']
missing=[key for key in required if key not in proof]
if missing:raise SystemExit('missing expanded acceptance cases: '+str(missing))
assert proof['source_head']=='e2d3dad3e3c93247e0d741ddaef3cf07cddaa46f'
assert proof['kernel']=='6.1.0-53-arm64' and proof['kernel']!=proof['outer_kernel']['kernel'] and proof['boot_id']!=proof['outer_kernel']['boot_id']
assert proof['canonical_phases']==['registered','reserved','recorded','bound','issued']
pathlib.Path(sys.argv[2]).write_text(json.dumps(proof,indent=2)+'\n')
print('PASS expanded installed protected launch fixture; actual Lab/gad.2 remains separate')
