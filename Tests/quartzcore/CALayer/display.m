/* When a layer decides it needs drawing again.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the flag that says a layer wants drawing")

  CALayer *l = [CALayer layer];

  [l setBounds: CGRectMake(0, 0, 50, 50)];
  [l displayIfNeeded];
  PASS([l needsDisplay] == NO, "a layer that has drawn does not want drawing");

  [l setNeedsDisplay];
  PASS([l needsDisplay] == YES, "asking for drawing sets the flag");

  [l displayIfNeeded];
  PASS([l needsDisplay] == NO, "drawing when needed clears it");

  [l setNeedsDisplayInRect: CGRectMake(0, 0, 10, 10)];
  PASS([l needsDisplay] == YES, "asking for part of it sets the flag too");

  [l displayIfNeeded];

  testHopeful = YES;
  [l setNeedsDisplay];
  [l display];
  PASS([l needsDisplay] == NO, "drawing outright clears it as well");
  testHopeful = NO;

  END_SET("the flag that says a layer wants drawing")

  START_SET("redrawing when the bounds change")

  CALayer *off = [CALayer layer];

  [off displayIfNeeded];
  [off setBounds: CGRectMake(0, 0, 30, 30)];
  PASS([off needsDisplay] == NO,
       "a bounds change alone does not ask for drawing");

  CALayer *on = [CALayer layer];

  [on setNeedsDisplayOnBoundsChange: YES];
  [on displayIfNeeded];
  [on setBounds: CGRectMake(0, 0, 30, 30)];
  PASS([on needsDisplay] == YES,
       "a layer told to redraw on a bounds change asks for drawing");

  END_SET("redrawing when the bounds change")

  [pool release];
  return 0;
}
