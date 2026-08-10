/* CATransformLayer and CAOpenGLLayer are layers.  Both declare themselves a
   subclass of CALayer in the header, so both should answer what a layer
   answers.

   CAOpenGLLayer is reached by name rather than by type, so that this file
   does not name a class Apple has deprecated. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATransformLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a transform layer is a layer")

  CATransformLayer *t = [CATransformLayer layer];

  PASS(t != nil, "a transform layer can be made");
  PASS([t isKindOfClass: [CALayer class]], "a transform layer is a layer");
  PASS([t opacity] == 1.0, "it starts with what a layer starts with");

  CALayer *child = [CALayer layer];

  [t addSublayer: child];
  PASS([[t sublayers] count] == 1, "it takes a sublayer");
  PASS([child superlayer] == t, "and the sublayer knows it");

  END_SET("a transform layer is a layer")

  START_SET("an OpenGL layer is a layer")

  Class openGLLayer = NSClassFromString(@"CAOpenGLLayer");

  PASS(openGLLayer != Nil, "there is a CAOpenGLLayer class");

  CALayer *g = [openGLLayer layer];

  PASS(g != nil, "an OpenGL layer can be made");
  PASS([g isKindOfClass: [CALayer class]], "an OpenGL layer is a layer");
  PASS([g opacity] == 1.0, "it starts with what a layer starts with");

  END_SET("an OpenGL layer is a layer")

  [pool release];
  return 0;
}
