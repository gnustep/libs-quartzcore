/* What a CAEmitterLayer and a CAEmitterCell hold before anything is set.

   Every value here was measured against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/QuartzCore.h>

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the two classes")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];

  PASS([CAEmitterLayer superclass] == [CALayer class],
       "an emitter layer is a layer");
  PASS([CAEmitterCell superclass] == [NSObject class],
       "an emitter cell is not");
  PASS(![cell isKindOfClass: [CALayer class]],
       "a cell is no kind of layer");
  PASS([cell conformsToProtocol: @protocol(CAMediaTiming)],
       "a cell has a timing of its own");
  PASS([cell conformsToProtocol: @protocol(NSCoding)], "a cell can be coded");
  PASS([cell conformsToProtocol: @protocol(NSCopying)], "and copied");

  END_SET("the two classes")

  START_SET("what an emitter layer starts with")

  CAEmitterLayer *layer = [CAEmitterLayer layer];

  PASS([layer emitterCells] == nil, "no cells");
  PASS(CLOSE([layer emitterPosition].x, 0) && CLOSE([layer emitterPosition].y, 0),
       "the emitter sits at the origin");
  PASS(CLOSE([layer emitterZPosition], 0), "at depth zero");
  PASS(CLOSE([layer emitterSize].width, 0)
       && CLOSE([layer emitterSize].height, 0), "with no size");
  PASS(CLOSE([layer emitterDepth], 0), "and no depth");
  PASS([[layer emitterShape] isEqualToString: kCAEmitterLayerPoint],
       "it emits from a point");
  PASS([[layer emitterMode] isEqualToString: kCAEmitterLayerVolume],
       "throughout the volume of that shape");
  PASS([[layer renderMode] isEqualToString: kCAEmitterLayerUnordered],
       "and draws the particles in no particular order");
  PASS(CLOSE([layer scale], 1), "the scale multiplier is one");
  PASS([layer seed] == 0, "the seed is zero");
  PASS(CLOSE([layer spin], 1), "and so are the spin");
  PASS(CLOSE([layer velocity], 1), "velocity");
  PASS(CLOSE([layer birthRate], 1), "birth rate");
  PASS(CLOSE([layer lifetime], 1), "and lifetime multipliers");
  PASS(![layer preservesDepth], "depth is not preserved");

  END_SET("what an emitter layer starts with")

  START_SET("two emitter layers seed the same")

  PASS([[CAEmitterLayer layer] seed] == [[CAEmitterLayer layer] seed],
       "the seed is not random");

  END_SET("two emitter layers seed the same")

  START_SET("what an emitter cell starts with")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];
  CGRect rect = [cell contentsRect];

  PASS([cell contents] == nil, "no contents");
  PASS(CLOSE(rect.origin.x, 0) && CLOSE(rect.origin.y, 0)
       && CLOSE(rect.size.width, 1) && CLOSE(rect.size.height, 1),
       "the whole of them is drawn");
  PASS(CLOSE([cell contentsScale], 1), "at a scale of one");
  PASS([cell emitterCells] == nil, "no cells of its own");
  PASS([cell isEnabled], "a cell is enabled");
  PASS([cell name] == nil, "with no name");
  PASS([cell style] == nil, "and no style");

  END_SET("what an emitter cell starts with")

  START_SET("the colour a cell starts with")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];
  CGColorRef color = [cell color];

  PASS(color != NULL, "a cell has a colour");
  if (color != NULL)
    {
      const CGFloat *c = CGColorGetComponents(color);

      PASS(CGColorGetNumberOfComponents(color) == 4,
           "of four components");
      PASS(CLOSE(c[0], 1) && CLOSE(c[1], 1) && CLOSE(c[2], 1) && CLOSE(c[3], 1),
           "opaque white");
    }

  END_SET("the colour a cell starts with")

  START_SET("a cell varies nothing to begin with")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];

  PASS(CLOSE([cell redRange], 0) && CLOSE([cell greenRange], 0)
       && CLOSE([cell blueRange], 0) && CLOSE([cell alphaRange], 0),
       "no colour component varies");
  PASS(CLOSE([cell redSpeed], 0) && CLOSE([cell greenSpeed], 0)
       && CLOSE([cell blueSpeed], 0) && CLOSE([cell alphaSpeed], 0),
       "and none of them changes over a lifetime");
  PASS(CLOSE([cell spin], 0) && CLOSE([cell spinRange], 0), "it does not spin");
  PASS(CLOSE([cell emissionLatitude], 0) && CLOSE([cell emissionLongitude], 0)
       && CLOSE([cell emissionRange], 0), "and emits along one direction");
  PASS(CLOSE([cell velocity], 0) && CLOSE([cell velocityRange], 0),
       "at no speed");
  PASS(CLOSE([cell xAcceleration], 0) && CLOSE([cell yAcceleration], 0)
       && CLOSE([cell zAcceleration], 0), "and no acceleration");

  END_SET("a cell varies nothing to begin with")

  START_SET("a cell emits nothing until it is told to")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];

  PASS(CLOSE([cell birthRate], 0), "nothing is born");
  PASS(CLOSE([cell lifetime], 0) && CLOSE([cell lifetimeRange], 0),
       "and would not live if it were");

  END_SET("a cell emits nothing until it is told to")

  START_SET("how a cell scales and filters its contents")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];

  PASS(CLOSE([cell scale], 1), "the scale is one");
  PASS(CLOSE([cell scaleRange], 0) && CLOSE([cell scaleSpeed], 0),
       "and does not vary or change");
  PASS([[cell magnificationFilter] isEqualToString: kCAFilterLinear],
       "contents are magnified linearly");
  PASS([[cell minificationFilter] isEqualToString: kCAFilterLinear],
       "and reduced linearly");
  PASS(CLOSE([cell minificationFilterBias], 0), "with no bias");

  END_SET("how a cell scales and filters its contents")

  START_SET("the shapes an emitter can have")

  PASS([kCAEmitterLayerPoint isEqualToString: @"point"], "point");
  PASS([kCAEmitterLayerLine isEqualToString: @"line"], "line");
  PASS([kCAEmitterLayerRectangle isEqualToString: @"rectangle"], "rectangle");
  PASS([kCAEmitterLayerCuboid isEqualToString: @"cuboid"], "cuboid");
  PASS([kCAEmitterLayerCircle isEqualToString: @"circle"], "circle");
  PASS([kCAEmitterLayerSphere isEqualToString: @"sphere"], "sphere");

  END_SET("the shapes an emitter can have")

  START_SET("where in a shape the particles come from")

  PASS([kCAEmitterLayerPoints isEqualToString: @"points"], "points");
  PASS([kCAEmitterLayerOutline isEqualToString: @"outline"], "outline");
  PASS([kCAEmitterLayerSurface isEqualToString: @"surface"], "surface");
  PASS([kCAEmitterLayerVolume isEqualToString: @"volume"], "volume");

  END_SET("where in a shape the particles come from")

  START_SET("the order the particles are drawn in")

  PASS([kCAEmitterLayerUnordered isEqualToString: @"unordered"], "unordered");
  PASS([kCAEmitterLayerOldestFirst isEqualToString: @"oldestFirst"],
       "oldest first");
  PASS([kCAEmitterLayerOldestLast isEqualToString: @"oldestLast"],
       "oldest last");
  PASS([kCAEmitterLayerBackToFront isEqualToString: @"backToFront"],
       "back to front");
  PASS([kCAEmitterLayerAdditive isEqualToString: @"additive"], "additive");

  END_SET("the order the particles are drawn in")

  START_SET("the defaults each class answers for")

  PASS([[CAEmitterCell defaultValueForKey: @"enabled"] boolValue],
       "a cell is enabled by default");
  PASS(CLOSE([[CAEmitterCell defaultValueForKey: @"scale"] floatValue], 1),
       "and scaled by one");
  PASS([CAEmitterCell defaultValueForKey: @"birthRate"] == nil,
       "it names no default birth rate");
  PASS([CAEmitterCell defaultValueForKey: @"lifetime"] == nil,
       "and no default lifetime");
  PASS([CAEmitterCell defaultValueForKey: @"bogus"] == nil,
       "a key it does not know answers nothing");

  PASS(CLOSE([[CAEmitterLayer defaultValueForKey: @"birthRate"] floatValue], 1),
       "the layer does name a default birth rate");
  PASS([[CAEmitterLayer defaultValueForKey: @"emitterShape"]
         isEqualToString: kCAEmitterLayerPoint],
       "and the shape it emits from");
  PASS(CLOSE([[CAEmitterLayer defaultValueForKey: @"scale"] floatValue], 1),
       "and its scale");

  END_SET("the defaults each class answers for")

  START_SET("what a cell puts in an archive")

  CAEmitterCell *cell = [CAEmitterCell emitterCell];

  PASS(![cell shouldArchiveValueForKey: @"name"],
       "a cell archives nothing by default");

  END_SET("what a cell puts in an archive")

  START_SET("giving cells to a layer")

  CAEmitterLayer *layer = [CAEmitterLayer layer];
  CAEmitterCell *cell = [CAEmitterCell emitterCell];
  NSMutableArray *given = [NSMutableArray arrayWithObject: cell];

  [layer setEmitterCells: given];

  PASS([[layer emitterCells] count] == 1, "the layer holds the cell");
  PASS([[layer emitterCells] objectAtIndex: 0] == cell,
       "the cell itself, not a copy of it");

  [given removeAllObjects];

  PASS([[layer emitterCells] count] == 1,
       "the array is copied, so emptying the original leaves the layer alone");

  END_SET("giving cells to a layer")

  START_SET("a cell holding cells")

  CAEmitterCell *parent = [CAEmitterCell emitterCell];
  CAEmitterCell *child = [CAEmitterCell emitterCell];

  [parent setEmitterCells: [NSArray arrayWithObject: child]];

  PASS([[parent emitterCells] count] == 1,
       "a cell can hold cells of its own");
  PASS([[parent emitterCells] objectAtIndex: 0] == child,
       "which is how a particle emits particles");

  END_SET("a cell holding cells")

  [pool release];
  return 0;
}
