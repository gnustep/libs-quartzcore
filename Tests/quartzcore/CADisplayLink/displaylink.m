/* CADisplayLink: what a link holds, that it sends its selector once it is
   in a run loop, and that pausing and invalidating stop it.

   Apple's +displayLinkWithTarget:selector: is unavailable on macOS, where a
   link comes from a view, a window or a screen instead, so there is nothing
   to check these against and this file is not run there.  What it holds
   before it has sent anything is not documented either; the values below
   are this implementation's. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CADisplayLink.h>

static int fireCount = 0;
static CFTimeInterval lastSeenTimestamp = 0.0;

@interface Ticker : NSObject
- (void) step: (CADisplayLink *)link;
@end

@implementation Ticker
- (void) step: (CADisplayLink *)link
{
  fireCount++;
  lastSeenTimestamp = [link timestamp];
}
@end

static void
runFor(NSTimeInterval seconds)
{
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow: seconds]];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  Ticker *ticker = [[Ticker alloc] init];

  START_SET("what a link holds before it runs")

  CADisplayLink *link = [CADisplayLink displayLinkWithTarget: ticker
                                                    selector: @selector(step:)];

  PASS(link != nil, "a link can be made");
  PASS([link isPaused] == NO, "a link is not paused");
  PASS([link timestamp] == 0.0, "nothing has been sent yet");
  PASS([link targetTimestamp] == 0.0, "and nothing is due yet");
  PASS([link duration] > 0.0, "a frame lasts some time");
  PASS([link preferredFramesPerSecond] == 60,
       "a link asks for sixty frames a second");

  END_SET("what a link holds before it runs")

  START_SET("a link in a run loop")

  fireCount = 0;
  CADisplayLink *link = [CADisplayLink displayLinkWithTarget: ticker
                                                    selector: @selector(step:)];

  [link addToRunLoop: [NSRunLoop currentRunLoop]
             forMode: NSDefaultRunLoopMode];
  runFor(0.25);

  PASS(fireCount > 0, "a link in a run loop sends its selector");
  PASS([link timestamp] > 0.0, "and records when it did");
  PASS(lastSeenTimestamp == [link timestamp],
       "the link it sends is the one that was asked to run");
  PASS([link targetTimestamp] > [link timestamp],
       "the next frame is due after the last one");

  [link invalidate];

  END_SET("a link in a run loop")

  START_SET("a link that is paused")

  fireCount = 0;
  CADisplayLink *link = [CADisplayLink displayLinkWithTarget: ticker
                                                    selector: @selector(step:)];

  [link setPaused: YES];
  PASS([link isPaused] == YES, "pausing reads back");

  [link addToRunLoop: [NSRunLoop currentRunLoop]
             forMode: NSDefaultRunLoopMode];
  runFor(0.15);
  PASS(fireCount == 0, "a paused link sends nothing");

  [link setPaused: NO];
  runFor(0.30);
  PASS(fireCount > 0, "and sends again once it is not paused");

  [link invalidate];

  END_SET("a link that is paused")

  START_SET("a link that has been invalidated")

  CADisplayLink *link = [CADisplayLink displayLinkWithTarget: ticker
                                                    selector: @selector(step:)];

  [link addToRunLoop: [NSRunLoop currentRunLoop]
             forMode: NSDefaultRunLoopMode];
  runFor(0.15);
  [link invalidate];

  fireCount = 0;
  runFor(0.15);
  PASS(fireCount == 0, "an invalidated link sends nothing more");

  END_SET("a link that has been invalidated")

  [ticker release];
  [pool release];
  return 0;
}
