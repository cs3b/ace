#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <json-c/json.h>
#include <poll.h>
#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/provider.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>
#include <grp.h>

#define MAP_PATH "/etc/ace/assignment-authorities.json"
#define LIMIT 65536
static _Noreturn void deny(const char *why) { fprintf(stderr, "ace-worker-gate: %s\n", why); exit(125); }
static double now(void) { struct timespec ts; if (clock_gettime(CLOCK_MONOTONIC,&ts)) deny("clock unavailable"); return ts.tv_sec + ts.tv_nsec / 1e9; }
static int token(const char *s) {
  if (!s || !*s || strlen(s)>128) return 0;
  if(!((s[0]>='a'&&s[0]<='z')||(s[0]>='A'&&s[0]<='Z')||(s[0]>='0'&&s[0]<='9')))return 0;
  for (const unsigned char *p=(const unsigned char *)s; *p; p++)
    if (!((*p>='a'&&*p<='z')||(*p>='A'&&*p<='Z')||(*p>='0'&&*p<='9')||*p=='_'||*p=='-'||*p=='.')) return 0;
  return 1;
}
static json_object *field(json_object *o,const char *k,enum json_type t) {
  json_object *v=NULL;
  if (!o || !json_object_object_get_ex(o,k,&v) || !json_object_is_type(v,t)) deny("invalid protected schema");
  return v;
}
static const char *str(json_object *o,const char *k) {
  json_object *value=field(o,k,json_type_string);const char *text=json_object_get_string(value);
  if((size_t)json_object_get_string_len(value)!=strlen(text))deny("embedded NUL in protected string");
  return text;
}
static int number(json_object *o,const char *k) {
  int64_t n=json_object_get_int64(field(o,k,json_type_int));
  if (n<=0 || n>2147483647) deny("invalid principal identity");
  return (int)n;
}
static void trusted_path(const char *path,int dir,uid_t owner) {
  char copy[4097]; size_t n=strlen(path); struct stat st;
  if (!n || n>=sizeof(copy) || path[0]!='/' || strstr(path,"//") || strstr(path,"/../") || strstr(path,"/./") ||
      !strcmp(path+n-1,"/") || !strcmp(path+n-(n>=3?3:n),"/..")) deny("invalid protected path");
  memcpy(copy,path,n+1);
  for (size_t i=1;i<=n;i++) if (copy[i]=='/' || i==n) {
    char c=copy[i]; copy[i]=0;
    if (lstat(copy,&st) || (i==n ? st.st_uid!=owner : (st.st_uid!=0 && st.st_uid!=owner)) || (st.st_mode&022) || S_ISLNK(st.st_mode) ||
        (i<n&&!S_ISDIR(st.st_mode))) deny("protected path is writable or replaced");
    copy[i]=c;
  }
  if (dir && !S_ISDIR(st.st_mode)) deny("protected directory unavailable");
  if (!dir && !S_ISREG(st.st_mode)) deny("protected file unavailable");
}
static void root_path(const char *path,int dir) { trusted_path(path,dir,0); }
static char *read_file(const char *path,size_t max) {
  int fd=open(path,O_RDONLY|O_CLOEXEC|O_NOFOLLOW); if(fd<0) deny("policy file unavailable");
  char *s=calloc(max+1,1); if(!s) deny("allocation failed"); size_t n=0;
  while(n<max) { ssize_t r=read(fd,s+n,max-n); if(r<0&&errno==EINTR) continue; if(r<0) deny("policy read failed"); if(!r) break; n+=(size_t)r; }
  char extra; if(n==max&&read(fd,&extra,1)!=0) deny("policy file oversized"); close(fd); return s;
}
static void policy(void) {
  char *s=read_file("/proc/sys/kernel/yama/ptrace_scope",16);
  if(strcmp(s,"2\n")&&strcmp(s,"2")) deny("Linux Yama ptrace_scope=2 is required");
  free(s);
}
static void credentials(pid_t pid,int uid,int gid,json_object *groups) {
  char path[64]; snprintf(path,sizeof(path),"/proc/%d/status",pid); char *s=read_file(path,16384);
  int got_uid=0,got_gid=0,caps=0,got_groups=0,no_new_privs=0; char *save=NULL;
  for(char *line=strtok_r(s,"\n",&save);line;line=strtok_r(NULL,"\n",&save)) {
    unsigned a,b,c,d; unsigned long long cap;
    if(sscanf(line,"Uid: %u %u %u %u",&a,&b,&c,&d)==4) { if(a!=(unsigned)uid||b!=a||c!=a||d!=a) deny("UID changed"); got_uid=1; }
    if(sscanf(line,"Gid: %u %u %u %u",&a,&b,&c,&d)==4) { if(a!=(unsigned)gid||b!=a||c!=a||d!=a) deny("GID changed"); got_gid=1; }
    if(sscanf(line,"NoNewPrivs: %u",&a)==1) { if(a!=1)deny("NoNewPrivs=1 is required"); no_new_privs=1; }
    const char *names[]={"CapInh:","CapPrm:","CapEff:","CapBnd:","CapAmb:"};
    for(int i=0;i<5;i++) if(!strncmp(line,names[i],7)) {
      if(sscanf(line+7,"%llx",&cap)!=1 || cap!=0) deny("all capability sets must be empty");
      caps|=1<<i;
    }
    if(!strncmp(line,"Groups:",7)) {
      size_t count=json_object_array_length(groups),index=0; char *end=NULL,*p=line+7;
      while(1) { while(*p==' '||*p=='\t')p++; if(!*p)break; errno=0; long group=strtol(p,&end,10);
        if(errno||end==p||index>=count||!json_object_is_type(json_object_array_get_idx(groups,index),json_type_int)||
           group!=json_object_get_int64(json_object_array_get_idx(groups,index))) deny("supplementary groups changed");
        p=end; index++;
      }
      if(index!=count) deny("supplementary groups changed");
      got_groups=1;
    }
  }
  free(s); if(!got_uid||!got_gid||!got_groups||!no_new_privs||caps!=31)deny("kernel credentials unavailable");
}
struct parent_identity { pid_t pid; char birth[256]; };
static void parent_birth(pid_t pid,char birth[256]) {
  if(pid<=1||getppid()!=pid) deny("original gate parent unavailable");
  char path[64]; snprintf(path,sizeof(path),"/proc/%d/stat",pid); char *s=read_file(path,16384);
  char *end=strrchr(s,')'); if(!end||end[1]!=' ') deny("server birth unavailable");
  char *save=NULL,*word=strtok_r(end+2," ", &save); int i=3; const char *ticks=NULL;
  while(word) { if(i==22){ticks=word;break;} i++;word=strtok_r(NULL," ",&save); }
  if(!ticks||strspn(ticks,"0123456789")!=strlen(ticks))deny("server birth unavailable");
  char *boot=read_file("/proc/sys/kernel/random/boot_id",128); boot[strcspn(boot,"\n")]=0;
  int written=snprintf(birth,256,"linux:%s:%s",boot,ticks);
  if(written<0||written>=256)deny("parent birth oversized");
  free(boot);free(s);
  if(getppid()!=pid)deny("original gate parent changed");
}
static void same_parent(const struct parent_identity *parent) {
  char birth[256];parent_birth(parent->pid,birth);
  if(strcmp(birth,parent->birth))deny("original gate parent incarnation changed");
}
static void parent_credentials(const struct parent_identity *parent,json_object *mapping) {
  same_parent(parent);
  credentials(parent->pid,number(mapping,"worker_uid"),number(mapping,"worker_gid"),field(mapping,"worker_groups",json_type_array));
  same_parent(parent);
}
static void closed(json_object *object,const char *const *keys,size_t count) {
  if(!json_object_is_type(object,json_type_object)||(size_t)json_object_object_length(object)!=count)deny("open protected schema");
  for(size_t i=0;i<count;i++) { json_object *value=NULL;if(!json_object_object_get_ex(object,keys[i],&value))deny("incomplete protected schema"); }
}
static void hex_field(json_object *object,const char *key,size_t min,size_t max) {
  const char *value=str(object,key);size_t length=(size_t)json_object_get_string_len(field(object,key,json_type_string));
  if(length!=strlen(value)||(length!=min&&length!=max)||strspn(value,"0123456789abcdef")!=length)deny("invalid protected digest");
}
static void bounded_integer(json_object *object,const char *key,int64_t max) {
  int64_t value=json_object_get_int64(field(object,key,json_type_int));
  if(value<1||value>max)deny("invalid prepared bound");
}
static void entry_reference(json_object *reference,int64_t limit) {
  static const char *const keys[]={"path","bytes","sha256"};
  closed(reference,keys,3);bounded_integer(reference,"bytes",limit);hex_field(reference,"sha256",64,64);
  const char *path=str(reference,"path");size_t n=strlen(path);
  if(n<2||n>4096||path[0]!='/'||path[n-1]=='/'||strstr(path,"//")||strstr(path,"/./")||strstr(path,"/../")||
     !strcmp(path+n-2,"/.")||(n>=3&&!strcmp(path+n-3,"/..")))deny("invalid worker reference path");
}
static void worker_entry(json_object *entry) {
  static const char *const keys[]={"interpreter","wrapper"};closed(entry,keys,2);
  entry_reference(field(entry,"interpreter",json_type_object),33554432);
  entry_reference(field(entry,"wrapper",json_type_object),1048576);
}
static void prepared_permission(json_object *permission) {
  static const char *const permission_keys[]={"operation","launch_ticket","attempt_id","assignment_id","generation","journal_commit","prepared_input"};
  closed(permission,permission_keys,7);hex_field(permission,"journal_commit",40,64);
  json_object *input=field(permission,"prepared_input",json_type_object);
  static const char *const input_keys[]={"registration_generation","registration_commit","definition_digest","original_binding_digest","prepared_work","bundle_ref","bundle_bytes","bundle_sha256","worker_entry"};
  closed(input,input_keys,9);worker_entry(field(input,"worker_entry",json_type_object));bounded_integer(input,"registration_generation",INT64_MAX);
  hex_field(input,"registration_commit",40,64);hex_field(input,"definition_digest",64,64);
  hex_field(input,"original_binding_digest",64,64);hex_field(input,"bundle_sha256",64,64);
  bounded_integer(input,"bundle_bytes",64*1024*1024);
  char expected[256];
  int written=snprintf(expected,sizeof(expected),"execution/prepared/%s-%s.bundle",str(permission,"assignment_id"),str(input,"bundle_sha256"));
  if(written<0||(size_t)written>=sizeof(expected)||
      strcmp(expected,str(input,"bundle_ref"))||json_object_get_string_len(field(input,"bundle_ref",json_type_string))!=(int)strlen(expected))deny("prepared bundle reference differs");
  json_object *work=field(input,"prepared_work",json_type_object);
  static const char *const work_keys[]={"version","task_id","scope","prepared_head","prepared_tree","manifest_bytes","manifest_sha256","selection_sha256"};
  closed(work,work_keys,8);
  const char *task=str(work,"task_id");size_t task_length=(size_t)json_object_get_string_len(field(work,"task_id",json_type_string));
  if(json_object_get_int64(field(work,"version",json_type_int))!=1||task_length!=strlen(task)||!task_length||task_length>200||
      !((task[0]>='a'&&task[0]<='z')||(task[0]>='A'&&task[0]<='Z')||(task[0]>='0'&&task[0]<='9')))deny("invalid prepared selection");
  for(size_t i=0;i<task_length;i++)if(!((task[i]>='a'&&task[i]<='z')||(task[i]>='A'&&task[i]<='Z')||(task[i]>='0'&&task[i]<='9')||task[i]=='_'||task[i]=='-'||task[i]=='.'))deny("invalid prepared task");
  const char *scope=str(work,"scope");size_t scope_length=(size_t)json_object_get_string_len(field(work,"scope",json_type_string));
  if(scope_length!=strlen(scope)||!scope_length)deny("invalid prepared scope");
  size_t digits=0;
  for(size_t i=0;i<scope_length;i++) {
    if(scope[i]>='0'&&scope[i]<='9')digits++;
    else if(scope[i]=='.'&&digits>0)digits=0;
    else deny("invalid prepared scope");
  }
  if(!digits)deny("invalid prepared scope");
  hex_field(work,"prepared_head",40,64);hex_field(work,"prepared_tree",40,64);
  hex_field(work,"manifest_sha256",64,64);hex_field(work,"selection_sha256",64,64);
  bounded_integer(work,"manifest_bytes",32768);
}
/* First OpenSSL call suppresses config; a private context has only the fixed
   default provider. /dev/null is deliberately not a module directory. */
static EVP_MD *fixed_sha256(OSSL_LIB_CTX **context,OSSL_PROVIDER **provider) {
  if(!OPENSSL_init_crypto(OPENSSL_INIT_NO_LOAD_CONFIG,NULL))deny("digest initialization failed");
  *context=OSSL_LIB_CTX_new();if(!*context||!OSSL_PROVIDER_set_default_search_path(*context,"/dev/null"))deny("digest context failed");
  *provider=OSSL_PROVIDER_load(*context,"default");if(!*provider)deny("fixed digest provider unavailable");
  EVP_MD *digest=EVP_MD_fetch(*context,"SHA256","provider=default");if(!digest)deny("fixed digest unavailable");return digest;
}
static int same_metadata(const struct stat *a,const struct stat *b) {
  return a->st_dev==b->st_dev&&a->st_ino==b->st_ino&&a->st_uid==b->st_uid&&a->st_gid==b->st_gid&&
    a->st_mode==b->st_mode&&a->st_size==b->st_size&&a->st_mtim.tv_sec==b->st_mtim.tv_sec&&
    a->st_mtim.tv_nsec==b->st_mtim.tv_nsec&&a->st_ctim.tv_sec==b->st_ctim.tv_sec&&a->st_ctim.tv_nsec==b->st_ctim.tv_nsec;
}
static int held_entry(json_object *reference,int executable,const EVP_MD *digest,struct stat *verified) {
  const char *path=str(reference,"path");root_path(path,0);
  int fd=open(path,O_RDONLY|O_NONBLOCK|O_NOFOLLOW|O_CLOEXEC);if(fd<0)deny("worker entry unavailable");
  struct stat before,after;
  int64_t expected=json_object_get_int64(field(reference,"bytes",json_type_int));
  if(fstat(fd,&before)||!S_ISREG(before.st_mode)||before.st_uid!=0||(before.st_mode&06022)||before.st_size!=expected||
     (executable&&!(before.st_mode&0111)))deny("unsafe held worker entry");
  unsigned char magic[4];
  if(executable&&(pread(fd,magic,sizeof(magic),0)!=(ssize_t)sizeof(magic)||memcmp(magic,"\177ELF",4)))deny("worker interpreter is not native ELF");
  int snapshot=-1;if(!executable) {snapshot=memfd_create("ace-worker-source",MFD_CLOEXEC|MFD_ALLOW_SEALING);if(snapshot<0)deny("worker snapshot unavailable");}
  EVP_MD_CTX *ctx=EVP_MD_CTX_new();if(!ctx||!EVP_DigestInit_ex(ctx,digest,NULL))deny("worker digest unavailable");
  unsigned char buffer[65536],sum[EVP_MAX_MD_SIZE];size_t total=0;unsigned int sum_size=0;
  for(;;) {
    ssize_t n=read(fd,buffer,sizeof(buffer));if(n<0&&errno==EINTR)continue;if(n<0)deny("held worker read failed");if(!n)break;
    if((int64_t)total+n>expected)deny("held worker entry enlarged");
    if(!EVP_DigestUpdate(ctx,buffer,(size_t)n))deny("worker digest failed");
    total+=(size_t)n;
    if(snapshot>=0) {size_t offset=0;while(offset<(size_t)n) {ssize_t written=write(snapshot,buffer+offset,(size_t)n-offset);
      if(written<0&&errno==EINTR)continue;
      if(written<=0)deny("worker snapshot write failed");
      offset+=(size_t)written;}}
  }
  if(total!=(size_t)expected||!EVP_DigestFinal_ex(ctx,sum,&sum_size)||sum_size!=32||fstat(fd,&after)||!same_metadata(&before,&after))deny("held worker entry changed");
  EVP_MD_CTX_free(ctx);char hex[65];for(unsigned int i=0;i<32;i++)snprintf(hex+i*2,3,"%02x",sum[i]);
  if(strcmp(hex,str(reference,"sha256")))deny("held worker digest differs");
  *verified=after;
  if(executable) {if(lseek(fd,0,SEEK_SET)<0)deny("worker interpreter seek failed");return fd;}
  close(fd);
  int seals=F_SEAL_WRITE|F_SEAL_GROW|F_SEAL_SHRINK|F_SEAL_SEAL;
  if(fcntl(snapshot,F_ADD_SEALS,seals)||fcntl(snapshot,F_GET_SEALS)!=seals)deny("worker snapshot sealing failed");
  char descriptor[64];snprintf(descriptor,sizeof(descriptor),"/proc/self/fd/%d",snapshot);
  int readonly=open(descriptor,O_RDONLY|O_CLOEXEC);if(readonly<0)deny("readonly worker snapshot unavailable");
  struct stat sealed,reopened;
  if(fstat(snapshot,&sealed)||fstat(readonly,&reopened)||sealed.st_dev!=reopened.st_dev||sealed.st_ino!=reopened.st_ino||
    reopened.st_size!=expected||fcntl(readonly,F_GET_SEALS)!=seals)deny("worker snapshot identity differs");
  *verified=reopened;
  close(snapshot);return readonly;
}
static void select_entry_descriptors(int interpreter,int wrapper) {
  int held_interpreter=fcntl(interpreter,F_DUPFD_CLOEXEC,6),held_wrapper=fcntl(wrapper,F_DUPFD_CLOEXEC,6);
  if(held_interpreter<0||held_wrapper<0)deny("worker descriptor reservation failed");
  close(interpreter);close(wrapper);
  if(dup2(held_interpreter,4)!=4||dup2(held_wrapper,5)!=5||fcntl(4,F_SETFD,0)||fcntl(5,F_SETFD,0))deny("worker descriptor selection failed");
  close(held_interpreter);close(held_wrapper);
}
static void wait_fd(int fd,short events,double deadline) {
  struct pollfd p={.fd=fd,.events=events}; int r;
  do {
    double remaining=deadline-now(); if(remaining<=0)deny("authority deadline expired");
    r=poll(&p,1,(int)(remaining*1000));
  }while(r<0&&errno==EINTR);
  if(r<=0 || (p.revents&(POLLERR|POLLNVAL)))deny("authority stream unavailable");
}
static void send_frame(int fd,json_object *o,double deadline) {
  const char *s=json_object_to_json_string_ext(o,JSON_C_TO_STRING_PLAIN); size_t n=strlen(s);
  if(n+1>LIMIT)deny("request oversized");
  char *frame=malloc(n+2); if(!frame)deny("allocation failed");
  memcpy(frame,s,n);frame[n++]='\n';size_t offset=0;
  while(offset<n) { wait_fd(fd,POLLOUT,deadline); ssize_t r=send(fd,frame+offset,n-offset,MSG_NOSIGNAL);
    if(r<0&&(errno==EINTR||errno==EAGAIN))continue;
    if(r<=0)deny("authority write failed");
    offset+=(size_t)r; }
  free(frame);
}
static json_object *receive(int fd,double deadline) {
  char *s=calloc(LIMIT+1,1); if(!s)deny("allocation failed"); size_t n=0;
  while(n<LIMIT) { wait_fd(fd,POLLIN,deadline); ssize_t r=recv(fd,s+n,1,0);
    if(r<0&&(errno==EINTR||errno==EAGAIN))continue;
    if(r<=0)deny("authority EOF before permission");
    if(s[n++]=='\n') { json_tokener *t=json_tokener_new();json_tokener_set_flags(t,JSON_TOKENER_VALIDATE_UTF8);json_object *o=json_tokener_parse_ex(t,s,(int)n);
      if(!o||json_tokener_get_error(t)!=json_tokener_success||json_tokener_get_parse_end(t)!=n||!json_object_is_type(o,json_type_object))deny("invalid authority frame");
      /* The maintained wire emits one compact JSON record. Round-trip equality
         refuses duplicate keys, extra whitespace/records and alternate escapes. */
      const char *canonical=json_object_to_json_string_ext(o,JSON_C_TO_STRING_PLAIN|JSON_C_TO_STRING_NOSLASHESCAPE);
      if(strlen(canonical)!=n-1||memcmp(canonical,s,n-1))deny("noncanonical authority frame");
      json_tokener_free(t);free(s);return o; }
  }
  deny("authority frame oversized"); return NULL;
}
int main(int argc,char **argv) {
  struct parent_identity original_parent={.pid=getppid()};
  parent_birth(original_parent.pid,original_parent.birth);same_parent(&original_parent);
  if(prctl(PR_SET_DUMPABLE,0,0,0,0))deny("non-dumpable gate unavailable");
  if(argc!=3||!token(argv[1])||!token(argv[2]))deny("expected fixed mapping and correlation ticket");
  policy();root_path(MAP_PATH,0);char *bytes=read_file(MAP_PATH,LIMIT);
  json_tokener *parser=json_tokener_new();json_tokener_set_flags(parser,JSON_TOKENER_VALIDATE_UTF8);json_object *map=json_tokener_parse_ex(parser,bytes,(int)strlen(bytes));
  if(!map||json_tokener_get_error(parser)!=json_tokener_success||json_tokener_get_parse_end(parser)!=strlen(bytes))deny("invalid deployment map");
  json_tokener_free(parser);free(bytes);
  if(strcmp(str(map,"schema"),"ace.assign.authorities/v2"))deny("unsupported deployment map");
  json_object *mapping=field(field(map,"launch_mappings",json_type_object),argv[1],json_type_object);
  json_object *service=field(field(map,"authorities",json_type_object),str(mapping,"authority_id"),json_type_object);
  int worker=number(mapping,"worker_uid"),launcher=number(mapping,"launcher_uid"),authority=number(service,"uid");
  if(worker==launcher||worker==authority||authority==launcher)deny("principals are not distinct");
  credentials(getpid(),worker,number(mapping,"worker_gid"),field(mapping,"worker_groups",json_type_array));
  parent_credentials(&original_parent,mapping);
  const char *bootstrap=str(mapping,"bootstrap");root_path(bootstrap,0);
  struct stat installed,self;
  if(stat(bootstrap,&installed)||stat("/proc/self/exe",&self)||installed.st_dev!=self.st_dev||installed.st_ino!=self.st_ino||
     (installed.st_mode&06000))deny("gate executable differs from installed bootstrap");
  const char *path=str(service,"socket_path");char parent[4096];if(strlen(path)>=sizeof(parent))deny("socket path too long");
  strcpy(parent,path);char *slash=strrchr(parent,'/');if(!slash||slash==parent)deny("invalid socket path");*slash=0;
  /* Only root/the trusted authority may own the non-writable ancestry. */
  trusted_path(parent,1,(uid_t)authority);
  struct stat directory,endpoint;if(lstat(parent,&directory)||!S_ISDIR(directory.st_mode)||directory.st_uid!=(uid_t)authority||
    (directory.st_mode&022)||lstat(path,&endpoint)||!S_ISSOCK(endpoint.st_mode)||endpoint.st_uid!=(uid_t)authority)deny("unsafe authority endpoint");
  int fd=socket(AF_UNIX,SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK,0);if(fd<0)deny("socket unavailable");
  struct sockaddr_un address={.sun_family=AF_UNIX};if(strlen(path)>=sizeof(address.sun_path))deny("socket path too long");strcpy(address.sun_path,path);
  double deadline=now()+30;
  if(connect(fd,(struct sockaddr *)&address,sizeof(address))<0) {
    if(errno!=EINPROGRESS&&errno!=EAGAIN)deny("authority connection failed");
    wait_fd(fd,POLLOUT,deadline);
    int error=0;socklen_t length=sizeof(error);if(getsockopt(fd,SOL_SOCKET,SO_ERROR,&error,&length)||error)deny("authority connection failed");
  }
  struct ucred peer;socklen_t length=sizeof(peer);
  if(getsockopt(fd,SOL_SOCKET,SO_PEERCRED,&peer,&length)||peer.uid!=(uid_t)authority||peer.gid!=(gid_t)number(service,"gid"))deny("authority peer differs");
  credentials(peer.pid,authority,number(service,"gid"),field(service,"groups",json_type_array));
  struct stat after;if(lstat(path,&after)||after.st_dev!=endpoint.st_dev||after.st_ino!=endpoint.st_ino||after.st_uid!=endpoint.st_uid)deny("authority endpoint replaced");
  json_object *request=json_object_new_object(),*params=json_object_new_object();
  json_object_object_add(request,"version",json_object_new_int(1));json_object_object_add(request,"operation",json_object_new_string("gate_ready"));
  json_object_object_add(request,"mutation_id",NULL);json_object_object_add(request,"project_id",json_object_new_string(str(mapping,"project_id")));
  json_object_object_add(params,"mapping_id",json_object_new_string(argv[1]));json_object_object_add(params,"launch_ticket",json_object_new_string(argv[2]));
  json_object_object_add(request,"params",params);parent_credentials(&original_parent,mapping);send_frame(fd,request,deadline);json_object_put(request);
  json_object *ready=receive(fd,deadline);
  if(strcmp(str(ready,"status"),"ok")||strcmp(str(field(ready,"data",json_type_object),"phase"),"ready"))deny("gate not admitted");
  json_object_put(ready);
  json_object *permission=receive(fd,deadline);
  if(strcmp(str(permission,"operation"),"release")||strcmp(str(permission,"launch_ticket"),argv[2])||
    !token(str(permission,"attempt_id"))||!token(str(permission,"assignment_id"))||!token(str(permission,"journal_commit")))deny("release permission differs");
  if(json_object_get_int64(field(permission,"generation",json_type_int))<1)deny("invalid release generation");
  if(strlen(json_object_to_json_string_ext(permission,JSON_C_TO_STRING_PLAIN|JSON_C_TO_STRING_NOSLASHESCAPE))+1>16384)deny("release envelope oversized");
  prepared_permission(permission);
  policy();parent_credentials(&original_parent,mapping);credentials(peer.pid,authority,number(service,"gid"),field(service,"groups",json_type_array));
  json_object *entry=field(field(permission,"prepared_input",json_type_object),"worker_entry",json_type_object);
  OSSL_LIB_CTX *digest_context=NULL;OSSL_PROVIDER *digest_provider=NULL;EVP_MD *digest=fixed_sha256(&digest_context,&digest_provider);
  struct stat interpreter_metadata,wrapper_metadata;
  int interpreter=held_entry(field(entry,"interpreter",json_type_object),1,digest,&interpreter_metadata);
  int wrapper=held_entry(field(entry,"wrapper",json_type_object),0,digest,&wrapper_metadata);
  EVP_MD_free(digest);OSSL_PROVIDER_unload(digest_provider);OSSL_LIB_CTX_free(digest_context);
  if(clearenv())deny("environment reset failed");
  json_object *env=field(mapping,"worker_env",json_type_object);
  json_object_object_foreach(env,key,value) {
    if(!json_object_is_type(value,json_type_string)||!strncmp(key,"LD_",3)||!strncmp(key,"DYLD_",5)||!strncmp(key,"RUBY",4)||!strncmp(key,"BUNDLE",6)||!strncmp(key,"PYTHON",6))deny("unsafe fixed environment");
    if(setenv(key,json_object_get_string(value),1))deny("environment setup failed");
  }
  if(setenv("ACE_ASSIGN_ATTEMPT_ID",str(permission,"attempt_id"),1)||setenv("ACE_ASSIGN_ASSIGNMENT_ID",str(permission,"assignment_id"),1)||
    setenv("ACE_ASSIGN_LAUNCH_MAPPING",argv[1],1))deny("authority context unavailable");
  if(chdir(str(mapping,"worker_cwd")))deny("fixed worker directory unavailable");
  close(fd);
  struct stat final_interpreter,final_wrapper;
  if(fstat(interpreter,&final_interpreter)||fstat(wrapper,&final_wrapper)||
     !same_metadata(&interpreter_metadata,&final_interpreter)||!same_metadata(&wrapper_metadata,&final_wrapper))deny("worker entry changed before execution");
  select_entry_descriptors(interpreter,wrapper);
  parent_credentials(&original_parent,mapping);
  char *const payload[]={"/proc/self/fd/4","-I","-S","-B","/proc/self/fd/5","authority","worker",NULL};
  extern char **environ;
  fexecve(4,payload,environ);deny("fixed worker execution failed");
}
