/* CAReplicatorLayer: what a fresh replicator layer holds and what its
   setters keep.  Expected values checked against Apple QuartzCore.

   This covers the properties.  A replicator layer does not draw its copies
   here yet. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAReplicatorLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a replicator layer starts with")

  CAReplicatorLayer *r = [CAReplicatorLayer layer];

  PASS([r isKindOfClass: [CALayer class]], "a replicator layer is a layer");
  PASS([r instanceCount] == 1, "a replicator layer draws one copy");
  PASS([r instanceDelay] == 0.0, "a replicator layer has no delay");
  PASS(CATransform3DIsIdentity([r instanceTransform]),
       "a replicator layer does not move its copies");
  PASS([r preservesDepth] == NO, "a replicator layer does not preserve depth");
  PASS([r instanceRedOffset] == 0.0, "there is no red offset");
  PASS([r instanceGreenOffset] == 0.0, "there is no green offset");
  PASS([r instanceBlueOffset] == 0.0, "there is no blue offset");
  PASS([r instanceAlphaOffset] == 0.0, "there is no alpha offset");

  END_SET("what a replicator layer starts with")

  START_SET("the colour a replicator layer multiplies by")

  CAReplicatorLayer *r = [CAReplicatorLayer layer];
  CGColorRef colour = [r instanceColor];

  PASS(colour != NULL, "a replicator layer starts with a colour");
  PASS(CGColorGetNumberOfComponents(colour) == 4,
       "the colour has four components");
  PASS(CGColorGetAlpha(colour) == 1.0, "the colour is opaque");

  const CGFloat *components = CGColorGetComponents(colour);

  PASS(components[0] == 1.0 && components[1] == 1.0 && components[2] == 1.0,
       "the colour is white, so a copy is drawn as it is");

  END_SET("the colour a replicator layer multiplies by")

  START_SET("what the setters keep")

  CAReplicatorLayer *r = [CAReplicatorLayer layer];

  [r setInstanceCount: 5];
  PASS([r instanceCount] == 5, "the instance count reads back");

  [r setInstanceDelay: 0.5];
  PASS([r instanceDelay] == 0.5, "the delay reads back");

  [r setPreservesDepth: YES];
  PASS([r preservesDepth] == YES, "preserving depth reads back");

  [r setInstanceTransform: CATransform3DMakeTranslation(10, 20, 0)];
  PASS([r instanceTransform].m41 == 10 && [r instanceTransform].m42 == 20,
       "the instance transform reads back as it was set");

  [r setInstanceAlphaOffset: -0.25];
  PASS([r instanceAlphaOffset] == -0.25, "the alpha offset reads back");

  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGFloat values[4] = {1.0, 0.0, 0.0, 1.0};
  CGColorRef red = CGColorCreate(space, values);

  [r setInstanceColor: red];
  PASS([r instanceColor] == red,
       "the colour it is given is the colour it answers");
  CGColorRelease(red);
  CGColorSpaceRelease(space);

  PASS(CGColorGetAlpha([r instanceColor]) == 1.0,
       "the colour it kept is still there after the caller let go");

  END_SET("what the setters keep")

  [pool release];
  return 0;
}
