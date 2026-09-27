/* What a shader and a program hold, and what GL holds for them.

   CAGLShader and CAGLProgram are GNUstep classes with no counterpart in Apple
   QuartzCore and no installed header, so they are declared here and the file
   is named in APPLE_SKIP_TESTS.  The shaders come from the framework's own
   Resources, which is where -initWithFile:ofType: looks.

   All of it needs a context with a drawable, and a context without one never
   returns from being made current, so the window is checked at every step
   before the context is touched and the sets are skipped otherwise. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <stdlib.h>

#import <AppKit/AppKit.h>
#define GL_GLEXT_PROTOTYPES 1
#import <GL/gl.h>
#import <GL/glext.h>

@interface CAGLShader : NSObject
- (id) initWithFile: (NSString *)file ofType: (NSString *)type;
- (void) compile;
- (GLint) compileStatus;
- (NSString *) shaderLog;
- (NSString *) source;
- (GLuint) shaderID;
- (GLenum) shaderType;
@end

@interface CAGLVertexShader : CAGLShader
@end

@interface CAGLFragmentShader : CAGLShader
@end

@interface CAGLProgram : NSObject
- (id) initWithArrayOfShaders: (NSArray *)shaders;
- (void) validate;
- (GLint) validateStatus;
- (void) link;
- (GLint) linkStatus;
- (NSString *) programLog;
- (GLint) locationForUniform: (NSString *)uniform;
- (void) use;
- (NSArray *) shaders;
- (GLuint) programID;
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

static void clearErrors(void)
{
  while (glGetError() != GL_NO_ERROR)
    {
    }
}

static GLint programStatus(CAGLProgram *program, GLenum which)
{
  GLint status = -1;

  glGetProgramiv([program programID], which, &status);
  return status;
}

/* A linked program built from the framework's own simple shaders, or nil. */
static CAGLProgram *simpleProgram(void)
{
  CAGLVertexShader *vertex = [[[CAGLVertexShader alloc]
                                initWithFile: @"simple" ofType: @"vsh"] autorelease];
  CAGLFragmentShader *fragment = [[[CAGLFragmentShader alloc]
                                initWithFile: @"simple" ofType: @"fsh"] autorelease];
  CAGLProgram *program;

  if (vertex == nil || fragment == nil)
    {
      return nil;
    }

  program = [[[CAGLProgram alloc] initWithArrayOfShaders:
               [NSArray arrayWithObjects: vertex, fragment, nil]] autorelease];
  [program link];
  return program;
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

  START_SET("a shader built from a file")

  CAGLVertexShader *vertex;
  CAGLFragmentShader *fragment;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();
  vertex = [[[CAGLVertexShader alloc] initWithFile: @"simple"
                                            ofType: @"vsh"] autorelease];

  PASS(vertex != nil, "a shader can be built from a file in the framework");
  if (vertex == nil)
    {
      SKIP("there is no shader to ask anything of")
    }

  PASS([vertex shaderID] != 0, "it is given a name by GL");
  PASS([vertex shaderType] == GL_VERTEX_SHADER, "a vertex shader is one");
  PASS([[vertex source] length] > 0, "it holds the text of the file");
  PASS([vertex compileStatus] == GL_FALSE, "it has not been compiled yet");

  [vertex compile];
  PASS([vertex compileStatus] == GL_TRUE, "and it compiles");
  PASS(glGetError() == GL_NO_ERROR, "compiling it leaves no error behind");

  fragment = [[[CAGLFragmentShader alloc] initWithFile: @"simple"
                                                ofType: @"fsh"] autorelease];
  PASS(fragment != nil && [fragment shaderType] == GL_FRAGMENT_SHADER,
       "a fragment shader is one");

  PASS([[[CAGLVertexShader alloc] initWithFile: @"nosuchshader"
                                        ofType: @"vsh"] autorelease] == nil,
       "a file that is not there gives no shader");

  END_SET("a shader built from a file")

  START_SET("a shader with nothing to compile")

  CAGLVertexShader *empty;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();
  empty = [[[CAGLVertexShader alloc] init] autorelease];

  PASS([empty source] == nil, "a shader built without a file holds no text");
  [empty compile];
  PASS([empty compileStatus] == GL_FALSE, "it does not compile");

  /* Compiling goes ahead with a nil source and hands GL nothing. */
  testHopeful = YES;
  PASS(glGetError() == GL_NO_ERROR,
       "and asking it to leaves no error behind");
  testHopeful = NO;

  END_SET("a shader with nothing to compile")

  START_SET("linking a program")

  CAGLProgram *program;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();
  program = simpleProgram();

  PASS(program != nil, "a program can be built from two shaders");
  if (program == nil)
    {
      SKIP("there is no program to ask anything of")
    }

  PASS([program programID] != 0, "it is given a name by GL");
  PASS([[program shaders] count] == 2, "it holds the shaders it was given");
  PASS([program linkStatus] == GL_TRUE, "it links");
  PASS(glGetError() == GL_NO_ERROR, "linking it leaves no error behind");

  [program use];
  {
    GLint current = -1;

    glGetIntegerv(GL_CURRENT_PROGRAM, &current);
    PASS(current == (GLint)[program programID], "using it makes it current");
  }

  PASS([program locationForUniform: @"texture_2d"] >= 0,
       "a uniform the shaders use can be found");
  PASS([program locationForUniform: @"nosuchuniform"] == -1,
       "one they do not have cannot");

  END_SET("linking a program")

  START_SET("validating a program")

  CAGLProgram *program;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();
  program = simpleProgram();

  if (program == nil)
    {
      SKIP("there is no program to ask anything of")
    }

  PASS(programStatus(program, GL_VALIDATE_STATUS) == GL_FALSE,
       "GL holds no validation for a program that has only been linked");

  [program validate];

  /* -validate compiles, attaches and links a second time, and never asks GL
     to validate anything.  -validateStatus reads the link status. */
  testHopeful = YES;
  PASS(programStatus(program, GL_VALIDATE_STATUS) == GL_TRUE,
       "validating a program is something GL is asked to do");
  PASS([program validateStatus] == programStatus(program, GL_VALIDATE_STATUS),
       "and the status read back is the validation status");
  PASS(glGetError() == GL_NO_ERROR, "validating leaves no error behind");
  testHopeful = NO;

  END_SET("validating a program")

  [pool release];
  return 0;
}
