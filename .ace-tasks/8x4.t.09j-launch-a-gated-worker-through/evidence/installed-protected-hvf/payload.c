#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
int main(void){ int fd=open("/run/ace-payload-starts",O_WRONLY|O_APPEND); if(fd<0)return 2; dprintf(fd,"%d %s %s\n",getpid(),getenv("ACE_ASSIGN_ASSIGNMENT_ID"),getenv("ACE_ASSIGN_ATTEMPT_ID"));close(fd);sleep(60);return 0; }
