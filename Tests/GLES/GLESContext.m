#import "GLESContext.h"
#import <GLES/gl.h>
#import <EGL/egl.h>
#import <AppKit/AppKit.h>

@class XGXSubWindow; /* internal class in -back */

#if 0
@interface XGXSubWindow : NSObject
// part of the interface definition taken from -back.
// 1. we only need the xwindowid ivar, but we have no getter
// 2. we only need the initWithView... method, to avoid a warning.
{
  @public
  Window xwindowid;
  NSView *attached;
}
- initWithView: (NSView *)view visualinfo: (XVisualInfo *)xVisualInfo;
@end
#endif

extern id GSCurrentServer();

@implementation GLESContext
@synthesize view=_surfaceContainer;

- (id) init
{
  self = [super init];
  if (!self)
    return nil;

  return self;
}
- (void) createContext
{
  EGLint eglAttributes[] = {
    EGL_RED_SIZE, 8,
    EGL_GREEN_SIZE, 8,
    EGL_BLUE_SIZE, 8,
    EGL_DEPTH_SIZE, 16,
    EGL_RENDERABLE_TYPE, EGL_OPENGL_ES_BIT,
    EGL_NONE
  };
  EGLint eglContextAttributes[] = {
    EGL_CONTEXT_CLIENT_VERSION, 1,
    EGL_NONE
  };
  EGLint nConfigs = 0;

  EGLint versionMajor, versionMinor;

  // Set up EGL display
  _x11Display = (Display *)[GSCurrentServer() xDisplay];
  _eglDisplay = eglGetDisplay(_x11Display);
  eglInitialize(_eglDisplay, &versionMajor, &versionMinor);
  NSLog(@"Major and minor: %d %d", versionMajor, versionMinor);

  // Print out version
  const char * ver;
  ver = eglQueryString(_eglDisplay, EGL_VERSION);
  NSLog(@"EGL_VERSION = %s", ver);

  // Choose FB config.
  if (!eglChooseConfig(_eglDisplay, eglAttributes, _eglFBConfig, 1, &nConfigs))
    {
      NSLog(@"couldn't choose any egl fb configs (nconfigs: %d), aborting", nConfigs);
      abort();
    }

  // Create the backing surface.
  [self createSurface];

  // Create EGL surface and context.
  _eglSurface = eglCreateWindowSurface(_eglDisplay, _eglFBConfig[0], /*_viewSubwindow->xwindowid*/ [[_viewSubwindow valueForKey: @"xwindowid"] intValue], 0);
  NSLog(@"Created a window surface");
  _eglContext = eglCreateContext(_eglDisplay, _eglFBConfig[0],
                                 EGL_NO_CONTEXT, eglContextAttributes);
  NSLog(@"Created a context");
  printf("EGLContext = %p\n", _eglContext);
}

- (void)createSurface
{
  XVisualInfo template = {0};
  int vID=0, n;

  NSLog(@"display %p fbconf %p", _eglDisplay, _eglFBConfig[0]);
  if(!eglGetConfigAttrib(_eglDisplay, _eglFBConfig[0], EGL_NATIVE_VISUAL_ID, &vID))
    {
      NSLog(@"could not get native visual id for egl, aborting");
      abort();
    }
  template.visualid = vID;
  NSLog(@"vid %d", vID);
  NSLog(@"x display %p", _x11Display);
  XVisualInfo *visual = XGetVisualInfo(_x11Display, VisualIDMask, &template, &n);
  NSLog(@"N: %d", n);
  if(!visual)
    {
      NSLog(@"visual is null, aborting");
      abort();
    }

  long screen = DefaultScreen(_x11Display);
  Colormap colormap = XCreateColormap(_x11Display,
    RootWindow(_x11Display, screen),
    visual->visual,
    AllocNone);

/*
  NSWindow *w;
  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,640,480)
                                       styleMask: NSTitledWindowMask | NSClosableWindowMask
                                         backing: NSBackingStoreBuffered
                                           defer: NO];
  
  [window makeKeyAndOrderFront];
  _surfaceContainer = window;

  // alternative plan:
  // get XID of the window and construct window there.
  // to be avoided, though, since this window may have different visual etc.
*/

  Class classXGXSubWindow;
  classXGXSubWindow = NSClassFromString(@"XGXSubWindow");
  _viewSubwindow = [[classXGXSubWindow alloc] initWithView: _surfaceContainer visualinfo: visual];

}

- (void) makeCurrentContext
{
  eglMakeCurrent(_eglDisplay, _eglSurface, _eglSurface, _eglContext);
}
- (void) flushBuffer
{
  eglSwapBuffers(_eglDisplay, _eglSurface);
}
@end


// Temporary:
GLint gluBuild2DMipmaps(GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *data)
{
  glTexParameterf(target,GL_GENERATE_MIPMAP, GL_TRUE); // (GL 1.4 based)
  glTexImage2D(target, 0, internalFormat, width, height, 0, format, type, data);

  return 0;
}


