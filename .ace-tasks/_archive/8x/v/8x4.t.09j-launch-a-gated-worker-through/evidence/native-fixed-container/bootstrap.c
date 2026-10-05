/* Native creation shape fixture only: no protected launch acceptance. */
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
int main(int argc,char **argv){
  if(argc!=3)return 125;
  int fd=open("/tmp/native-bootstrap-starts",O_WRONLY|O_CREAT|O_APPEND,0600);
  if(fd<0)return 1;
  dprintf(fd,"%d %s %s\n",getpid(),argv[1],argv[2]);close(fd);
  sleep(60);return 0;
}
