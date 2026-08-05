/* CAOpenGLLayer is a CALayer.  None of the class's own drawing is checked
   here: its defining methods take a CGL context, which this framework has no
   portable equivalent for.  What is checked is that the class exists and
   behaves as the layer it is declared to be. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAOpenGLLayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a GL layer is a layer")

  CAOpenGLLayer *layer = nil;

  PASS([CAOpenGLLayer superclass] == [CALayer class],
       "a GL layer comes from CALayer");

  PASS_RUNS(layer = [CAOpenGLLayer layer];,
            "and answers the layer its class is asked for");

  if (layer == nil)
    {
      SKIP("there is no layer to ask anything of")
    }

  PASS([layer isKindOfClass: [CALayer class]], "which is a CALayer");

  [layer setBounds: CGRectMake(0, 0, 40, 30)];
  PASS(CGRectEqualToRect([layer bounds], CGRectMake(0, 0, 40, 30)),
       "keeping the bounds it is given");

  [layer setOpacity: 0.5];
  PASS([layer opacity] == 0.5, "and the opacity it is given");

  PASS([[layer sublayers] count] == 0, "starting with no sublayers");

  END_SET("a GL layer is a layer")

  [pool release];
  return 0;
}
