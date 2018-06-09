#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import <GNUstepBase/GSVersionMacros.h>

@interface  NSView (NSViewCAmethods)
@property BOOL wantsLayer;
- (CALayer *) makeBackingLayer;

/* methods from libs-gui/Headers/AppKit/NSOpenGlView.h */
+ (NSOpenGLPixelFormat*) defaultPixelFormat;
- (void) clearGLContext;
- (void) setOpenGLContext: (NSOpenGLContext*)context;
- (NSOpenGLContext*) openGLContext;
- (id) initWithFrame: (NSRect)frameRect 
         pixelFormat: (NSOpenGLPixelFormat*)format;
- (NSOpenGLPixelFormat*) pixelFormat;
- (void) setPixelFormat: (NSOpenGLPixelFormat*)pixelFormat;
- (void) reshape;
- (void) update;
#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
- (void) prepareOpenGL;
#endif
@end
