/* The layer properties that describe how it looks, and replacing a sublayer.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

/* The whole framework rather than CALayer.h alone, because the filter names
   are declared in a header of their own here and alongside the layer on
   Apple. */
#import <QuartzCore/QuartzCore.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what these properties start as")

  CALayer *l = [CALayer layer];

  PASS([l name] == nil, "a layer starts with no name");
  PASS([l borderWidth] == 0.0, "its border starts with no width");
  PASS([l cornerRadius] == 0.0, "its corners start square");
  PASS([l rasterizationScale] == 1.0, "it rasterises at a scale of 1");
  PASS([l isDoubleSided] == YES, "it starts double sided");
  PASS([[l minificationFilter] isEqualToString: kCAFilterLinear],
       "it shrinks with the linear filter");
  PASS([[l magnificationFilter] isEqualToString: kCAFilterLinear],
       "and grows with it too");

  END_SET("what these properties start as")

  START_SET("what their setters keep")

  CALayer *l = [CALayer layer];

  [l setName: @"a layer"];
  PASS([[l name] isEqualToString: @"a layer"],
       "the name reads back as it was set");

  [l setBorderWidth: 2.5];
  PASS([l borderWidth] == 2.5, "the border width reads back as it was set");

  [l setCornerRadius: 4.0];
  PASS([l cornerRadius] == 4.0, "the corner radius reads back as it was set");

  [l setRasterizationScale: 2.0];
  PASS([l rasterizationScale] == 2.0,
       "the rasterization scale reads back as it was set");

  [l setDoubleSided: NO];
  PASS([l isDoubleSided] == NO, "double sided reads back as it was set");

  [l setMinificationFilter: kCAFilterNearest];
  PASS([[l minificationFilter] isEqualToString: kCAFilterNearest],
       "the minification filter reads back as it was set");

  [l setMagnificationFilter: kCAFilterNearest];
  PASS([[l magnificationFilter] isEqualToString: kCAFilterNearest],
       "the magnification filter reads back as it was set");

  END_SET("what their setters keep")

  START_SET("replacing one sublayer with another")

  CALayer *root = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];
  CALayer *c = [CALayer layer];

  [root addSublayer: a];
  [root addSublayer: b];
  [root replaceSublayer: b with: c];

  PASS([[root sublayers] count] == 2, "the count does not change");
  PASS([[root sublayers] objectAtIndex: 1] == c,
       "the new layer takes the place of the old one");
  PASS([c superlayer] == root, "and its superlayer is the one it went into");
  PASS([b superlayer] == nil, "while the old one has no superlayer left");
  PASS([[root sublayers] objectAtIndex: 0] == a,
       "the layers around it are left alone");

  END_SET("replacing one sublayer with another")

  [pool release];
  return 0;
}
