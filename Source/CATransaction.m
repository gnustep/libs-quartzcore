/* CATransaction.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: June 2012

   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/Foundation.h>
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CATransaction.h"
#import "QuartzCore/CAMediaTimingFunction.h"
#import "CATransaction+FrameworkPrivate.h"
#import "CALayer+FrameworkPrivate.h"

NSString *kCATransactionAnimationDuration = @"animationDuration";
NSString *kCATransactionAnimationTimingFunction= @"animationTimingFunction";
NSString *kCATransactionDisableActions = @"disableActions";
NSString *kCATransactionCompletionBlock = @"completionBlock";

#if defined(__BLOCKS__)
/* Something invocable holding a block, so that everything waiting on a commit
   can be scheduled the same way whether it came from a block or from a target
   and a selector. */
@interface CACompletionBlockHolder : NSObject
{
  void (^_block)(void);
}
- (id) initWithBlock: (void (^)(void))block;
- (void) invoke;
@end

@implementation CACompletionBlockHolder

- (id) initWithBlock: (void (^)(void))block
{
  if ((self = [super init]) != nil)
    {
      _block = [block copy];
    }
  return self;
}

- (void) invoke
{
  if (_block != NULL)
    {
      _block();
    }
}

- (void) dealloc
{
  [_block release];
  [super dealloc];
}

@end
#endif

/* A thread has a transaction stack of its own.  What one thread has begun is
   nothing to do with another, and neither can commit or disturb what the
   other holds open, so the stack lives in the thread rather than beside the
   class.  Being per-thread, it needs no lock of its own. */
static NSString * const CATransactionStackKey = @"CATransactionStack";

static NSMutableArray *
CATransactionStack(void)
{
  NSMutableDictionary *thread = [[NSThread currentThread] threadDictionary];
  NSMutableArray *stack = [thread objectForKey: CATransactionStackKey];

  if (stack == nil)
    {
      stack = [NSMutableArray array];
      [thread setObject: stack forKey: CATransactionStackKey];
    }

  return stack;
}

/* +lock and +unlock hand out a recursive lock for callers to hold across a
   read, a change and a write.  How deep the calling thread has gone is kept
   beside it, so that unlocking more often than locking does nothing rather
   than unlocking somebody else's hold. */
static NSRecursiveLock *transactionLock = nil;
static NSString * const CATransactionLockDepthKey = @"CATransactionLockDepth";

@interface CATransaction ()

- (void) commit;

@property (retain) NSMutableDictionary *values;
@property (retain) NSMutableArray *actions;
@property (retain) NSMutableArray *completions;
@property (assign, getter=isImplicit) BOOL implicit;
@end

@implementation CATransaction
@synthesize values=_values;
@synthesize actions=_actions;
@synthesize completions=_completions;
@synthesize implicit=_implicit;

+ (void) begin
{
  NSMutableArray *stack = CATransactionStack();
  CATransaction *enclosingTransaction;
  CATransaction *newTransaction;

  /* A transaction starts out with the values of the one it is nested in;
     changing them affects only the new transaction. */
  enclosingTransaction = [stack lastObject];
  newTransaction = [CATransaction new];
  if (enclosingTransaction)
    {
      [[newTransaction values] removeAllObjects];
      [[newTransaction values] addEntriesFromDictionary:
        [enclosingTransaction values]];
    }

  [stack addObject: newTransaction];
  [newTransaction release];
}

+ (void) commit
{
  NSMutableArray *stack;
  CATransaction *topTransaction = [self topTransaction];

  [topTransaction commit];

  stack = CATransactionStack();
  [stack removeObjectAtIndex: [stack count]-1];
}

+ (void) flush
{
  NSMutableArray *stack = CATransactionStack();
  CATransaction *top = [stack lastObject];

  /* Only the implicit transaction is flushed, and only once nothing
     explicit is still open on top of it: an explicit transaction is the
     caller's to commit, and the flush waits for it. */
  if (top != nil && [top isImplicit])
    {
      [top commit];
      [stack removeLastObject];
    }
}

+ (void) lock
{
  NSNumber *depth;

  if (transactionLock == nil)
    {
      transactionLock = [NSRecursiveLock new];
    }

  [transactionLock lock];

  depth = [[[NSThread currentThread] threadDictionary]
            objectForKey: CATransactionLockDepthKey];
  [[[NSThread currentThread] threadDictionary]
    setObject: [NSNumber numberWithInt: [depth intValue] + 1]
       forKey: CATransactionLockDepthKey];
}

+ (void) unlock
{
  NSMutableDictionary *thread = [[NSThread currentThread] threadDictionary];
  int depth = [[thread objectForKey: CATransactionLockDepthKey] intValue];

  /* Unlocking what this thread never locked does nothing at all. */
  if (depth <= 0)
    {
      return;
    }

  [thread setObject: [NSNumber numberWithInt: depth - 1]
             forKey: CATransactionLockDepthKey];
  [transactionLock unlock];
}

+ (CFTimeInterval) animationDuration
{
  return [[self valueForKey: kCATransactionAnimationDuration] doubleValue];
}

+ (void) setAnimationDuration: (CFTimeInterval)animationDuration
{
  [self setValue: [NSNumber numberWithDouble: animationDuration]
          forKey: kCATransactionAnimationDuration];
}

+ (CAMediaTimingFunction *) animationTimingFunction
{
  return [self valueForKey: kCATransactionAnimationTimingFunction];
}

+ (void) setAnimationTimingFunction: (CAMediaTimingFunction *)function
{
  [self setValue: function forKey: kCATransactionAnimationTimingFunction];
}

+ (BOOL) disableActions
{
  return [[self valueForKey: kCATransactionDisableActions] boolValue];
}

+ (void) setDisableActions: (BOOL)disableActions
{
  [self setValue: [NSNumber numberWithBool: disableActions]
          forKey: kCATransactionDisableActions];
}

+ (void) setCompletionTarget: (id)target selector: (SEL)selector
{
  NSInvocation *invocation;

  if (target == nil || selector == NULL)
    {
      return;
    }

  invocation = [NSInvocation invocationWithMethodSignature:
                 [target methodSignatureForSelector: selector]];
  [invocation setTarget: target];
  [invocation setSelector: selector];
  [invocation retainArguments];
  [[[self topTransaction] completions] addObject: invocation];
}

#if defined(__BLOCKS__)
+ (void (^)(void)) completionBlock
{
  return [self valueForKey: kCATransactionCompletionBlock];
}

+ (void) setCompletionBlock: (void (^)(void))block
{
  CATransaction *transaction = [self topTransaction];

  /* Each block set adds to what will run; the one most recently set is also
     what the getter answers, and a nil clears that without taking away what
     was already asked for. */
  if (block != NULL)
    {
      CACompletionBlockHolder *holder =
        [[CACompletionBlockHolder alloc] initWithBlock: block];

      [[transaction completions] addObject: holder];
      [holder release];
    }

  [transaction setValue: block forKey: kCATransactionCompletionBlock];
}
#endif

+ (id) valueForKey: (NSString *)key
{
  return [[self topTransaction] valueForKey: key];
}

+ (void) setValue: (id)value forKey: (NSString *)key
{
  [[self topTransaction] setValue: value forKey: key];
}

/* ***** Private class methods ******* */
+ (CATransaction *) topTransaction
{
  NSMutableArray *stack = CATransactionStack();

  if(![stack lastObject])
    {
      [CATransaction begin];
      [[stack lastObject] setImplicit: YES];
    }

  return [stack lastObject];
}

/* ***** Instance methods ****** */
/* Note: All are private */

- (id) init
{
  self = [super init];
  if (!self)
    return nil;

  _actions = [[NSMutableArray alloc] init];
  _completions = [[NSMutableArray alloc] init];

  /* The values an outermost transaction starts with.  There is no timing
     function until one is set. */
  _values = [[NSMutableDictionary alloc] init];
  [_values setObject: [NSNumber numberWithDouble: 0.25]
              forKey: kCATransactionAnimationDuration];
  [_values setObject: [NSNumber numberWithBool: NO]
              forKey: kCATransactionDisableActions];

  return self;
}

- (void) dealloc
{
  [_values release];
  [_actions release];
  [_completions release];

  [super dealloc];
}

/* A transaction holds whatever keys are set on it, and reading one that was
   never set answers nil rather than raising. */
- (id) valueForKey: (NSString *)key
{
  return [_values objectForKey: key];
}

- (void) setValue: (id)value forKey: (NSString *)key
{
  if (value == nil)
    {
      [_values removeObjectForKey: key];
    }
  else
    {
      [_values setObject: value forKey: key];
    }
}

- (void) commit
{
  for (NSDictionary* actionDescription in _actions)
    {
      NSObject<CAAction> * action = [actionDescription objectForKey: @"action"];
      id object = [actionDescription objectForKey: @"object"];
      NSString * keyPath = [actionDescription objectForKey: @"keyPath"];
      NSDictionary * arguments = nil;

      if ([object respondsToSelector: @selector(isPresentationLayer)] &&
          [object isPresentationLayer])
        {
          NSLog(@"Attempt at adding action to a presentation layer");
          continue;
        }

      if ([action conformsToProtocol:@protocol(CAMediaTiming)])
        {
          NSObject<CAAction, CAMediaTiming>* timedAction = (id)action;
          if(![timedAction duration])
            [timedAction setDuration: [CATransaction animationDuration]];
        }
      if ([action isKindOfClass: [CAAnimation class]])
        {
          CAAnimation * animation = (id)action;
          if(![animation timingFunction] && [CATransaction animationTimingFunction])
            [animation setTimingFunction: [CATransaction animationTimingFunction]];
        }

      [action runActionForKey: keyPath
                       object: object
                    arguments: arguments];
    }
  [_actions removeAllObjects];

  /* Whatever was asked to be told about the commit is told on a later turn
     of this thread's run loop rather than here, so that a caller committing
     is not made to wait on it. */
  {
    NSInvocation *completion;

    for (completion in _completions)
      {
        [[NSRunLoop currentRunLoop] performSelector: @selector(invoke)
                                             target: completion
                                           argument: nil
                                              order: 0
                                              modes: [NSArray arrayWithObject:
                                                       NSDefaultRunLoopMode]];
      }
    [_completions removeAllObjects];
  }
}

- (void)registerAction: (NSObject<CAAction> *)action
              onObject: (id)object
               keyPath: (NSString *)keyPath
{
  /* eliminate any earlier actions with same object and keypath */
  NSPredicate * sameActionsPredicate = [NSPredicate predicateWithFormat: @"object = %@ and keyPath = %@", object, keyPath];
  NSArray * duplicates = [_actions filteredArrayUsingPredicate: sameActionsPredicate];
  [_actions removeObjectsInArray: duplicates];

  /* now add the new action */
  NSDictionary * actionDescription = [NSDictionary dictionaryWithObjectsAndKeys:
    action, @"action",
    object, @"object",
    keyPath, @"keyPath",
    nil];

  [_actions addObject: actionDescription];
}

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
