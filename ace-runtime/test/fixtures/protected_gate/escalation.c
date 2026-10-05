/* Isolated root-owned setuid fixture: NoNewPrivs must preserve worker identity. */
#define main installed_gate_main
#include "worker_gate.c"
#undef main
int main(void) {
  json_object *groups=json_object_new_array();
  json_object_array_add(groups,json_object_new_int(13001));
  credentials(getpid(),13001,13001,groups);
  json_object_put(groups);
  puts("post-exec setuid fixture retained worker IDs, empty capabilities and NoNewPrivs");
  return 0;
}
