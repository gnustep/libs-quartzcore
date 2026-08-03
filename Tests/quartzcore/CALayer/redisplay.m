/* Which property changes redisplay a layer.

   +needsDisplayForKey: answers NO for every key, and a subclass overrides it
   to have a change to one of its properties mark the layer.  The expected
   values are the ones Apple QuartzCore produces. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

/* Redisplays for a change to the opacity and for nothing else. */
@interface RedisplayLayer : CALayer
@end

@implementation RedisplayLayer
+ (BOOL) needsDisplayForKey: (NSString *)key
{
  if ([key isEqualToString: @"opacity"])
    return YES;
  return [super needsDisplayForKey: key];
}
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a layer answers by default")

  PASS([CALayer needsDisplayForKey: @"bounds"] == NO,
       "a layer does not redisplay for its bounds");
  PASS([CALayer needsDisplayForKey: @"position"] == NO,
       "nor for its position");
  PASS([CALayer needsDisplayForKey: @"opacity"] == NO,
       "nor for its opacity");
  PASS([CALayer needsDisplayForKey: @"contents"] == NO,
       "nor for its contents");
  PASS([CALayer needsDisplayForKey: @"aKeyNobodyDefines"] == NO,
       "a key it does not have answers no rather than raising");
  PASS([CALayer needsDisplayForKey: nil] == NO, "and so does no key at all");

  END_SET("what a layer answers by default")

  START_SET("a layer that asks for nothing")

  CALayer *l = [CALayer layer];

  [l displayIfNeeded];
  PASS([l needsDisplay] == NO, "a layer that has displayed wants nothing");

  [l setOpacity: 0.5];
  PASS([l needsDisplay] == NO,
       "and a property it does not redisplay for leaves it that way");

  END_SET("a layer that asks for nothing")

  START_SET("a subclass that asks for one property")

  RedisplayLayer *r = [RedisplayLayer layer];

  PASS([RedisplayLayer needsDisplayForKey: @"opacity"] == YES,
       "the subclass answers for the property it overrode");
  PASS([RedisplayLayer needsDisplayForKey: @"bounds"] == NO,
       "and leaves the rest to its superclass");

  [r displayIfNeeded];
  [r setBounds: CGRectMake(0, 0, 10, 10)];
  PASS([r needsDisplay] == NO,
       "a property it does not ask for does not redisplay it");

  [r setOpacity: 0.25];
  PASS([r needsDisplay] == YES, "and the one it asks for does");

  END_SET("a subclass that asks for one property")

  START_SET("setting a property to what it already is")

  RedisplayLayer *same = [RedisplayLayer layer];

  [same setOpacity: 0.25];
  [same displayIfNeeded];
  PASS([same needsDisplay] == NO, "the layer has displayed");

  [same setOpacity: 0.25];
  PASS([same needsDisplay] == NO,
       "setting the same value again is not a change to redisplay for");

  END_SET("setting a property to what it already is")

  START_SET("setting it through the key")

  RedisplayLayer *kvc = [RedisplayLayer layer];

  [kvc displayIfNeeded];
  [kvc setValue: [NSNumber numberWithFloat: 0.75] forKey: @"opacity"];
  PASS([kvc needsDisplay] == YES,
       "a value set by key redisplays as one set by the setter does");

  END_SET("setting it through the key")

  [pool release];
  return 0;
}
