/* The values a layer starts with, and the shape of its sublayer tree.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <CoreGraphics/CoreGraphics.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the values a layer starts with")

  CALayer *l = [CALayer layer];

  PASS([l opacity] == 1.0, "a layer starts fully opaque");
  PASS([l isHidden] == NO, "a layer starts visible");
  PASS([l masksToBounds] == NO, "a layer does not mask to its bounds");
  PASS([l isGeometryFlipped] == NO, "a layer's geometry is not flipped");
  PASS([l zPosition] == 0.0, "a layer sits at a z position of 0");
  PASS([l shadowOpacity] == 0.0, "a layer's shadow starts fully transparent");
  PASS([l shadowRadius] == 3.0, "a layer's shadow radius starts at 3");
  PASS([l shadowOffset].width == 0.0 && [l shadowOffset].height == -3.0,
       "a layer's shadow is offset up by 3");
  PASS(CGRectEqualToRect([l contentsRect], CGRectMake(0, 0, 1, 1)),
       "a layer's contents rect is the unit rect");
  PASS([l needsDisplayOnBoundsChange] == NO,
       "a layer does not redraw when its bounds change");
  PASS([l shouldRasterize] == NO, "a layer does not rasterise");
  PASS([l superlayer] == nil, "a layer starts with no superlayer");
  PASS([l actions] == nil, "a layer starts with no actions");
  PASS([l style] == nil, "a layer starts with no style");
  PASS([l contents] == nil, "a layer starts with no contents");
  PASS([l backgroundColor] == NULL, "a layer starts with no background");

  PASS([l sublayers] == nil, "a layer starts with no sublayers at all");

  testHopeful = YES;
  PASS([l modelLayer] == l, "a layer is its own model layer");
  PASS([[l contentsGravity] isEqualToString: kCAGravityResize],
       "a layer's contents gravity is resize");
  PASS([l borderColor] != NULL, "a layer starts with a border colour");
  testHopeful = NO;

  END_SET("the values a layer starts with")

  START_SET("a layer that has lost its sublayers")

  CALayer *l = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [l addSublayer: a];
  PASS([l sublayers] != nil, "having one, it answers an array");

  [a removeFromSuperlayer];
  PASS([l sublayers] == nil, "having lost the only one, it answers nothing");

  [l addSublayer: a];
  [l addSublayer: b];
  [a removeFromSuperlayer];
  PASS([[l sublayers] count] == 1, "losing one of two leaves the other");
  [b removeFromSuperlayer];
  PASS([l sublayers] == nil, "and losing that one leaves nothing again");

  [l setSublayers: [NSArray arrayWithObject: a]];
  [l setSublayers: [NSArray array]];
  PASS([l sublayers] == nil, "being given an empty array is the same thing");

  [l setSublayers: [NSArray arrayWithObject: a]];
  [l setSublayers: nil];
  PASS([l sublayers] == nil, "and so is being given nothing");

  /* Being given nothing must not stop it taking sublayers later. */
  [l addSublayer: a];
  PASS([[l sublayers] count] == 1, "a layer given nothing can still be given one");

  END_SET("a layer that has lost its sublayers")

  START_SET("the sublayer tree")

  CALayer *root = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];
  CALayer *c = [CALayer layer];

  [root addSublayer: a];
  PASS([[root sublayers] count] == 1, "adding a sublayer leaves one behind");
  PASS([a superlayer] == root, "and its superlayer is the one it went into");

  [root addSublayer: b];
  [root addSublayer: c];
  PASS([[root sublayers] objectAtIndex: 0] == a
       && [[root sublayers] objectAtIndex: 1] == b
       && [[root sublayers] objectAtIndex: 2] == c,
       "sublayers are kept in the order they were added");

  [b removeFromSuperlayer];
  PASS([[root sublayers] count] == 2, "removing one leaves the rest");
  PASS([b superlayer] == nil, "and the one removed has no superlayer");

  CALayer *d = [CALayer layer];

  [root insertSublayer: d atIndex: 0];
  PASS([[root sublayers] objectAtIndex: 0] == d,
       "inserting at an index puts it there");

  CALayer *e = [CALayer layer];

  [root insertSublayer: e below: a];
  PASS([[root sublayers] indexOfObject: e] == 1,
       "inserting below a layer puts it just under that one");

  CALayer *f = [CALayer layer];

  [root insertSublayer: f above: a];
  PASS([[root sublayers] indexOfObject: f] == 3,
       "inserting above a layer puts it just over that one");

  CALayer *other = [CALayer layer];

  [other addSublayer: a];
  PASS([a superlayer] == other, "and its superlayer is where it went");

  /* #19 is what takes a layer out of the tree it was already in. */
  testHopeful = YES;
  PASS([[root sublayers] count] == 4,
       "adding a layer elsewhere takes it out of where it was");
  testHopeful = NO;

  END_SET("the sublayer tree")

  START_SET("setting the sublayers wholesale")

  CALayer *root = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [root setSublayers: [NSArray arrayWithObjects: a, b, nil]];
  PASS([[root sublayers] count] == 2, "the layers given are the sublayers");

  testHopeful = YES;
  PASS([a superlayer] == root && [b superlayer] == root,
       "and each one's superlayer is the layer they went into");
  testHopeful = NO;

  END_SET("setting the sublayers wholesale")

  [pool release];
  return 0;
}
