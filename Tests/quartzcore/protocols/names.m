/* The protocols a delegate or a layout manager names.

   Naming one of these in a class declaration is the point of the test: a
   class written against Apple QuartzCore says

     @interface Thing : NSObject <CALayerDelegate>

   and this file will not compile unless the framework declares it.  Every
   method of all three is optional, so the classes below implement nothing
   and still conform. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

@interface GSTestLayerDelegate : NSObject <CALayerDelegate>
@end
@implementation GSTestLayerDelegate
@end

@interface GSTestLayoutManager : NSObject <CALayoutManager>
@end
@implementation GSTestLayoutManager
@end

@interface GSTestAnimationDelegate : NSObject <CAAnimationDelegate>
@end
@implementation GSTestAnimationDelegate
@end

/* A class that implements the methods without naming the protocol. */
@interface GSTestQuietDelegate : NSObject
- (void) displayLayer: (CALayer *)layer;
@end
@implementation GSTestQuietDelegate
- (void) displayLayer: (CALayer *)layer {}
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the protocols exist to be named")

  PASS(@protocol(CALayerDelegate) != nil, "a layer has a delegate protocol");
  PASS(@protocol(CALayoutManager) != nil, "and a layout manager protocol");
  PASS(@protocol(CAAnimationDelegate) != nil,
       "an animation has a delegate protocol");

  END_SET("the protocols exist to be named")

  START_SET("naming one is enough to conform")

  /* Nothing below implements a single method of the protocol it names. */
  PASS([GSTestLayerDelegate conformsToProtocol: @protocol(CALayerDelegate)],
       "a class conforms by naming the layer delegate protocol");
  PASS([GSTestLayoutManager conformsToProtocol: @protocol(CALayoutManager)],
       "and by naming the layout manager protocol");
  PASS([GSTestAnimationDelegate conformsToProtocol:
         @protocol(CAAnimationDelegate)],
       "and by naming the animation delegate protocol");

  END_SET("naming one is enough to conform")

  START_SET("implementing without naming is not conforming")

  GSTestQuietDelegate *quiet = [[[GSTestQuietDelegate alloc] init] autorelease];

  PASS([quiet respondsToSelector: @selector(displayLayer:)],
       "the class implements a delegate method");
  PASS(![quiet conformsToProtocol: @protocol(CALayerDelegate)],
       "and still does not conform, since conformance is declared");

  END_SET("implementing without naming is not conforming")

  START_SET("a layer takes one")

  CALayer *layer = [CALayer layer];
  GSTestLayerDelegate *delegate =
    [[[GSTestLayerDelegate alloc] init] autorelease];
  GSTestLayoutManager *manager =
    [[[GSTestLayoutManager alloc] init] autorelease];

  [layer setDelegate: delegate];
  [layer setLayoutManager: manager];

  PASS([layer delegate] == delegate, "a layer holds such a delegate");
  PASS([layer layoutManager] == manager, "and such a layout manager");

  END_SET("a layer takes one")

  START_SET("an animation takes one")

  CAAnimation *animation = [CAAnimation animation];
  GSTestAnimationDelegate *delegate =
    [[[GSTestAnimationDelegate alloc] init] autorelease];

  [animation setDelegate: delegate];

  PASS([animation delegate] == delegate, "an animation holds such a delegate");

  END_SET("an animation takes one")

  START_SET("the protocols the classes themselves name")

  PASS([CALayer conformsToProtocol: @protocol(CAMediaTiming)],
       "a layer has a media timing");
  PASS([CAAnimation conformsToProtocol: @protocol(CAMediaTiming)],
       "and so does an animation");
  PASS([CAAnimation conformsToProtocol: @protocol(CAAction)],
       "an animation is also an action");

  END_SET("the protocols the classes themselves name")

  [pool release];
  return 0;
}
