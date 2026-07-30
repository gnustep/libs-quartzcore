/* Creating a layer, and the change notification each geometry setter posts.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>

@interface Watcher : NSObject
{
  NSMutableDictionary *_counts;
}
- (int) countForKey: (NSString *)key;
@end

@implementation Watcher

- (id) init
{
  if ((self = [super init]) != nil)
    {
      _counts = [[NSMutableDictionary alloc] init];
    }
  return self;
}

- (void) dealloc
{
  [_counts release];
  [super dealloc];
}

- (void) observeValueForKeyPath: (NSString *)keyPath
                       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  NSNumber *n = [_counts objectForKey: keyPath];

  [_counts setObject: [NSNumber numberWithInt: [n intValue] + 1]
              forKey: keyPath];
}

- (int) countForKey: (NSString *)key
{
  return [[_counts objectForKey: key] intValue];
}

@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("CALayer change notification")

  PASS([CALayer layer] != nil, "a layer can be created");

  Watcher *w = [[[Watcher alloc] init] autorelease];
  CALayer *l = [CALayer layer];
  NSArray *keys = [NSArray arrayWithObjects: @"bounds", @"position",
                   @"anchorPoint", @"anchorPointZ", @"zPosition", @"transform",
                   @"sublayerTransform", @"opacity", @"contentsScale",
                   @"masksToBounds", @"shadowOffset", nil];
  NSEnumerator *e = [keys objectEnumerator];
  NSString *key;

  while ((key = [e nextObject]) != nil)
    {
      [l addObserver: w
          forKeyPath: key
             options: NSKeyValueObservingOptionOld
             context: NULL];
    }

  [l setBounds: CGRectMake(0, 0, 10, 20)];
  [l setPosition: CGPointMake(1, 2)];
  [l setAnchorPoint: CGPointMake(0, 0)];
  [l setAnchorPointZ: 3];
  [l setZPosition: 4];
  [l setTransform: CATransform3DMakeScale(2, 2, 2)];
  [l setSublayerTransform: CATransform3DMakeTranslation(1, 1, 1)];
  [l setOpacity: 0.5];
  [l setContentsScale: 2];
  [l setMasksToBounds: YES];
  [l setShadowOffset: CGSizeMake(1, 1)];

  e = [keys objectEnumerator];
  while ((key = [e nextObject]) != nil)
    {
      PASS([w countForKey: key] == 1,
           "setting %s posts one change notification", [key UTF8String]);
    }

  e = [keys objectEnumerator];
  while ((key = [e nextObject]) != nil)
    {
      [l removeObserver: w forKeyPath: key];
    }

  Watcher *same = [[[Watcher alloc] init] autorelease];
  CALayer *s = [CALayer layer];

  [s setPosition: CGPointMake(5, 6)];
  [s addObserver: same
      forKeyPath: @"position"
         options: NSKeyValueObservingOptionOld
         context: NULL];
  [s setPosition: CGPointMake(5, 6)];
  PASS([same countForKey: @"position"] == 0,
       "setting a position to the value it already has posts nothing");
  [s removeObserver: same forKeyPath: @"position"];

  END_SET("CALayer change notification")

  [pool release];
  return 0;
}
