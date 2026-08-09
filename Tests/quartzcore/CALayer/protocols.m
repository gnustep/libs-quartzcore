/* The messages a layer sends its delegate and its layout manager.

   The expected values are the ones Apple QuartzCore produces: a delegate is
   told a layer is about to draw, a layout manager is told the moment a
   layout that was good becomes one that is not, and a layer with no layout
   manager prefers the size of its own bounds. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

static NSMutableArray *sent;

@interface Drawer : NSObject
@end

@implementation Drawer
- (void) layerWillDraw: (CALayer *)layer
{
  [sent addObject: @"layerWillDraw:"];
}

- (void) drawLayer: (CALayer *)layer inContext: (CGContextRef)context
{
  [sent addObject: @"drawLayer:inContext:"];
}
@end

@interface Manager : NSObject
@end

@implementation Manager
- (void) layoutSublayersOfLayer: (CALayer *)layer
{
  [sent addObject: @"layoutSublayersOfLayer:"];
}

- (void) invalidateLayoutOfLayer: (CALayer *)layer
{
  [sent addObject: @"invalidateLayoutOfLayer:"];
}

- (CGSize) preferredSizeOfLayer: (CALayer *)layer
{
  [sent addObject: @"preferredSizeOfLayer:"];
  return CGSizeMake(11, 22);
}
@end

/* A layer under a layout manager, laid out, so that the next change to it is
   one that turns a good layout into a bad one. */
static CALayer *
settled(void)
{
  CALayer *layer = [CALayer layer];

  [layer setBounds: CGRectMake(0, 0, 50, 50)];
  [layer setLayoutManager: (id)[[Manager new] autorelease]];
  [layer layoutIfNeeded];
  [sent removeAllObjects];
  return layer;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  sent = [NSMutableArray array];

  START_SET("a delegate that draws the layer")

  CALayer *layer = [CALayer layer];
  Drawer *drawer = [[Drawer new] autorelease];

  [layer setBounds: CGRectMake(0, 0, 20, 20)];
  [layer setDelegate: drawer];
  [sent removeAllObjects];

  [layer display];

  PASS([sent count] == 2, "both messages reach the delegate");
  PASS([sent count] > 0
       && [[sent objectAtIndex: 0] isEqualToString: @"layerWillDraw:"],
       "it is told the layer is about to draw first");
  PASS([sent count] > 1
       && [[sent objectAtIndex: 1] isEqualToString: @"drawLayer:inContext:"],
       "and asked to draw it second");

  END_SET("a delegate that draws the layer")

  START_SET("a layout that stops being good")

  CALayer *layer = settled();

  [layer setNeedsLayout];

  PASS([sent containsObject: @"invalidateLayoutOfLayer:"],
       "the layout manager is told the layout is no longer good");

  [sent removeAllObjects];
  [layer setNeedsLayout];
  PASS(![sent containsObject: @"invalidateLayoutOfLayer:"],
       "and is not told again while the layout is still not good");

  END_SET("a layout that stops being good")

  START_SET("what makes a layout stop being good")

  CALayer *layer = settled();

  [layer addSublayer: [CALayer layer]];
  PASS([sent containsObject: @"invalidateLayoutOfLayer:"],
       "a sublayer arriving does");

  layer = settled();
  [layer setBounds: CGRectMake(0, 0, 60, 60)];
  PASS([sent containsObject: @"invalidateLayoutOfLayer:"],
       "so does the layer being resized");

  layer = settled();
  [layer setPosition: CGPointMake(5, 5)];
  PASS(![sent containsObject: @"invalidateLayoutOfLayer:"],
       "but moving it does not, its sublayers sitting where they did");

  END_SET("what makes a layout stop being good")

  START_SET("laying out again")

  CALayer *layer = settled();

  [layer layoutIfNeeded];
  PASS([sent count] == 0,
       "a layer that has been laid out and not changed lays out no further");

  END_SET("laying out again")

  START_SET("the size a layer prefers")

  CALayer *plain = [CALayer layer];
  CALayer *managed = [CALayer layer];
  CGSize preferred;

  [plain setBounds: CGRectMake(0, 0, 30, 40)];
  preferred = [plain preferredFrameSize];
  PASS(preferred.width == 30 && preferred.height == 40,
       "a layer with no layout manager prefers the size it has");

  [managed setBounds: CGRectMake(0, 0, 50, 50)];
  [managed setLayoutManager: (id)[[Manager new] autorelease]];
  [sent removeAllObjects];
  preferred = [managed preferredFrameSize];

  PASS(preferred.width == 11 && preferred.height == 22,
       "and one with a layout manager prefers the size it is given");
  PASS([sent containsObject: @"preferredSizeOfLayer:"],
       "the manager being the one asked");

  END_SET("the size a layer prefers")

  [pool release];
  return 0;
}
