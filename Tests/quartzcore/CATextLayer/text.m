/* CATextLayer: what a fresh text layer holds and what its setters keep.
   Expected values checked against Apple QuartzCore.

   This covers the properties.  A text layer does not draw its text yet. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATextLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a text layer starts with")

  CATextLayer *t = [CATextLayer layer];

  PASS([t isKindOfClass: [CALayer class]], "a text layer is a layer");
  PASS([t string] == nil, "a text layer starts with no text");
  PASS([t fontSize] == 36.0, "the text is 36 points");
  PASS([t isWrapped] == NO, "the text is not wrapped");
  PASS([[t alignmentMode] isEqualToString: kCAAlignmentNatural],
       "the text is aligned naturally");
  PASS([[t truncationMode] isEqualToString: kCATruncationNone],
       "the text is not truncated");
  PASS([t font] != NULL, "a text layer starts with a font");

  END_SET("what a text layer starts with")

  START_SET("the colour the text is drawn in")

  CATextLayer *t = [CATextLayer layer];
  CGColorRef colour = [t foregroundColor];

  PASS(colour != NULL, "a text layer starts with a colour");
  PASS(CGColorGetNumberOfComponents(colour) == 4,
       "the colour has four components");
  PASS(CGColorGetAlpha(colour) == 1.0, "the colour is opaque");

  const CGFloat *components = CGColorGetComponents(colour);

  PASS(components[0] == 1.0 && components[1] == 1.0 && components[2] == 1.0,
       "the colour is white");

  END_SET("the colour the text is drawn in")

  START_SET("the alignment names")

  PASS([kCAAlignmentNatural isEqualToString: @"natural"], "natural");
  PASS([kCAAlignmentLeft isEqualToString: @"left"], "left");
  PASS([kCAAlignmentRight isEqualToString: @"right"], "right");
  PASS([kCAAlignmentCenter isEqualToString: @"center"], "center");
  PASS([kCAAlignmentJustified isEqualToString: @"justified"], "justified");

  END_SET("the alignment names")

  START_SET("the truncation names")

  PASS([kCATruncationNone isEqualToString: @"none"], "none");
  PASS([kCATruncationStart isEqualToString: @"start"], "start");
  PASS([kCATruncationEnd isEqualToString: @"end"], "end");
  PASS([kCATruncationMiddle isEqualToString: @"middle"], "middle");

  END_SET("the truncation names")

  START_SET("what the setters keep")

  CATextLayer *t = [CATextLayer layer];

  [t setString: @"hello"];
  PASS([[t string] isEqualToString: @"hello"], "the text reads back");

  [t setFontSize: 12.0];
  PASS([t fontSize] == 12.0, "the size reads back");

  [t setWrapped: YES];
  PASS([t isWrapped] == YES, "wrapping reads back");

  [t setAlignmentMode: kCAAlignmentCenter];
  PASS([[t alignmentMode] isEqualToString: kCAAlignmentCenter],
       "the alignment reads back");

  [t setTruncationMode: kCATruncationEnd];
  PASS([[t truncationMode] isEqualToString: kCATruncationEnd],
       "the truncation reads back");

  /* Apple does not check the name against the ones it knows. */
  [t setAlignmentMode: @"notAnAlignment"];
  PASS([[t alignmentMode] isEqualToString: @"notAnAlignment"],
       "an alignment that is not one of them is kept as it was given");

  [t setFont: (CFTypeRef)@"Times"];
  PASS([(id)[t font] isEqualToString: @"Times"],
       "a font named by a string reads back as that string");

  [t setString: nil];
  PASS([t string] == nil, "the text can be taken away again");

  END_SET("what the setters keep")

  START_SET("the colour it is given")

  CATextLayer *t = [CATextLayer layer];
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGFloat values[4] = {1.0, 0.0, 0.0, 1.0};
  CGColorRef red = CGColorCreate(space, values);

  [t setForegroundColor: red];
  PASS([t foregroundColor] == red,
       "the colour it is given is the colour it answers");
  CGColorRelease(red);
  CGColorSpaceRelease(space);

  PASS(CGColorGetAlpha([t foregroundColor]) == 1.0,
       "the colour it kept is still there after the caller let go");

  END_SET("the colour it is given")

  [pool release];
  return 0;
}
