/* A keyframe animation that follows a path.

   Apple documents the contract this checks: for a property holding a CGPoint
   the path stands in place of the values, the end of each line or curve is a
   keyframe, a move-to is not one, and the points between two keyframes come
   from the line or the curve itself.

   -calculatedAnimationValueAtTime:onLayer: is GNUstep API with no counterpart
   in Apple QuartzCore, so this file is named in APPLE_SKIP_TESTS. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>

/* Declared by the framework, not by a public header. */
@interface CAPropertyAnimation (Interpolation)
- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

static CGPoint
pointAt(CAKeyframeAnimation *k, CFTimeInterval time, CALayer *layer)
{
  CGPoint point = CGPointMake(-1, -1);
  NSValue *value = [k calculatedAnimationValueAtTime: time onLayer: layer];

  if (value != nil)
    {
      [value getValue: &point];
    }
  return point;
}

/* Two straight sides of a square, drawn over four seconds. */
static CAKeyframeAnimation *
cornerPath(void)
{
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGMutablePathRef path = CGPathCreateMutable();

  CGPathMoveToPoint(path, NULL, 0, 0);
  CGPathAddLineToPoint(path, NULL, 100, 0);
  CGPathAddLineToPoint(path, NULL, 100, 100);

  [k setDuration: 4.0];
  [k setPath: path];
  CGPathRelease(path);
  return k;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the path a keyframe animation is given")

  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGMutablePathRef path = CGPathCreateMutable();

  PASS([k path] == NULL, "an animation starts with no path");

  CGPathMoveToPoint(path, NULL, 1, 2);
  [k setPath: path];
  PASS([k path] == path, "the path reads back as it was set");

  [k setPath: NULL];
  PASS([k path] == NULL, "and it can be taken away again");
  CGPathRelease(path);

  END_SET("the path a keyframe animation is given")

  START_SET("running along a path of straight lines")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = cornerPath();

  PASS(CLOSE(pointAt(k, 0.0, layer).x, 0)
       && CLOSE(pointAt(k, 0.0, layer).y, 0),
       "it starts where the path starts");
  PASS(CLOSE(pointAt(k, 1.0, layer).x, 50)
       && CLOSE(pointAt(k, 1.0, layer).y, 0),
       "a quarter of the way along it is half way down the first side");
  PASS(CLOSE(pointAt(k, 2.0, layer).x, 100)
       && CLOSE(pointAt(k, 2.0, layer).y, 0),
       "half way along it is at the corner");
  PASS(CLOSE(pointAt(k, 3.0, layer).x, 100)
       && CLOSE(pointAt(k, 3.0, layer).y, 50),
       "and then half way down the second side");
  PASS(CLOSE(pointAt(k, 4.0, layer).x, 100)
       && CLOSE(pointAt(k, 4.0, layer).y, 100),
       "ending where the path ends");

  END_SET("running along a path of straight lines")

  START_SET("a path standing in place of the values")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = cornerPath();
  CGPoint ignored = CGPointMake(-50, -50);

  [k setValues: [NSArray arrayWithObject:
    [NSValue valueWithBytes: &ignored objCType: @encode(CGPoint)]]];

  PASS(CLOSE(pointAt(k, 2.0, layer).x, 100)
       && CLOSE(pointAt(k, 2.0, layer).y, 0),
       "the values are left alone while there is a path");

  END_SET("a path standing in place of the values")

  START_SET("running along a curve")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGMutablePathRef path = CGPathCreateMutable();
  CGPoint middle;

  /* A curve whose control points both sit above the straight line between
     its ends, so the middle of it is above that line as well. */
  CGPathMoveToPoint(path, NULL, 0, 0);
  CGPathAddCurveToPoint(path, NULL, 0, 100, 100, 100, 100, 0);
  [k setDuration: 2.0];
  [k setPath: path];
  CGPathRelease(path);

  PASS(CLOSE(pointAt(k, 0.0, layer).x, 0) && CLOSE(pointAt(k, 0.0, layer).y, 0),
       "a curve starts where it starts");
  PASS(CLOSE(pointAt(k, 2.0, layer).x, 100)
       && CLOSE(pointAt(k, 2.0, layer).y, 0),
       "and ends where it ends");

  middle = pointAt(k, 1.0, layer);
  PASS(CLOSE(middle.x, 50), "half way along it is half way across");
  PASS(CLOSE(middle.y, 75),
       "and it is on the curve rather than on the line between the ends");

  END_SET("running along a curve")

  START_SET("stepping from point to point")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = cornerPath();

  [k setCalculationMode: kCAAnimationDiscrete];

  PASS(CLOSE(pointAt(k, 1.0, layer).x, 0) && CLOSE(pointAt(k, 1.0, layer).y, 0),
       "a discrete animation holds the point it started from");
  PASS(CLOSE(pointAt(k, 2.0, layer).x, 100)
       && CLOSE(pointAt(k, 2.0, layer).y, 0),
       "then steps to the end of the first line");
  PASS(CLOSE(pointAt(k, 4.0, layer).x, 100)
       && CLOSE(pointAt(k, 4.0, layer).y, 100),
       "and to the end of the last one");

  END_SET("stepping from point to point")

  START_SET("a move to in the middle of a path")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGMutablePathRef path = CGPathCreateMutable();

  /* Two separate lines.  The move-to between them is not a keyframe, so the
     animation is in two halves, jumping across at the middle. */
  CGPathMoveToPoint(path, NULL, 0, 0);
  CGPathAddLineToPoint(path, NULL, 10, 0);
  CGPathMoveToPoint(path, NULL, 50, 50);
  CGPathAddLineToPoint(path, NULL, 60, 50);
  [k setDuration: 2.0];
  [k setPath: path];
  CGPathRelease(path);

  PASS(CLOSE(pointAt(k, 0.5, layer).x, 5) && CLOSE(pointAt(k, 0.5, layer).y, 0),
       "the first half runs along the first line");
  PASS(CLOSE(pointAt(k, 1.5, layer).x, 55)
       && CLOSE(pointAt(k, 1.5, layer).y, 50),
       "and the second along the second, the move-to not being a keyframe");

  END_SET("a move to in the middle of a path")

  [pool release];
  return 0;
}
