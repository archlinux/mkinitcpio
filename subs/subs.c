#include <strings.h>
#include <stdio.h>
#include <unistd.h>

void usage(char *name)
{
  fprintf(stderr,"Usage:\n\t%s [-n <character>] [-w <character>] <string>\n",name);
}

int main(int argc, char *argv[])
{
  char *h,n=':',w=' ';
  int c;

  while((c=getopt(argc, argv, "n:w:"))!=-1)
    switch(c)
    {
      case 'n':
        n=optarg[0];
        break;
      case 'w':
        w=optarg[0];
        break;
      default:
        usage(argv[0]);
        return 1;
    }

  if(optind>=argc)
  {
    usage(argv[0]);
    return 1;
  }

  h=argv[optind];
  while( (h=index(h, n)) !=NULL )
    *h++=w;
  
  printf("%s",argv[optind]);

  return 0;
}
