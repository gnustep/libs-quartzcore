/* The values a shape layer starts with, and what its setters keep.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAShapeLayer.h>
#import <CoreGraphics/CoreGraphics.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the values a shape layer starts with")

  CAShapeLayer *l = [CAShapeLayer layer];

  PASS(l != nil, "a shape layer can be created");
  PASS([l isKindOfClass: [CALayer class]], "a shape layer is a layer");
  PASS([l path] == NULL, "it starts with no path");
  PASS([l strokeColor] == NULL, "it starts with no stroke colour");
  PASS([l strokeStart] == 0.0, "the stroke starts at 0");
  PASS([l lineDashPhase] == 0.0, "the line dash phase starts at 0");
  PASS([l lineDashPattern] == nil, "it starts with no line dash pattern");

  testHopeful = YES;

  {
    CGColorRef fill = [l fillColor];

    PASS(fill != NULL, "it starts with a fill colour");
    PASS(fill != NULL
         && CGColorGetNumberOfComponents(fill) == 4
         && CGColorGetComponents(fill)[0] == 0.0
         && CGColorGetComponents(fill)[1] == 0.0
         && CGColorGetComponents(fill)[2] == 0.0
         && CGColorGetAlpha(fill) == 1.0,
         "the fill colour it starts with is opaque black");
  }

  PASS([[l fillRule] isEqualToString: kCAFillRuleNonZero],
       "it starts filling by the non-zero rule");
  PASS([l strokeEnd] == 1.0, "the stroke ends at 1");
  PASS([l lineWidth] == 1.0, "the line width starts at 1");
  PASS([l miterLimit] == 10.0, "the miter limit starts at 10");
  PASS([[l lineCap] isEqualToString: kCALineCapButt],
       "the line cap starts butt");
  PASS([[l lineJoin] isEqualToString: kCALineJoinMiter],
       "the line join starts miter");

  testHopeful = NO;

  END_SET("the values a shape layer starts with")

  START_SET("what a shape layer's setters keep")

  CAShapeLayer *l = [CAShapeLayer layer];

  [l setLineWidth: 4.5];
  PASS([l lineWidth] == 4.5, "the line width reads back as it was set");

  [l setMiterLimit: 3.0];
  PASS([l miterLimit] == 3.0, "the miter limit reads back as it was set");

  [l setStrokeStart: 0.25];
  PASS([l strokeStart] == 0.25, "the stroke start reads back as it was set");

  [l setStrokeEnd: 0.75];
  PASS([l strokeEnd] == 0.75, "the stroke end reads back as it was set");

  [l setLineDashPhase: 2.0];
  PASS([l lineDashPhase] == 2.0,
       "the line dash phase reads back as it was set");

  [l setFillRule: kCAFillRuleEvenOdd];
  PASS([[l fillRule] isEqualToString: kCAFillRuleEvenOdd],
       "the fill rule reads back as it was set");

  [l setLineCap: kCALineCapRound];
  PASS([[l lineCap] isEqualToString: kCALineCapRound],
       "the line cap reads back as it was set");

  [l setLineJoin: kCALineJoinBevel];
  PASS([[l lineJoin] isEqualToString: kCALineJoinBevel],
       "the line join reads back as it was set");

  END_SET("what a shape layer's setters keep")

  START_SET("a line dash pattern is copied")

  CAShapeLayer *l = [CAShapeLayer layer];
  NSMutableArray *pattern = [NSMutableArray array];

  [pattern addObject: [NSNumber numberWithInt: 4]];
  [pattern addObject: [NSNumber numberWithInt: 2]];
  [l setLineDashPattern: pattern];
  [pattern addObject: [NSNumber numberWithInt: 9]];

  PASS([[l lineDashPattern] count] == 2,
       "changing the array afterwards does not change the layer");
  PASS([l lineDashPattern] != pattern,
       "the layer holds a copy and not the array it was given");

  END_SET("a line dash pattern is copied")

  [pool release];
  return 0;
}
