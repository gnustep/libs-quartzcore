/* Where a layer looks for an action, and in what order.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CATransaction.h>

/* An action that can be told apart from the others by its tag. */
@interface QCMarker : CAAnimation
{
  NSString *_tag;
}
- (void) setTag: (NSString *)tag;
- (NSString *) tag;
@end

@implementation QCMarker

- (void) setTag: (NSString *)tag
{
  [tag retain];
  [_tag release];
  _tag = tag;
}

- (NSString *) tag
{
  return _tag;
}

- (void) dealloc
{
  [_tag release];
  [super dealloc];
}

@end

@interface QCActionDelegate : NSObject
{
  id _answer;
}
- (void) setAnswer: (id)answer;
@end

@implementation QCActionDelegate

- (void) setAnswer: (id)answer
{
  _answer = answer;
}

- (id<CAAction>) actionForLayer: (CALayer *)layer forKey: (NSString *)key
{
  return _answer;
}

@end

static QCMarker *marker(NSString *tag)
{
  QCMarker *m = [QCMarker animation];

  [m setTag: tag];
  return m;
}

static BOOL taggedWith(id action, NSString *tag)
{
  return [action isKindOfClass: [QCMarker class]]
    && [[(QCMarker *)action tag] isEqualToString: tag];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a layer with nothing to offer")

  CALayer *l = [CALayer layer];

  PASS([CALayer defaultActionForKey: @"position"] == nil,
       "the class offers no action");

  /* Coming back empty-handed is an answer: what to do when nothing offers
     an action is for the caller to decide, not for the search to invent. */
  testHopeful = YES;
  PASS([l actionForKey: @"position"] == nil,
       "a bare layer has no action for a property");
  PASS([l actionForKey: @"aKeyNobodyDefined"] == nil,
       "and none for a key nobody defined");
  testHopeful = NO;

  END_SET("a layer with nothing to offer")

  START_SET("the delegate is asked first")

  CALayer *l = [CALayer layer];
  QCActionDelegate *d = [[[QCActionDelegate alloc] init] autorelease];

  [l setDelegate: (id)d];

  [d setAnswer: marker(@"fromDelegate")];
  PASS(taggedWith([l actionForKey: @"position"], @"fromDelegate"),
       "what the delegate answers is the action");

  [d setAnswer: [NSNull null]];
  PASS([l actionForKey: @"position"] == nil,
       "a null from the delegate ends the search with no action");

  [d setAnswer: nil];
  [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                             forKey: @"position"]];
  PASS(taggedWith([l actionForKey: @"position"], @"fromActions"),
       "nil from the delegate carries the search on to the actions");

  [d setAnswer: marker(@"fromDelegate")];
  PASS(taggedWith([l actionForKey: @"position"], @"fromDelegate"),
       "and the delegate is preferred to the actions");

  END_SET("the delegate is asked first")

  START_SET("then the actions dictionary")

  CALayer *l = [CALayer layer];

  [l setActions: [NSDictionary dictionaryWithObject: [NSNull null]
                                             forKey: @"position"]];
  PASS([l actionForKey: @"position"] == nil,
       "a null in the actions ends the search with no action");

  [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                             forKey: @"position"]];
  PASS(taggedWith([l actionForKey: @"position"], @"fromActions"),
       "what the actions hold is the action");

  testHopeful = YES;
  PASS([l actionForKey: @"opacity"] == nil,
       "a key the actions do not hold finds nothing");
  testHopeful = NO;

  END_SET("then the actions dictionary")

  START_SET("then the style")

  CALayer *l = [CALayer layer];
  NSDictionary *styleActions =
    [NSDictionary dictionaryWithObject: marker(@"fromStyle")
                                forKey: @"position"];

  [l setStyle: [NSDictionary dictionaryWithObject: styleActions
                                           forKey: @"actions"]];
  PASS(taggedWith([l actionForKey: @"position"], @"fromStyle"),
       "the actions inside the style are looked in");

  [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                             forKey: @"position"]];
  PASS(taggedWith([l actionForKey: @"position"], @"fromActions"),
       "and the actions dictionary is preferred to the style");

  CALayer *n = [CALayer layer];
  NSDictionary *nullActions =
    [NSDictionary dictionaryWithObject: [NSNull null] forKey: @"position"];

  [n setStyle: [NSDictionary dictionaryWithObject: nullActions
                                           forKey: @"actions"]];
  PASS([n actionForKey: @"position"] == nil,
       "a null in the style ends the search with no action");

  END_SET("then the style")

  START_SET("disabling actions does not change the search")

  CALayer *l = [CALayer layer];

  [l setActions: [NSDictionary dictionaryWithObject: marker(@"fromActions")
                                             forKey: @"position"]];
  [CATransaction begin];
  [CATransaction setDisableActions: YES];
  PASS(taggedWith([l actionForKey: @"position"], @"fromActions"),
       "an action is still found while actions are disabled");
  [CATransaction commit];

  PASS(taggedWith([l actionForKey: @"position"], @"fromActions"),
       "and afterwards too");

  END_SET("disabling actions does not change the search")

  [pool release];
  return 0;
}
