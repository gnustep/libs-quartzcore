/* CAScrollLayer: the scroll mode it starts with, and where scrolling leaves
   the bounds.  Expected values checked against Apple QuartzCore.

   Scrolling moves the origin of the layer's own bounds.  The scrolling
   methods CALayer gains from this header are not covered: they convert a
   point from a sublayer's space, which this framework cannot do yet. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAScrollLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a scroll layer starts with")

  CAScrollLayer *s = [CAScrollLayer layer];

  PASS([s isKindOfClass: [CALayer class]], "a scroll layer is a layer");
  PASS([[s scrollMode] isEqualToString: kCAScrollBoth],
       "a scroll layer scrolls both ways");
  PASS([s opacity] == 1.0, "a scroll layer keeps what a layer starts with");

  END_SET("what a scroll layer starts with")

  START_SET("the scroll mode names")

  PASS([kCAScrollNone isEqualToString: @"none"],
       "not scrolling is named none");
  PASS([kCAScrollVertically isEqualToString: @"vertically"],
       "scrolling up and down is named vertically");
  PASS([kCAScrollHorizontally isEqualToString: @"horizontally"],
       "scrolling side to side is named horizontally");
  PASS([kCAScrollBoth isEqualToString: @"both"],
       "scrolling either way is named both");

  END_SET("the scroll mode names")

  START_SET("scrolling to a point")

  CAScrollLayer *s = [CAScrollLayer layer];

  [s setBounds: CGRectMake(0, 0, 100, 100)];
  [s scrollToPoint: CGPointMake(50, 60)];

  PASS([s bounds].origin.x == 50 && [s bounds].origin.y == 60,
       "scrolling moves the origin of the bounds");
  PASS([s bounds].size.width == 100 && [s bounds].size.height == 100,
       "scrolling leaves the size of the bounds alone");

  END_SET("scrolling to a point")

  START_SET("scrolling to a rectangle")

  CAScrollLayer *s = [CAScrollLayer layer];

  [s setBounds: CGRectMake(50, 60, 100, 100)];
  [s scrollToRect: CGRectMake(200, 200, 10, 10)];

  /* Far enough to bring the far edge in, and no further. */
  PASS([s bounds].origin.x == 110 && [s bounds].origin.y == 110,
       "scrolling to a rectangle moves as little as it can");

  [s setBounds: CGRectMake(100, 100, 100, 100)];
  [s scrollToRect: CGRectMake(120, 120, 10, 10)];
  PASS([s bounds].origin.x == 100 && [s bounds].origin.y == 100,
       "a rectangle already in view does not move anything");

  [s setBounds: CGRectMake(100, 100, 100, 100)];
  [s scrollToRect: CGRectMake(20, 20, 10, 10)];
  PASS([s bounds].origin.x == 20 && [s bounds].origin.y == 20,
       "a rectangle behind the view is scrolled back to");

  [s setBounds: CGRectMake(0, 0, 100, 100)];
  [s scrollToRect: CGRectMake(20, 20, 400, 400)];
  PASS([s bounds].origin.x == 20 && [s bounds].origin.y == 20,
       "a rectangle too big to fit is scrolled to its own origin");

  END_SET("scrolling to a rectangle")

  START_SET("a scroll mode that holds one way still")

  CAScrollLayer *s = [CAScrollLayer layer];

  [s setBounds: CGRectMake(0, 0, 100, 100)];
  [s setScrollMode: kCAScrollVertically];
  [s scrollToPoint: CGPointMake(70, 80)];
  PASS([s bounds].origin.x == 0 && [s bounds].origin.y == 80,
       "scrolling vertically leaves the horizontal origin alone");

  [s setBounds: CGRectMake(0, 0, 100, 100)];
  [s setScrollMode: kCAScrollHorizontally];
  [s scrollToPoint: CGPointMake(70, 80)];
  PASS([s bounds].origin.x == 70 && [s bounds].origin.y == 0,
       "scrolling horizontally leaves the vertical origin alone");

  [s setBounds: CGRectMake(0, 0, 100, 100)];
  [s setScrollMode: kCAScrollNone];
  [s scrollToPoint: CGPointMake(70, 80)];
  PASS([s bounds].origin.x == 0 && [s bounds].origin.y == 0,
       "a layer that does not scroll stays where it is");

  END_SET("a scroll mode that holds one way still")

  [pool release];
  return 0;
}
