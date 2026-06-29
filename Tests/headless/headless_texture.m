/* Headless regression tests for CAGLTexture -_writeToPNG:.

   These run entirely without a display: a surfaceless EGL context backed by
   Mesa's software rasteriser (llvmpipe) provides a desktop-GL context, which
   is all CAGLTexture needs (it only uploads a texture and reads it back with
   glGetTexImage -- there is no on-screen rendering).  The class is obtained
   with objc_getClass so no private header is required.

   Build is gated on EGL being available (see GNUmakefile); at run time the
   test skips cleanly if no GL context can be created.

   Test 1 exercises the full readback + encode path and checks a valid PNG of
   the right dimensions is produced.

   Test 2 is the regression for the stack overflow: the previous
   implementation read the whole texture into a stack VLA
   (char pixels[width*height*4]); for a large texture that overflowed the
   stack.  Running it on a thread with a deliberately small stack makes the
   overflow deterministic, so a regression aborts the process here instead of
   depending on the caller's stack limit. */

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GL/gl.h>
#include <pthread.h>

#ifndef EGL_PLATFORM_SURFACELESS_MESA
#define EGL_PLATFORM_SURFACELESS_MESA 0x31DD
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

@interface CAGLTexture : NSObject
+ (instancetype) texture;
- (void) loadRGBATexImage:(void*)data width:(unsigned int)w height:(unsigned int)h;
- (void) _writeToPNG:(NSString*)path;
@end

static int failures = 0;
static void check(int cond, const char *msg)
{
  printf("%s: %s\n", cond ? "PASS" : "FAIL", msg);
  if (!cond) failures++;
}

static int makeHeadlessGL(void)
{
  typedef EGLDisplay (*getPlatDisp)(EGLenum, void*, const EGLint*);
  getPlatDisp gpd = (getPlatDisp)eglGetProcAddress("eglGetPlatformDisplayEXT");
  EGLDisplay dpy = gpd ? gpd(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, NULL)
                       : eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (dpy == EGL_NO_DISPLAY || !eglInitialize(dpy, NULL, NULL))
    return 0;
  if (!eglBindAPI(EGL_OPENGL_API))      /* desktop GL: glGetTexImage is not in GLES */
    return 0;
  EGLint cfgAttrs[] = { EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
                        EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT, EGL_NONE };
  EGLConfig cfg; EGLint n = 0;
  if (!eglChooseConfig(dpy, cfgAttrs, &cfg, 1, &n) || n < 1)
    return 0;
  EGLContext ctx = eglCreateContext(dpy, cfg, EGL_NO_CONTEXT, NULL);
  if (ctx == EGL_NO_CONTEXT)
    return 0;
  if (!eglMakeCurrent(dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, ctx))
    return 0;
  return 1;
}

static unsigned be32(const unsigned char *p)
{
  return ((unsigned)p[0] << 24) | ((unsigned)p[1] << 16)
       | ((unsigned)p[2] << 8) | (unsigned)p[3];
}

static NSString *tmpPath(NSString *name)
{
  return [NSTemporaryDirectory() stringByAppendingPathComponent: name];
}

/* Run on a small-stack thread so the old stack-VLA reliably overflows. */
static void *largeTextureThread(void *arg)
{
  unsigned dim = *(unsigned *)arg;
  @autoreleasepool
    {
      Class cls = objc_getClass("CAGLTexture");
      unsigned char *up = malloc((size_t)dim * dim * 4);
      if (up == NULL)
        return (void *)1;          /* out of memory: treat as non-fatal */
      memset(up, 0x40, (size_t)dim * dim * 4);
      id tex = [cls texture];
      [tex loadRGBATexImage: up width: dim height: dim];
      [tex _writeToPNG: tmpPath(@"qc_headless_large.png")];
      free(up);
    }
  return (void *)1;
}

int main(void)
{
  @autoreleasepool
    {
      if (!makeHeadlessGL())
        {
          printf("SKIP: no headless GL context available\n");
          return 0;
        }
      printf("GL: %s / %s\n", glGetString(GL_VERSION), glGetString(GL_RENDERER));

      Class cls = objc_getClass("CAGLTexture");
      check(cls != Nil, "CAGLTexture class is available");
      if (cls == Nil)
        return 1;

      /* Test 1: a texture round-trips to a valid PNG of the right size. */
      {
        const unsigned W = 64, H = 48;
        unsigned char *up = malloc((size_t)W * H * 4);
        unsigned i;
        for (i = 0; i < W * H * 4; i++)
          up[i] = (unsigned char)(i * 131 + 7);

        id tex = [cls texture];
        [tex loadRGBATexImage: up width: W height: H];
        NSString *path = tmpPath(@"qc_headless_64x48.png");
        [tex _writeToPNG: path];

        NSData *png = [NSData dataWithContentsOfFile: path];
        const unsigned char *b = (const unsigned char *)[png bytes];
        int sig = (png && [png length] > 24
                   && b[0] == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G');
        check(sig, "writeToPNG produced a valid PNG");
        if (sig)
          check(be32(b + 16) == W && be32(b + 20) == H,
                "PNG dimensions match the texture");
        free(up);
      }

      /* Test 2: regression -- a large texture must not be read into a stack
         VLA.  Run on a 2 MB-stack thread; the old 4 MB VLA overflows it. */
      {
        unsigned dim = 1024;          /* 1024*1024*4 = 4 MB readback buffer */
        pthread_attr_t attr;
        pthread_t th;
        void *res = NULL;
        if (pthread_attr_init(&attr) == 0
            && pthread_attr_setstacksize(&attr, 2 * 1024 * 1024) == 0
            && pthread_create(&th, &attr, largeTextureThread, &dim) == 0)
          {
            pthread_join(th, &res);
            check(res != NULL,
                  "writeToPNG of a large texture did not overflow a 2 MB stack");
          }
        pthread_attr_destroy(&attr);
      }

      printf("\n%s (%d failure%s)\n",
             failures ? "FAILED" : "All OK", failures, failures == 1 ? "" : "s");
      return failures ? 1 : 0;
    }
}
