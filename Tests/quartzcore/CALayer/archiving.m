/* -contentsAreFlipped and -shouldArchiveValueForKey:, both measured against
   Apple QuartzCore.  A layer's contents are flipped when an odd number of
   layers between it and the root have their geometry flipped, and a layer
   archives a property once that property has been given a value, with
   allowsEdgeAntialiasing and allowsGroupOpacity archived from the start
   because Apple takes them from the application bundle. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

static void flipping(void)
{
  CALayer *l = [CALayer layer];

  PASS([l contentsAreFlipped] == NO, "a new layer does not flip its contents");
  [l setGeometryFlipped: YES];
  PASS([l contentsAreFlipped] == YES,
       "flipped geometry flips the contents with it");

  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];
  CALayer *c = [CALayer layer];
  [a addSublayer: b];
  [b addSublayer: c];

  PASS([c contentsAreFlipped] == NO,
       "a layer under two unflipped layers is unflipped");

  [a setGeometryFlipped: YES];
  PASS([b contentsAreFlipped] == YES && [c contentsAreFlipped] == YES,
       "one flipped ancestor flips everything below it");

  [b setGeometryFlipped: YES];
  PASS([b contentsAreFlipped] == NO && [c contentsAreFlipped] == NO,
       "a second flip along the same path cancels the first");

  [c setGeometryFlipped: YES];
  PASS([c contentsAreFlipped] == YES, "and a third flips it again");

  [c removeFromSuperlayer];
  PASS([c contentsAreFlipped] == YES,
       "a flipped layer with no superlayer flips its own contents");
}

static void freshLayer(void)
{
  CALayer *l = [CALayer layer];

  PASS([l shouldArchiveValueForKey: @"position"] == NO,
       "a new layer does not archive its position");
  PASS([l shouldArchiveValueForKey: @"bounds"] == NO,
       "a new layer does not archive its bounds");
  PASS([l shouldArchiveValueForKey: @"delegate"] == NO,
       "a new layer does not archive its delegate");
  PASS([l shouldArchiveValueForKey: @"contents"] == NO,
       "a new layer does not archive its contents");
  PASS([l shouldArchiveValueForKey: @"opacity"] == NO,
       "a new layer does not archive its opacity");
  PASS([l shouldArchiveValueForKey: @"hidden"] == NO,
       "a new layer does not archive whether it is hidden");
  PASS([l shouldArchiveValueForKey: @"transform"] == NO,
       "a new layer does not archive its transform");
  PASS([l shouldArchiveValueForKey: @"mask"] == NO,
       "a new layer does not archive its mask");
  PASS([l shouldArchiveValueForKey: @"filters"] == NO,
       "a new layer does not archive its filters");
  PASS([l shouldArchiveValueForKey: @"contentsCenter"] == NO,
       "a new layer does not archive its contents centre");
  PASS([l shouldArchiveValueForKey: @"style"] == NO,
       "a new layer does not archive its style");
  PASS([l shouldArchiveValueForKey: @"actions"] == NO,
       "a new layer does not archive its actions");
  PASS([l shouldArchiveValueForKey: @"sublayers"] == NO,
       "a new layer does not archive its sublayers");
  PASS([l shouldArchiveValueForKey: @"superlayer"] == NO,
       "a new layer does not archive its superlayer");

  PASS([l shouldArchiveValueForKey: @"allowsEdgeAntialiasing"] == YES,
       "a new layer does archive whether it allows edge antialiasing");
  PASS([l shouldArchiveValueForKey: @"allowsGroupOpacity"] == YES,
       "a new layer does archive whether it allows group opacity");

  PASS([l shouldArchiveValueForKey: @"notAKeyAtAll"] == NO,
       "a key the layer does not have is not archived");
  PASS([l shouldArchiveValueForKey: @""] == NO,
       "an empty key is not archived");
  PASS([l shouldArchiveValueForKey: nil] == NO, "and neither is no key");
}

static void afterSetting(void)
{
  CALayer *l = [CALayer layer];
  [l setOpacity: 0.5];
  PASS([l shouldArchiveValueForKey: @"opacity"] == YES,
       "a layer archives an opacity it was given");

  CALayer *h = [CALayer layer];
  [h setHidden: YES];
  PASS([h shouldArchiveValueForKey: @"hidden"] == YES,
       "and archives that it was hidden");

  CALayer *b = [CALayer layer];
  [b setBounds: CGRectMake(0, 0, 10, 10)];
  PASS([b shouldArchiveValueForKey: @"bounds"] == YES,
       "a layer archives bounds it was given");
  PASS([b shouldArchiveValueForKey: @"position"] == NO,
       "and does not archive a position nobody set");

  CALayer *f = [CALayer layer];
  [f setFrame: CGRectMake(1, 2, 3, 4)];
  PASS([f shouldArchiveValueForKey: @"bounds"] == YES
       && [f shouldArchiveValueForKey: @"position"] == YES,
       "setting the frame gives the layer both bounds and position");
  PASS([f shouldArchiveValueForKey: @"frame"] == NO,
       "the frame itself is never archived");

  CALayer *k = [CALayer layer];
  [k setValue: [NSNumber numberWithFloat: 0.25] forKey: @"opacity"];
  PASS([k shouldArchiveValueForKey: @"opacity"] == YES,
       "a value given through key value coding is archived too");

  CALayer *m = [CALayer layer];
  [m setMask: [CALayer layer]];
  [m setFilters: [NSArray array]];
  [m setContentsCenter: CGRectMake(0, 0, 0.5, 0.5)];
  PASS([m shouldArchiveValueForKey: @"mask"] == YES,
       "a layer archives a mask it was given");
  PASS([m shouldArchiveValueForKey: @"filters"] == YES,
       "and filters it was given");
  PASS([m shouldArchiveValueForKey: @"contentsCenter"] == YES,
       "and a contents centre it was given");

  CALayer *parent = [CALayer layer];
  CALayer *child = [CALayer layer];
  [parent addSublayer: child];
  PASS([parent shouldArchiveValueForKey: @"sublayers"] == YES,
       "adding a sublayer gives the superlayer sublayers to archive");
  PASS([child shouldArchiveValueForKey: @"superlayer"] == NO,
       "while the sublayer still does not archive its superlayer");

  CALayer *shape = (CALayer *)[CAShapeLayer layer];
  PASS([shape shouldArchiveValueForKey: @"path"] == NO,
       "a subclass does not archive a property nobody set either");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("flipping and archiving")

  flipping();
  freshLayer();
  afterSetting();

  END_SET("flipping and archiving")

  [pool release];
  return 0;
}
