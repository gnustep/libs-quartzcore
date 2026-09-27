/* A presentation layer stands for the layer it was made from while that layer
   animates, so it has to be a layer of the same class: a subclass that draws
   content of its own draws none of it when a plain CALayer stands for it.

   -initWithLayer: is what makes that copy here, so a subclass carries its own
   properties across by overriding it.

   Apple answers nil from -presentationLayer without a render server behind
   the layer, before and after -display and while an animation runs, and its
   -initWithLayer: copies nothing at all, so neither half of this can be
   checked against it and the file is named in APPLE_SKIP_TESTS. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAShapeLayer.h>

static CGPathRef rectPath(void)
{
  CGMutablePathRef path = CGPathCreateMutable();

  CGPathAddRect(path, NULL, CGRectMake(0, 0, 10, 10));
  return path;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the class a presentation layer is")

  CALayer *plain = [CALayer layer];
  CAShapeLayer *shape = [CAShapeLayer layer];
  CALayer *standsForPlain;
  CALayer *standsForShape;

  [plain setBounds: CGRectMake(0, 0, 40, 30)];
  standsForPlain = [plain presentationLayer];
  PASS(standsForPlain != nil, "a layer answers a presentation layer");
  PASS([standsForPlain modelLayer] == plain,
       "which answers the layer it stands for");
  PASS(CGRectEqualToRect([standsForPlain bounds], CGRectMake(0, 0, 40, 30)),
       "and carries that layer's bounds");
  PASS([standsForPlain isMemberOfClass: [CALayer class]],
       "and is a layer of the same class");

  [shape setBounds: CGRectMake(0, 0, 40, 30)];
  standsForShape = [shape presentationLayer];
  PASS([standsForShape isKindOfClass: [CAShapeLayer class]],
       "a shape layer is stood for by a shape layer");
  PASS([standsForShape modelLayer] == shape,
       "which answers the shape layer it stands for");

  END_SET("the class a presentation layer is")

  START_SET("what the copy carries")

  CAShapeLayer *shape = [CAShapeLayer layer];
  CGPathRef path = rectPath();
  CAShapeLayer *copy;

  [shape setBounds: CGRectMake(0, 0, 40, 30)];
  [shape setPath: path];
  [shape setLineWidth: 7];
  [shape setStrokeStart: 0.25];
  [shape setLineCap: kCALineCapRound];

  copy = [[CAShapeLayer alloc] initWithLayer: shape];
  PASS([copy path] == path, "the copy carries the path it was made from");
  PASS([copy lineWidth] == 7, "and the line width");
  PASS([copy strokeStart] == 0.25, "and where the stroke starts");
  PASS([[copy lineCap] isEqualToString: kCALineCapRound],
       "and the cap its line ends with");
  PASS(CGRectEqualToRect([copy bounds], CGRectMake(0, 0, 40, 30)),
       "along with the bounds a plain layer carries");

  [copy release];
  CGPathRelease(path);

  END_SET("what the copy carries")

  [pool release];
  return 0;
}
