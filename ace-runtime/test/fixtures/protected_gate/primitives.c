/* Linux primitive tests against the shipped C implementation. This deliberately
 * does not call main or claim protected launch acceptance on an unsafe kernel. */
#define main installed_gate_main
#include "worker_gate.c"
#undef main
#include <sys/wait.h>

static void expect_exit(int pid,int expected) {
  int status=0;if(waitpid(pid,&status,0)!=pid||!WIFEXITED(status)||WEXITSTATUS(status)!=expected)exit(1);
}
static void frame_case(const char *bytes,int expected) {
  int pair[2];if(socketpair(AF_UNIX,SOCK_STREAM,0,pair))exit(1);
  int pid=fork();if(pid<0)exit(1);
  if(!pid) {close(pair[0]);json_object *frame=receive(pair[1],now()+1);if(strcmp(str(frame,"operation"),"release"))exit(1);exit(0);}
  close(pair[1]);if(bytes&&write(pair[0],bytes,strlen(bytes))!=(ssize_t)strlen(bytes))exit(1);close(pair[0]);expect_exit(pid,expected);
}
int main(void) {
  frame_case("{\"operation\":\"release\",\"launch_ticket\":\"ticket\"}\n",0);
  frame_case(NULL,125);
  frame_case("{\"operation\":\"release\"}",125);
  frame_case("invalid\n",125);
  int pair[2];if(socketpair(AF_UNIX,SOCK_STREAM,0,pair))exit(1);
  int pid=fork();if(pid<0)exit(1);
  if(!pid){close(pair[0]);receive(pair[1],now()+0.01);exit(1);}close(pair[1]);expect_exit(pid,125);close(pair[0]);
  json_object *groups=json_object_new_array();json_object_array_add(groups,json_object_new_int(13001));
  credentials(getpid(),13001,13001,groups);json_object_put(groups);
  puts("installed C primitives: valid frame, EOF, partial-frame EOF, malformed JSON, deadline, real UID/groups/empty capabilities/NoNewPrivs checks passed");
  return 0;
}
