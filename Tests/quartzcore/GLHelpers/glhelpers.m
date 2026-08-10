/* What the GL helpers and the backing store hold, and what they leave bound.

   CAGLTexture, CAGLSimpleFramebuffer and CABackingStore are GNUstep classes
   with no counterpart in Apple QuartzCore and no installed header, so they
   are declared here and the file is named in APPLE_SKIP_TESTS.  The expected
   values are the ones this implementation produces.

   Every one of these needs a context with something to draw into, and a
   context with no drawable never returns from being made current.  So the
   window is checked at every step before the context is touched, and the
   sets are skipped rather than left to hang. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <stdlib.h>

#import <AppKit/AppKit.h>
#define GL_GLEXT_PROTOTYPES 1
#import <GL/gl.h>
#import <GL/glext.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CAGLTexture : NSObject
+ (CAGLTexture *) texture;
- (void) loadEmptyImageWithWidth: (GLuint)width height: (GLuint)height;
- (void) loadRGBATexImage: (void *)data width: (GLuint)width height: (GLuint)height;
- (void) loadImage: (CGImageRef)image;
- (void) bind;
- (void) unbind;
- (GLuint) textureID;
- (GLint) width;
- (GLint) height;
- (GLenum) textureTarget;
@end

@interface CAGLSimpleFramebuffer : NSObject
- (id) initWithWidth: (CGFloat)width height: (CGFloat)height;
- (void) bind;
- (void) unbind;
- (CAGLTexture *) texture;
- (BOOL) hasDepthBuffer;
- (void) setDepthBufferEnabled: (BOOL)flag;
@end

@interface CABackingStore : NSObject
+ (CABackingStore *) backingStoreWithWidth: (CGFloat)width height: (CGFloat)height;
- (void) refresh;
- (CAGLTexture *) contentsTexture;
- (CAGLTexture *) offscreenRenderTexture;
- (CGContextRef) context;
- (CGFloat) width;
- (CGFloat) height;
@end

/* Builds a window with a drawable, or answers nil having touched nothing
   that could block.  The reason is written into *why. */
static NSOpenGLContext *
usableContext(const char **why)
{
  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 24,
    0
  };
  NSOpenGLPixelFormat *format;
  NSWindow *window;
  NSOpenGLView *view;
  const char *display = getenv("DISPLAY");
  BOOL started = YES;

  if (display == NULL || *display == '\0')
    {
      *why = "there is no display, so nothing can be drawn into";
      return nil;
    }

  @try
    {
      [NSApplication sharedApplication];
    }
  @catch (NSException *e)
    {
      started = NO;
    }

  if (started == NO || NSApp == nil)
    {
      *why = "the backend would not start";
      return nil;
    }

  format = [[[NSOpenGLPixelFormat alloc]
              initWithAttributes: attrs] autorelease];
  if (format == nil)
    {
      *why = "there is no pixel format to draw with";
      return nil;
    }

  window = [[[NSWindow alloc]
              initWithContentRect: NSMakeRect(0, 0, 64, 48)
                        styleMask: NSBorderlessWindowMask
                          backing: NSBackingStoreBuffered
                            defer: NO] autorelease];
  view = [[[NSOpenGLView alloc] initWithFrame: NSMakeRect(0, 0, 64, 48)
                                  pixelFormat: format] autorelease];
  if (window == nil || view == nil)
    {
      *why = "no window to put a drawable in";
      return nil;
    }

  [window setContentView: view];
  [window orderFront: nil];

  if ([window windowNumber] <= 0)
    {
      *why = "the window server gave out no window";
      return nil;
    }

  if ([view openGLContext] == nil)
    {
      *why = "the view came back with no context";
      return nil;
    }

  return [view openGLContext];
}

static GLint boundTexture(void)
{
  GLint name = -1;

  glGetIntegerv(GL_TEXTURE_BINDING_2D, &name);
  return name;
}

static GLint boundFramebuffer(void)
{
  GLint name = -1;

  glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &name);
  return name;
}

/* What GL itself holds for a texture, which is not always what the object
   says it holds. */
static GLint storedWidth(CAGLTexture *texture)
{
  GLint width = -1;
  GLint saved = boundTexture();

  glBindTexture(GL_TEXTURE_2D, [texture textureID]);
  glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
  glBindTexture(GL_TEXTURE_2D, saved);
  return width;
}

static void clearErrors(void)
{
  while (glGetError() != GL_NO_ERROR)
    {
    }
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);

  if (context != nil)
    {
      [context makeCurrentContext];
    }

  START_SET("a texture on its own")

  CAGLTexture *texture;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  texture = [CAGLTexture texture];

  PASS(texture != nil, "a texture can be created");
  PASS([texture textureID] != 0, "it is given a name by GL");
  PASS([texture width] == 0 && [texture height] == 0,
       "it holds no image until one is loaded");
  PASS([texture textureTarget] == GL_TEXTURE_2D, "it is a two dimensional texture");

  glBindTexture(GL_TEXTURE_2D, 0);
  [texture bind];
  PASS(boundTexture() == (GLint)[texture textureID],
       "binding it makes it the texture GL draws with");
  [texture unbind];
  PASS(boundTexture() == 0, "unbinding it leaves no texture bound");

  END_SET("a texture on its own")

  START_SET("loading pixels into a texture")

  CAGLTexture *texture;
  unsigned char *pixels;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  texture = [CAGLTexture texture];
  pixels = calloc(8 * 4 * 4, 1);
  clearErrors();
  [texture loadRGBATexImage: pixels width: 8 height: 4];

  PASS([texture width] == 8 && [texture height] == 4,
       "the texture takes the size it was given");
  PASS(storedWidth(texture) == 8, "and GL holds an image of that width");
  PASS(boundTexture() == (GLint)[texture textureID],
       "the texture it loaded into is left bound");
  PASS(glGetError() == GL_NO_ERROR, "loading pixels leaves no error behind");
  free(pixels);

  END_SET("loading pixels into a texture")

  START_SET("loading an empty image into a texture")

  CAGLTexture *texture;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  texture = [CAGLTexture texture];
  glBindTexture(GL_TEXTURE_2D, 0);
  clearErrors();
  [texture loadEmptyImageWithWidth: 32 height: 16];

  PASS([texture width] == 32 && [texture height] == 16,
       "the texture takes the size it was given");

  /* Unlike -loadRGBATexImage:width:height:, this one never binds, so the
     image is made in whatever texture GL happens to be holding. */
  testHopeful = YES;
  PASS(storedWidth(texture) == 32, "and GL holds an image of that width");
  PASS(boundTexture() == (GLint)[texture textureID],
       "the texture it loaded into is left bound");
  testHopeful = NO;

  END_SET("loading an empty image into a texture")

  START_SET("loading a CGImage into a texture")

  CAGLTexture *texture;
  CGColorSpaceRef space;
  CGContextRef bitmap;
  CGImageRef image;
  unsigned char *pixels;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  pixels = calloc(16 * 8 * 4, 1);
  bitmap = CGBitmapContextCreate(pixels, 16, 8, 8, 16 * 4, space,
                                 kCGImageAlphaPremultipliedFirst);
  image = bitmap ? CGBitmapContextCreateImage(bitmap) : NULL;

  if (image == NULL)
    {
      SKIP("there is no image to load")
    }

  texture = [CAGLTexture texture];
  clearErrors();
  [texture loadImage: image];

  PASS([texture width] == 16 && [texture height] == 8,
       "the texture takes the size of the image");
  PASS(storedWidth(texture) == 16, "and GL holds an image of that width");

  /* The client storage pixel store parameter is Apple's, and asking for it
     anywhere else is an error GL keeps until somebody reads it. */
  testHopeful = YES;
  PASS(glGetError() == GL_NO_ERROR, "loading an image leaves no error behind");
  testHopeful = NO;

  CGImageRelease(image);
  CGContextRelease(bitmap);
  CGColorSpaceRelease(space);
  free(pixels);

  END_SET("loading a CGImage into a texture")

  START_SET("a framebuffer")

  CAGLSimpleFramebuffer *framebuffer;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  glBindFramebuffer(GL_FRAMEBUFFER_EXT, 0);
  clearErrors();
  framebuffer = [[CAGLSimpleFramebuffer alloc] initWithWidth: 32 height: 16];

  PASS(framebuffer != nil, "a framebuffer can be created");
  PASS([framebuffer texture] != nil, "it has a texture to draw into");
  PASS([[framebuffer texture] width] == 32 && [[framebuffer texture] height] == 16,
       "the texture is the size the framebuffer was asked for");
  PASS(storedWidth([framebuffer texture]) == 32,
       "and GL holds an image of that width");
  PASS([framebuffer hasDepthBuffer] == NO, "it starts with no depth buffer");
  PASS(glGetError() == GL_NO_ERROR, "building one leaves no error behind");

  /* Creating one should not change what GL is drawing into.  -bind and
     -unbind are what the stack is kept by. */
  testHopeful = YES;
  PASS(boundFramebuffer() == 0,
       "creating one leaves the framebuffer that was bound before");
  testHopeful = NO;

  glBindFramebuffer(GL_FRAMEBUFFER_EXT, 0);
  [framebuffer bind];
  PASS(boundFramebuffer() != 0, "binding it makes GL draw into it");
  PASS(glCheckFramebufferStatus(GL_FRAMEBUFFER_EXT) == GL_FRAMEBUFFER_COMPLETE_EXT,
       "and it is complete enough to draw into");
  [framebuffer unbind];
  PASS(boundFramebuffer() == 0,
       "unbinding the only one bound goes back to the window");

  [framebuffer setDepthBufferEnabled: YES];
  PASS([framebuffer hasDepthBuffer] == YES, "a depth buffer can be added");
  [framebuffer setDepthBufferEnabled: NO];
  PASS([framebuffer hasDepthBuffer] == NO, "and taken away again");
  PASS(glGetError() == GL_NO_ERROR, "neither leaves an error behind");

  [framebuffer release];

  END_SET("a framebuffer")

  START_SET("a backing store")

  CABackingStore *store;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();
  store = [CABackingStore backingStoreWithWidth: 64 height: 48];

  PASS(store != nil, "a backing store can be created");
  PASS([store width] == 64 && [store height] == 48,
       "it is the size it was asked for");
  PASS([store context] != NULL, "it has a context to draw into");
  PASS([store contentsTexture] != nil, "it has a texture to hold its contents");
  PASS([store offscreenRenderTexture] == nil,
       "and no offscreen texture until a layer gives it one");

  /* -setContext: refreshes, and it is called before the texture exists. */
  testHopeful = YES;
  PASS([[store contentsTexture] width] == 64,
       "its texture holds the contents once it has been created");
  testHopeful = NO;

  [store refresh];
  PASS([[store contentsTexture] width] == 64 &&
       [[store contentsTexture] height] == 48,
       "refreshing it puts the contents in the texture");
  PASS(storedWidth([store contentsTexture]) == 64,
       "and GL holds an image of that width");
  PASS(glGetError() == GL_NO_ERROR, "none of it leaves an error behind");

  END_SET("a backing store")

  [pool release];
  return 0;
}
