/* Linux primitive tests against the shipped C implementation. This deliberately
 * does not call main or claim protected launch acceptance on an unsafe kernel. */
#define main installed_gate_main
#include "worker_gate.c"
#undef main
#include <sys/wait.h>
#include <sys/syscall.h>

static void expect_exit(int pid,int expected) {
  int status=0;if(waitpid(pid,&status,0)!=pid||!WIFEXITED(status)||WEXITSTATUS(status)!=expected)exit(1);
}
static void frame_case(const char *bytes,int expected) {
  int pair[2];if(socketpair(AF_UNIX,SOCK_STREAM,0,pair))exit(1);
  int pid=fork();if(pid<0)exit(1);
  if(!pid) {close(pair[0]);json_object *frame=receive(pair[1],now()+1);if(strcmp(str(frame,"operation"),"release"))exit(1);exit(0);}
  close(pair[1]);if(bytes&&write(pair[0],bytes,strlen(bytes))!=(ssize_t)strlen(bytes))exit(1);close(pair[0]);expect_exit(pid,expected);
}
static void kernel_identity_case(void) {
  char path[96];snprintf(path,sizeof(path),"/tmp/ace-gate-primitives-%d",getpid());
  int listener=socket(AF_UNIX,SOCK_STREAM|SOCK_CLOEXEC,0);if(listener<0)exit(1);
  struct sockaddr_un address={.sun_family=AF_UNIX};strcpy(address.sun_path,path);
  if(bind(listener,(struct sockaddr*)&address,sizeof(address))||listen(listener,1))exit(1);
  int held[2];if(pipe(held))exit(1);
  int pid=fork();if(pid<0)exit(1);
  if(!pid){close(held[1]);close(listener);int client=socket(AF_UNIX,SOCK_STREAM,0);
    if(client<0||connect(client,(struct sockaddr*)&address,sizeof(address)))exit(1);
    char byte;if(read(held[0],&byte,1)!=0)exit(1);close(client);exit(0);}
  close(held[0]);int peer=accept(listener,NULL,NULL);if(peer<0)exit(1);
  struct ucred credential;socklen_t size=sizeof(credential);
  if(getsockopt(peer,SOL_SOCKET,SO_PEERCRED,&credential,&size)||credential.pid!=pid||credential.uid!=13001||credential.gid!=13001)exit(1);
  int handle=(int)syscall(SYS_pidfd_open,pid,0);if(handle<0)exit(1);
  struct pollfd watch={.fd=handle,.events=POLLIN};if(poll(&watch,1,0)!=0)exit(1);
  close(held[1]);expect_exit(pid,0);if(poll(&watch,1,1000)!=1||!(watch.revents&POLLIN))exit(1);
  close(handle);close(peer);close(listener);unlink(path);
}
int main(void) {
  kernel_identity_case();
  frame_case("{\"operation\":\"release\",\"launch_ticket\":\"ticket\"}\n",0);
  frame_case(NULL,125);
  frame_case("{\"operation\":\"release\"}",125);
  frame_case("invalid\n",125);
  int pair[2];if(socketpair(AF_UNIX,SOCK_STREAM,0,pair))exit(1);
  int pid=fork();if(pid<0)exit(1);
  if(!pid){close(pair[0]);receive(pair[1],now()+0.01);exit(1);}close(pair[1]);expect_exit(pid,125);close(pair[0]);
  json_object *groups=json_object_new_array();json_object_array_add(groups,json_object_new_int(13001));
  credentials(getpid(),13001,13001,groups);json_object_put(groups);
  puts("installed C primitives: valid frame, EOF, partial-frame EOF, malformed JSON, deadline, SO_PEERCRED exact child, pidfd live/exit, real UID/groups/empty capabilities/NoNewPrivs checks passed");
  return 0;
}
