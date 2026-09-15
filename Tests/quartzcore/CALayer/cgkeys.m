/* Reading the Core Graphics valued properties of a layer by key.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <CoreGraphics/CoreGraphics.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("reading a Core Graphics property by key")

  CALayer *l = [CALayer layer];
  CGMutablePathRef path = CGPathCreateMutable();
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGFloat components[4] = {1.0, 0.0, 0.0, 1.0};
  CGColorRef red = CGColorCreate(space, components);

  CGPathAddRect(path, NULL, CGRectMake(0, 0, 10, 10));
  [l setShadowPath: path];
  [l setShadowColor: red];

  PASS([l valueForKey: @"shadowColor"] == (id)[l shadowColor],
       "the shadow colour key answers the shadow colour");
  PASS([l valueForKey: @"backgroundColor"] == nil,
       "the background colour key answers nothing when none is set");
  PASS([l valueForKey: @"borderColor"] == (id)[l borderColor],
       "the border colour key answers the border colour");

  PASS([l valueForKey: @"shadowPath"] != nil,
       "the shadow path key answers something once a path is set");
  PASS([l valueForKey: @"shadowPath"] != (id)[l shadowColor],
       "and what it answers is not the shadow colour");

  CGPathRelease(path);
  CGColorRelease(red);
  CGColorSpaceRelease(space);

  END_SET("reading a Core Graphics property by key")

  [pool release];
  return 0;
}
