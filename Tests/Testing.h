#ifndef QUARTZCORE_TESTING_H
#define QUARTZCORE_TESTING_H

#include <unistd.h> // usleep()
#define PASS(x, y) \
{ \
  printf("%s ", y); \
  fflush(stdout); \
  if((x)) \
    { \
      printf(" [done]\n"); \
    } \
  else \
    { \
      printf(" [failed]\7\n"); \
      fflush(stdout); \
      usleep(250*1000); \
      testsFailed++; \
    } \
  fflush(stdout); \
}

#endif
/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
