#import <Foundation/Foundation.h>
#import <X11/Xlib.h>
#import <EGL/egl.h>

@class XGXSubWindow;
@interface GLESContext : NSObject
{
  Display *_x11Display;
  EGLDisplay _eglDisplay;
  EGLContext _eglContext;
  EGLSurface _eglSurface;
  EGLConfig _eglFBConfig[1];

  id _surfaceContainer; /* view */
  XGXSubWindow * _viewSubwindow; /* an internal class in -back. */
}

@property (nonatomic, retain) id view;
- (void) createContext;
@end
