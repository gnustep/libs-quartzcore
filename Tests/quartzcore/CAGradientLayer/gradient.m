/* CAGradientLayer: what a fresh gradient layer holds, and what its setters
   keep.  Expected values checked against Apple QuartzCore.

   This covers the properties only.  A gradient layer does not draw itself
   here yet. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAGradientLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a gradient layer starts with")

  CAGradientLayer *g = [CAGradientLayer layer];

  PASS([g isKindOfClass: [CALayer class]], "a gradient layer is a layer");
  PASS([g colors] == nil, "a gradient layer starts with no colours");
  PASS([g locations] == nil, "a gradient layer starts with no locations");
  PASS([g startPoint].x == 0.5 && [g startPoint].y == 0.0,
       "a gradient starts at the middle of the top edge");
  PASS([g endPoint].x == 0.5 && [g endPoint].y == 1.0,
       "a gradient ends at the middle of the bottom edge");
  PASS([[g type] isEqualToString: kCAGradientLayerAxial],
       "a gradient layer is axial");
  PASS([g opacity] == 1.0, "a gradient layer keeps what a layer starts with");

  END_SET("what a gradient layer starts with")

  START_SET("the gradient type names")

  PASS([kCAGradientLayerAxial isEqualToString: @"axial"],
       "the axial gradient is named axial");
  PASS([kCAGradientLayerRadial isEqualToString: @"radial"],
       "the radial gradient is named radial");
  PASS([kCAGradientLayerConic isEqualToString: @"conic"],
       "the conic gradient is named conic");

  END_SET("the gradient type names")

  START_SET("what the setters keep")

  CAGradientLayer *g = [CAGradientLayer layer];
  NSArray *locations = [NSArray arrayWithObjects:
    [NSNumber numberWithFloat: 0.0],
    [NSNumber numberWithFloat: 0.5],
    [NSNumber numberWithFloat: 1.0], nil];

  [g setLocations: locations];
  PASS([[g locations] count] == 3, "the locations read back");
  PASS([[[g locations] objectAtIndex: 1] floatValue] == 0.5,
       "a location reads back as it was set");

  [g setStartPoint: CGPointMake(0.25, 0.75)];
  PASS([g startPoint].x == 0.25 && [g startPoint].y == 0.75,
       "the start point reads back as it was set");

  [g setEndPoint: CGPointMake(1.0, 1.0)];
  PASS([g endPoint].x == 1.0 && [g endPoint].y == 1.0,
       "the end point reads back as it was set");

  [g setType: kCAGradientLayerRadial];
  PASS([[g type] isEqualToString: kCAGradientLayerRadial],
       "the type reads back as it was set");

  /* Apple does not check the name against the three it knows. */
  [g setType: @"notAGradientType"];
  PASS([[g type] isEqualToString: @"notAGradientType"],
       "a type that is not a gradient is kept as it was given");

  [g setLocations: nil];
  PASS([g locations] == nil, "the locations can be taken away again");

  END_SET("what the setters keep")

  /* Apple answers NO from +needsDisplayForKey: for colors, locations and
     startPoint.  CALayer has no such method here, so it is not checked. */

  [pool release];
  return 0;
}
